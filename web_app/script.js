const API_BASE_URL = "http://localhost:8118/";

class StorageManager {
    static saveUser(user) {
        localStorage.setItem('user', JSON.stringify(user));
    }

    static getUser() {
        const user = localStorage.getItem('user');
        return user ? JSON.parse(user) : null;
    }

    static clearUser() {
        localStorage.removeItem('user');
    }

    static saveHistory(item) {
        let history = this.getHistory();
        history.unshift(item);
        localStorage.setItem('history', JSON.stringify(history));
    }

    static async deleteHistoryItem(id, itemDate) {
        let history = this.getHistory();
        history = history.filter(h => {
            if (id && h.id && String(h.id) === String(id)) return false;
            if (!id && h.date === itemDate) return false;
            return true;
        });
        localStorage.setItem('history', JSON.stringify(history));

        if (id) {
            try {
                const res = await NetworkManager.deleteHistory(id);
                console.log("Server delete response:", res);
            } catch (err) {
                console.error("Failed to delete from server:", err);
            }
        }
    }

    static getHistory() {
        const history = localStorage.getItem('history');
        return history ? JSON.parse(history) : [];
    }

    static syncHistory(items) {
        if (!items) return;
        let localHistory = this.getHistory();

        items.forEach(item => {
            // Clean up image URL
            let rawUrl = item.image_url || item.image_path || item.imageUri;
            if (rawUrl) {
                if (rawUrl.startsWith('data:') || rawUrl.startsWith('http')) {
                    item.image_url = rawUrl;
                } else {
                    let filename = rawUrl.split(/[/\\]/).pop();
                    item.image_url = API_BASE_URL + 'images/' + filename;
                }
            }

            // Normalize patient object for result.html compatibility
            item.patient = {
                name: item.patient?.name || item.patient_name || item.patientName || "N/A",
                age: item.patient?.age || item.age || item.patientAge || "N/A",
                gender: item.patient?.gender || item.gender || item.patientGender || "N/A",
                family_history: item.patient?.family_history || item.family_history || item.patientFamilyHistory || "N/A",
                duration: item.patient?.duration || item.duration || item.patientDuration || "N/A",
                treatment: item.patient?.treatment || item.patient?.treatment_history || item.treatment_history || item.patientTreatmentHistory || "N/A",
                doctor_comments: item.patient?.doctor_comments || item.patient?.comments || item.doctor_comments || item.doctorComments || "N/A"
            };
            if (!item.vellus && item.vellus_hair) item.vellus = item.vellus_hair;
        });

        const combined = [...items];

        localHistory.forEach(localItem => {
            const alreadyExists = items.some(serverItem =>
                (serverItem.id && localItem.id && String(serverItem.id) === String(localItem.id)) ||
                (serverItem.date && localItem.date && serverItem.date === localItem.date) ||
                (serverItem.diagnosis_date && localItem.date && serverItem.diagnosis_date === localItem.date)
            );
            if (!alreadyExists) {
                let rawUrl = localItem.image_url || localItem.image_path || localItem.imageUri || localItem.preview_image;
                if (rawUrl && !rawUrl.startsWith('data:') && !rawUrl.startsWith('http')) {
                    let filename = rawUrl.split(/[/\\]/).pop();
                    localItem.image_url = API_BASE_URL + 'images/' + filename;
                }
                if (!localItem.patient) {
                    localItem.patient = {
                        name: localItem.patient_name || localItem.patientName || "N/A",
                        age: localItem.age || localItem.patientAge || "N/A",
                        gender: localItem.gender || localItem.patientGender || "N/A",
                        family_history: localItem.family_history || localItem.patientFamilyHistory || "N/A",
                        duration: localItem.duration || localItem.patientDuration || "N/A",
                        treatment: localItem.treatment_history || localItem.treatment || "N/A",
                        doctor_comments: localItem.doctor_comments || localItem.comments || "N/A"
                    };
                }
                combined.push(localItem);
            }
        });

        // Sort by date descending
        combined.sort((a, b) => new Date(b.date || b.diagnosis_date || 0) - new Date(a.date || a.diagnosis_date || 0));

        localStorage.setItem('history', JSON.stringify(combined));
    }
}

class NetworkManager {
    static async postForm(endpoint, data) {
        const url = `${API_BASE_URL}${endpoint}`;
        const formData = new URLSearchParams();
        for (const key in data) {
            formData.append(key, data[key]);
        }

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: formData
        });

        return await response.json();
    }

    static async login(username, password) {
        return await this.postForm('login', { username, password });
    }

    static async signup(data) {
        return await this.postForm('signup', data);
    }

    static async getHistory(userId) {
        return await this.postForm('get_history', { user_id: userId });
    }

    static async sendOTP(email) {
        return await this.postForm('send_email_otp', { email });
    }

    static async verifyOTP(email, otp) {
        return await this.postForm('verify_email_otp', { email, otp });
    }

    static async resetPassword(email, password) {
        return await this.postForm('reset_password', { email, password });
    }

    static async updateProfile(data) {
        return await this.postForm('update_profile', data);
    }

    static async deleteHistory(id) {
        const url = `${API_BASE_URL}delete_history`;
        const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id })
        });
        return await response.json();
    }

    static async diagnose(formData) {
        const url = `${API_BASE_URL}diagnose`;
        const response = await fetch(url, {
            method: 'POST',
            body: formData
        });
        return await response.json();
    }
}

// Global Navigation
function navigate(page) {
    if (window.location.pathname.endsWith(page)) return;
    window.location.href = page;
}

function checkAuth() {
    const user = StorageManager.getUser();
    const path = window.location.pathname;
    const currentPage = path.split('/').pop() || 'index.html';

    console.log("Current path:", path, "Page:", currentPage);

    const publicPages = ['login.html', 'signup.html', 'forgot_password.html', 'index.html'];

    if (!user && !publicPages.includes(currentPage)) {
        console.log("Redirecting to login...");
        navigate('login.html');
    }
    return user;
}

// Show/Hide Loader
function setLoader(show) {
    const loader = document.getElementById('loader');
    if (loader) loader.style.display = show ? 'flex' : 'none';
}

// Common Initialization
document.addEventListener('DOMContentLoaded', () => {
    const user = checkAuth();

    // Page specific initialization
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';

    if (currentPage === 'dashboard.html' && user) {
        const welcomeText = document.getElementById('welcome-text');
        if (welcomeText) welcomeText.innerText = `Hello, ${user.name}`;

        // Sync history in background
        NetworkManager.getHistory(user.id).then(res => {
            if (res.status === 'success') {
                StorageManager.syncHistory(res.history);
            }
        });
    }

    if (currentPage === 'login.html') {
        const loginForm = document.getElementById('login-form');
        if (loginForm) {
            loginForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const email = document.getElementById('email').value;
                const password = document.getElementById('password').value;

                setLoader(true);
                try {
                    const res = await NetworkManager.login(email, password);
                    if (res.status === 'success') {
                        StorageManager.saveUser(res.user);
                        navigate('dashboard.html');
                    } else {
                        alert(res.message || "Login failed");
                    }
                } catch (err) {
                    console.error("Fetch Error:", err);
                    alert(`Connection error: ${err.message}\n\nTarget URL: ${API_BASE_URL}\nCheck if the server is running at this IP.`);
                } finally {
                    setLoader(false);
                }
            });
        }
    }

    if (currentPage === 'signup.html') {
        const signupForm = document.getElementById('signup-form');
        if (signupForm) {
            signupForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const data = {
                    name: document.getElementById('name').value,
                    email: document.getElementById('email').value,
                    mobile: document.getElementById('mobile').value,
                    password: document.getElementById('password').value,
                    dob: document.getElementById('dob').value,
                    gender: document.getElementById('gender').value,
                    country: document.getElementById('country').value,
                    age: calculateAge(document.getElementById('dob').value)
                };

                setLoader(true);
                try {
                    const res = await NetworkManager.signup(data);
                    if (res.status === 'success') {
                        // Backend might not return user in signup sometimes, based on Swift code
                        if (res.user) {
                            StorageManager.saveUser(res.user);
                            navigate('dashboard.html');
                        } else {
                            // Try login automatically
                            const loginRes = await NetworkManager.login(data.email, data.password);
                            if (loginRes.status === 'success') {
                                StorageManager.saveUser(loginRes.user);
                                navigate('dashboard.html');
                            } else {
                                alert("Signup successful, please login.");
                                navigate('login.html');
                            }
                        }
                    } else {
                        alert(res.message || "Signup failed");
                    }
                } catch (err) {
                    alert("Connection error: " + err.message);
                } finally {
                    setLoader(false);
                }
            });
        }
    }

    if (currentPage === 'diagnosis.html') {
        const imageInput = document.getElementById('image-input');
        const preview = document.getElementById('image-preview');
        const placeholder = document.getElementById('upload-placeholder');
        const diagnoseBtn = document.getElementById('diagnose-btn');

        if (imageInput) {
            imageInput.addEventListener('change', (e) => {
                const file = e.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = (event) => {
                        preview.src = event.target.result;
                        preview.style.display = 'block';
                        placeholder.style.display = 'none';
                        diagnoseBtn.style.display = 'flex';
                        // Save local preview for result page
                        localStorage.setItem('temp_preview', event.target.result);
                    };
                    reader.readAsDataURL(file);
                }
            });
        }

        const diagnosisForm = document.getElementById('diagnosis-form');
        if (diagnosisForm) {
            diagnosisForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const user = StorageManager.getUser();
                if (!user) return;

                const imageFile = document.getElementById('image-input').files[0];

                const formData = new FormData();
                formData.append('image', imageFile);
                formData.append('patient_name', document.getElementById('patient-name').value);
                formData.append('age', document.getElementById('age').value);
                formData.append('gender', document.getElementById('gender').value);
                formData.append('family_history', document.getElementById('family-history').checked ? "Yes" : "No");
                formData.append('duration', document.getElementById('duration').value);
                formData.append('treatment_history', document.getElementById('treatment').value);
                formData.append('doctor_comments', document.getElementById('comments').value);
                formData.append('user_id', user.id);

                setLoader(true);
                // Artificial delay to match Swift code's 3-second rule
                const startTime = Date.now();

                try {
                    const res = await NetworkManager.diagnose(formData);
                    const elapsed = Date.now() - startTime;
                    const remaining = Math.max(0, 3000 - elapsed);

                    setTimeout(() => {
                        if (res.status === 'success' || res.status === 'valid') {
                            // Use explicit fields from backend if available, otherwise fallback to parsing
                            const condition = res.condition || "Analysis Result";
                            const density = res.density || "--";
                            let ratio = res.ratio || "--";
                            const vellus = res.vellus_hair || "--";
                            const observation = res.observation || res.diagnosis || "--";

                            // Parity with iOS: Combine ratio and vellus for storage
                            const finalRatio = (ratio && vellus && vellus !== "--") ? `${ratio}|${vellus}` : ratio;

                            const result = {
                                id: res.id || null,
                                condition: condition,
                                density: density,
                                ratio: finalRatio,
                                vellus: vellus,
                                signs: res.signs_present || "",
                                observation: observation,
                                image_url: res.image_url ? (res.image_url.startsWith('http') ? res.image_url : API_BASE_URL + 'images/' + (res.image_url.startsWith('uploads/') ? res.image_url.replace('uploads/', '') : (res.image_url.startsWith('/') ? res.image_url.substring(1) : res.image_url))) : null,
                                preview_image: localStorage.getItem('temp_preview'),
                                patient: {
                                    name: document.getElementById('patient-name').value,
                                    age: document.getElementById('age').value,
                                    gender: document.getElementById('gender').value,
                                    family_history: document.getElementById('family-history').checked ? "Yes" : "No",
                                    duration: document.getElementById('duration').value,
                                    treatment: document.getElementById('treatment').value,
                                    doctor_comments: document.getElementById('comments').value
                                },
                                date: new Date().toISOString()
                            };
                            localStorage.setItem('last_diagnosis', JSON.stringify(result));
                            StorageManager.saveHistory(result);
                            navigate('result.html');
                        } else {
                            alert(res.message || "Diagnosis failed");
                        }
                        setLoader(false);
                    }, remaining);
                } catch (err) {
                    console.error("Diagnosis Error:", err);
                    alert("Diagnosis failed: " + err.message + "\nPlease check your connection or try again later.");
                    setLoader(false);
                }
            });
        }
    }

    if (currentPage === 'history.html') {
        const container = document.getElementById('history-container');
        const searchInput = document.getElementById('search-input');

        const renderHistory = (filter = '') => {
            const history = StorageManager.getHistory();
            const filtered = history.filter(item =>
                (item.condition && item.condition.toLowerCase().includes(filter.toLowerCase())) ||
                (item.patient && item.patient.name && item.patient.name.toLowerCase().includes(filter.toLowerCase())) ||
                (item.patient_name && item.patient_name.toLowerCase().includes(filter.toLowerCase())) ||
                (item.observation && item.observation.toLowerCase().includes(filter.toLowerCase()))
            );

            if (container) {
                if (filtered.length === 0) {
                    container.innerHTML = `<p style="text-align:center; margin-top:20px; color:gray;">${filter ? 'No results found' : 'No history found'}</p>`;
                } else {
                    container.innerHTML = filtered.map((item, index) => {
                        const displayDate = new Date(item.date || item.diagnosis_date || Date.now()).toLocaleString('en-US', {
                            day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
                        });
                        const name = item.patient?.name || item.patient_name || item.patientName || 'Patient';
                        let rawImg = item.image_url || item.image_path || item.imageUri;
                        let imgSrc = 'logo.png';
                        if (rawImg) {
                            if (rawImg.startsWith('data:') || rawImg.startsWith('http')) {
                                imgSrc = rawImg;
                            } else {
                                let filename = rawImg.split(/[/\\]/).pop();
                                imgSrc = API_BASE_URL + 'images/' + filename;
                            }
                        }

                        return `
                            <div class="history-item" onclick="viewDiagnosisDetail(${index})" style="cursor:pointer; display: flex; align-items: center; justify-content: space-between;">
                                <div style="display: flex; align-items: center; gap: 16px;">
                                    <img src="${imgSrc}" class="history-item-img" style="width:60px; height:60px; object-fit:cover; border-radius:8px;" onerror="this.onerror=null; this.src='logo.png';">
                                    <div class="history-item-info">
                                        <h4 style="margin: 0 0 4px 0; font-size: 16px; font-weight: 700;">${name}</h4>
                                        <p style="margin: 0 0 4px 0; font-size: 14px; color: var(--brand-pink); font-weight: 600;">${item.condition || 'Scalp Analysis'}</p>
                                        <span style="font-size: 12px; color: #888;">${displayDate}</span>
                                    </div>
                                </div>
                                <div style="display: flex; align-items: center; gap: 15px;">
                                    <button onclick="event.stopPropagation(); deleteHistoryItemManual('${item.id}', '${item.date}', ${index})" style="background: none; border: none; color: #ff4d4d; cursor: pointer; padding: 10px;">
                                        <i class="fas fa-trash-alt"></i>
                                    </button>
                                    <i class="fas fa-chevron-right" style="color:#ccc"></i>
                                </div>
                            </div>
                        `;
                    }).join('');
                }
            }
        };

        renderHistory();

        // Sync history from server on page load
        if (user) {
            NetworkManager.getHistory(user.id).then(res => {
                if (res.status === 'success') {
                    StorageManager.syncHistory(res.history);
                    renderHistory(searchInput ? searchInput.value : '');
                }
            });
        }

        if (searchInput) {
            searchInput.addEventListener('input', (e) => renderHistory(e.target.value));
        }
    }

    if (currentPage === 'profile.html') {
        const user = StorageManager.getUser();
        if (user) {
            document.getElementById('profile-name').innerText = user.name || "User";
            document.getElementById('profile-email').innerText = user.email || user.username || user.id || "Not logged in";
            document.getElementById('val-mobile').innerText = user.mobile || user.phone || "Not provided";
            document.getElementById('val-dob').innerText = user.dob || "Not provided";
            document.getElementById('val-age').innerText = user.age || "Not provided";
            document.getElementById('val-gender').innerText = user.gender || "Not provided";
            document.getElementById('val-country').innerText = user.country || "Not provided";
            
            const statAge = document.getElementById('stat-age');
            if (statAge) statAge.innerText = user.age || "--";
            
            const statGender = document.getElementById('stat-gender-icon');
            if (statGender) statGender.innerText = user.gender ? user.gender.charAt(0).toUpperCase() : "--";
        }

        document.getElementById('signout-btn').onclick = () => {
            StorageManager.clearUser();
            navigate('login.html');
        };
    }

    if (currentPage === 'edit_profile.html') {
        const user = StorageManager.getUser();
        if (user) {
            document.getElementById('edit-name').value = user.name || "";
            document.getElementById('edit-mobile').value = user.mobile || "";
            document.getElementById('edit-dob').value = user.dob || "";
            document.getElementById('edit-gender').value = user.gender || "Male";
            document.getElementById('edit-country').value = user.country || "";
        }

        const editForm = document.getElementById('edit-profile-form');
        if (editForm) {
            editForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const data = {
                    email: user.email,
                    name: document.getElementById('edit-name').value,
                    mobile: document.getElementById('edit-mobile').value,
                    dob: document.getElementById('edit-dob').value,
                    gender: document.getElementById('edit-gender').value,
                    country: document.getElementById('edit-country').value,
                    age: calculateAge(document.getElementById('edit-dob').value)
                };

                setLoader(true);
                try {
                    const res = await NetworkManager.updateProfile(data);
                    if (res.status === 'success') {
                        // Update local user data
                        const updatedUser = { ...user, ...data };
                        if (res.user) Object.assign(updatedUser, res.user);
                        StorageManager.saveUser(updatedUser);
                        alert("Profile updated successfully!");
                        navigate('profile.html');
                    } else {
                        alert(res.message || "Update failed");
                    }
                } catch (err) {
                    alert("Connection error: " + err.message);
                } finally {
                    setLoader(false);
                }
            });
        }
    }

    if (currentPage === 'forgot_password.html') {
        const step1 = document.getElementById('step-1');
        const step2 = document.getElementById('step-2');
        const step3 = document.getElementById('step-3');
        const loaderText = document.getElementById('loader-text');

        const forgotAlert = document.getElementById('forgot-alert');
        const forgotAlertText = document.getElementById('forgot-alert-text');

        const emailInput = document.getElementById('forgot-email');
        const emailContainer = document.getElementById('email-input-container');
        const emailValidIcon = document.getElementById('email-valid-icon');
        const emailInvalidIcon = document.getElementById('email-invalid-icon');
        const emailFeedback = document.getElementById('email-feedback');

        const otpBoxes = document.querySelectorAll('.otp-single-box');
        const resendBtn = document.getElementById('resend-otp-btn');
        const resendTimerEl = document.getElementById('resend-timer');

        const newPassInput = document.getElementById('new-password');
        const confirmPassInput = document.getElementById('confirm-password');
        const passMatchFeedback = document.getElementById('password-match-feedback');
        const strengthFill = document.getElementById('strength-fill');
        const strengthText = document.getElementById('strength-text');

        let resetEmail = "";
        let resendTimerInterval = null;

        // Show/Hide Alert Banner
        window.showAlert = function(msg, isError = true) {
            if (!forgotAlert) return;
            forgotAlert.className = `alert-banner ${isError ? 'error' : 'success'}`;
            forgotAlertText.innerText = msg;
            forgotAlert.style.display = 'flex';
        };

        window.hideAlert = function() {
            if (forgotAlert) forgotAlert.style.display = 'none';
        };

        // Stepper Navigation Helper
        window.goToStep = function(stepNum) {
            hideAlert();
            step1.style.display = stepNum === 1 ? 'block' : 'none';
            step2.style.display = stepNum === 2 ? 'block' : 'none';
            step3.style.display = stepNum === 3 ? 'block' : 'none';

            // Update Stepper Nodes
            for (let i = 1; i <= 3; i++) {
                const node = document.getElementById(`step-node-${i}`);
                if (!node) continue;
                node.classList.remove('active', 'completed');
                if (i < stepNum) {
                    node.classList.add('completed');
                } else if (i === stepNum) {
                    node.classList.add('active');
                }
            }

            const fill = document.getElementById('stepper-fill');
            if (fill) {
                if (stepNum === 1) fill.style.width = '0%';
                if (stepNum === 2) fill.style.width = '50%';
                if (stepNum === 3) fill.style.width = '100%';
            }

            // Subtitles update
            const flowTitle = document.getElementById('flow-title');
            const flowSubtitle = document.getElementById('flow-subtitle');
            if (stepNum === 1) {
                if (flowTitle) flowTitle.innerText = "Forgot Password?";
                if (flowSubtitle) flowSubtitle.innerText = "Don't worry! Enter your registered email address below to reset your password.";
            } else if (stepNum === 2) {
                if (flowTitle) flowTitle.innerText = "Verify OTP Code";
                if (flowSubtitle) flowSubtitle.innerText = "We sent a 6-digit verification code to your email.";
                startResendTimer();
            } else if (stepNum === 3) {
                if (flowTitle) flowTitle.innerText = "Create New Password";
                if (flowSubtitle) flowSubtitle.innerText = "Please choose a strong new password for your Tricholens account.";
            }
        };

        // Client-side Email Validation
        function validateEmailFormat(emailStr) {
            const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return regex.test(emailStr);
        }

        if (emailInput) {
            const checkEmailValidity = () => {
                const val = emailInput.value.trim();
                hideAlert();
                if (!val) {
                    emailContainer.classList.remove('valid-state', 'error-state');
                    emailValidIcon.style.display = 'none';
                    emailInvalidIcon.style.display = 'none';
                    emailFeedback.style.display = 'none';
                    return false;
                }

                if (validateEmailFormat(val)) {
                    emailContainer.classList.remove('error-state');
                    emailContainer.classList.add('valid-state');
                    emailValidIcon.style.display = 'block';
                    emailInvalidIcon.style.display = 'none';
                    emailFeedback.className = 'input-feedback valid';
                    emailFeedback.innerHTML = '<i class="fas fa-check-circle"></i> Valid email format';
                    emailFeedback.style.display = 'flex';
                    return true;
                } else {
                    emailContainer.classList.remove('valid-state');
                    emailContainer.classList.add('error-state');
                    emailValidIcon.style.display = 'none';
                    emailInvalidIcon.style.display = 'block';
                    emailFeedback.className = 'input-feedback invalid';
                    emailFeedback.innerHTML = '<i class="fas fa-exclamation-circle"></i> Please enter a valid email format (e.g., user@domain.com)';
                    emailFeedback.style.display = 'flex';
                    return false;
                }
            };

            emailInput.addEventListener('input', checkEmailValidity);
            emailInput.addEventListener('blur', checkEmailValidity);
        }

        // OTP Boxes Auto-Focus Logic
        if (otpBoxes && otpBoxes.length > 0) {
            otpBoxes.forEach((box, idx) => {
                box.addEventListener('input', (e) => {
                    const val = e.target.value;
                    if (val && idx < otpBoxes.length - 1) {
                        otpBoxes[idx + 1].focus();
                    }
                    collectOTP();
                });
                box.addEventListener('keydown', (e) => {
                    if (e.key === 'Backspace' && !box.value && idx > 0) {
                        otpBoxes[idx - 1].focus();
                    }
                });
                box.addEventListener('paste', (e) => {
                    e.preventDefault();
                    const pasteData = (e.clipboardData || window.clipboardData).getData('text').trim();
                    if (/^\d{6}$/.test(pasteData)) {
                        pasteData.split('').forEach((char, i) => {
                            if (otpBoxes[i]) otpBoxes[i].value = char;
                        });
                        collectOTP();
                        if (otpBoxes[5]) otpBoxes[5].focus();
                    }
                });
            });
        }

        function collectOTP() {
            let fullOtp = "";
            otpBoxes.forEach(b => fullOtp += b.value);
            const hiddenOtp = document.getElementById('forgot-otp');
            if (hiddenOtp) hiddenOtp.value = fullOtp;
            return fullOtp;
        }

        // Resend OTP Timer
        function startResendTimer() {
            if (resendTimerInterval) clearInterval(resendTimerInterval);
            let seconds = 60;
            if (resendBtn) {
                resendBtn.disabled = true;
                resendBtn.style.cursor = 'not-allowed';
                resendBtn.style.color = '#9CA3AF';
            }

            resendTimerInterval = setInterval(() => {
                seconds--;
                if (resendTimerEl) resendTimerEl.innerText = seconds;
                if (seconds <= 0) {
                    clearInterval(resendTimerInterval);
                    if (resendBtn) {
                        resendBtn.disabled = false;
                        resendBtn.style.cursor = 'pointer';
                        resendBtn.style.color = 'var(--brand-pink)';
                        resendBtn.innerText = "Resend OTP";
                    }
                }
            }, 1000);
        }

        if (resendBtn) {
            resendBtn.addEventListener('click', async () => {
                if (resendBtn.disabled) return;
                setLoader(true);
                try {
                    const res = await NetworkManager.sendOTP(resetEmail);
                    if (res.status === 'success') {
                        showAlert("A new OTP code has been sent to your email.", false);
                        startResendTimer();
                    } else {
                        showAlert(res.message || "Failed to resend OTP.", true);
                    }
                } catch (err) {
                    showAlert("Connection error: " + err.message, true);
                } finally {
                    setLoader(false);
                }
            });
        }

        // Password Strength & Match Listener
        if (newPassInput) {
            newPassInput.addEventListener('input', () => {
                const pass = newPassInput.value;
                let score = 0;
                if (pass.length >= 6) score += 33;
                if (pass.length >= 8) score += 33;
                if (/[0-9]/.test(pass) && /[^A-Za-z0-9]/.test(pass)) score += 34;

                if (strengthFill) {
                    strengthFill.style.width = `${score}%`;
                    if (score <= 33) {
                        strengthFill.style.backgroundColor = '#DC2626';
                        if (strengthText) strengthText.innerText = "Weak Password";
                    } else if (score <= 66) {
                        strengthFill.style.backgroundColor = '#F59E0B';
                        if (strengthText) strengthText.innerText = "Medium Strength";
                    } else {
                        strengthFill.style.backgroundColor = '#10B981';
                        if (strengthText) strengthText.innerText = "Strong Password";
                    }
                }
                checkPasswordMatch();
            });
        }

        if (confirmPassInput) {
            confirmPassInput.addEventListener('input', checkPasswordMatch);
        }

        function checkPasswordMatch() {
            if (!confirmPassInput || !newPassInput) return false;
            const pass = newPassInput.value;
            const confirmVal = confirmPassInput.value;

            if (!confirmVal) {
                passMatchFeedback.style.display = 'none';
                return false;
            }

            if (pass === confirmVal) {
                passMatchFeedback.className = 'input-feedback valid';
                passMatchFeedback.innerHTML = '<i class="fas fa-check-circle"></i> Passwords match!';
                passMatchFeedback.style.display = 'flex';
                return true;
            } else {
                passMatchFeedback.className = 'input-feedback invalid';
                passMatchFeedback.innerHTML = '<i class="fas fa-times-circle"></i> Passwords do not match';
                passMatchFeedback.style.display = 'flex';
                return false;
            }
        }

        // Step 1 Form Submit (Send OTP)
        document.getElementById('forgot-email-form').onsubmit = async (e) => {
            e.preventDefault();
            resetEmail = emailInput.value.trim();

            if (!validateEmailFormat(resetEmail)) {
                showAlert("Please enter a valid email address format (e.g. name@domain.com).", true);
                return;
            }

            setLoader(true);
            hideAlert();
            if (loaderText) loaderText.innerText = "Verifying email & sending OTP...";

            try {
                const res = await NetworkManager.sendOTP(resetEmail);
                if (res.status === 'success') {
                    const sentDisplay = document.getElementById('sent-email-display');
                    if (sentDisplay) sentDisplay.innerText = resetEmail;
                    goToStep(2);
                } else {
                    showAlert(res.message || "Email lookup failed.", true);
                }
            } catch (err) {
                showAlert("Connection error: " + err.message, true);
            } finally {
                setLoader(false);
            }
        };

        // Step 2 Form Submit (Verify OTP)
        document.getElementById('forgot-otp-form').onsubmit = async (e) => {
            e.preventDefault();
            const otp = collectOTP();

            if (otp.length < 6) {
                showAlert("Please enter the complete 6-digit OTP code.", true);
                return;
            }

            setLoader(true);
            hideAlert();
            if (loaderText) loaderText.innerText = "Verifying OTP code...";

            try {
                const res = await NetworkManager.verifyOTP(resetEmail, otp);
                if (res.status === 'success') {
                    goToStep(3);
                } else {
                    showAlert(res.message || "Invalid OTP code. Please check and try again.", true);
                }
            } catch (err) {
                showAlert("Connection error: " + err.message, true);
            } finally {
                setLoader(false);
            }
        };

        // Step 3 Form Submit (Reset Password)
        document.getElementById('forgot-reset-form').onsubmit = async (e) => {
            e.preventDefault();
            const pass = newPassInput.value;
            const confirmPass = confirmPassInput.value;

            if (pass.length < 6) {
                showAlert("Password must be at least 6 characters long.", true);
                return;
            }

            if (pass !== confirmPass) {
                showAlert("Passwords do not match. Please ensure both fields are identical.", true);
                return;
            }

            setLoader(true);
            hideAlert();
            if (loaderText) loaderText.innerText = "Updating password...";

            try {
                const res = await NetworkManager.resetPassword(resetEmail, pass);
                if (res.status === 'success') {
                    const modal = document.getElementById('success-modal');
                    if (modal) modal.style.display = 'flex';
                } else {
                    showAlert(res.message || "Failed to reset password.", true);
                }
            } catch (err) {
                showAlert("Connection error: " + err.message, true);
            } finally {
                setLoader(false);
            }
        };
    }

});

function calculateAge(dobString) {
    if (!dobString) return "0";
    const dob = new Date(dobString);
    const diff = Date.now() - dob.getTime();
    const age = new Date(diff);
    return Math.abs(age.getUTCFullYear() - 1970).toString();
}

function viewDiagnosisDetail(index) {
    const history = StorageManager.getHistory();
    const item = history[index];
    if (!item) return;

    // Ensure image_url is properly formatted
    let rawImg = item.image_url || item.image_path || item.imageUri || item.preview_image;
    if (rawImg && !rawImg.startsWith('data:') && !rawImg.startsWith('http')) {
        let filename = rawImg.split(/[/\\]/).pop();
        item.image_url = API_BASE_URL + 'images/' + filename;
    }

    // Ensure patient details exist
    if (!item.patient) {
        item.patient = {
            name: item.patient_name || item.patientName || "N/A",
            age: item.age || item.patientAge || "N/A",
            gender: item.gender || item.patientGender || "N/A",
            family_history: item.family_history || item.patientFamilyHistory || "N/A",
            duration: item.duration || item.patientDuration || "N/A",
            treatment: item.treatment_history || item.treatment || "N/A",
            doctor_comments: item.doctor_comments || item.comments || "N/A"
        };
    }

    localStorage.setItem('last_diagnosis', JSON.stringify(item));
    navigate('result.html');
}

async function deleteCurrentDiagnosis() {
    const data = JSON.parse(localStorage.getItem('last_diagnosis'));
    if (data && confirm("Are you sure you want to delete this diagnosis?")) {
        setLoader(true);
        try {
            await StorageManager.deleteHistoryItem(data.id, data.date);
            localStorage.removeItem('last_diagnosis');
            navigate('history.html');
        } catch (err) {
            alert("Delete failed: " + err.message);
        } finally {
            setLoader(false);
        }
    }
}

async function deleteHistoryItemManual(id, date, index) {
    if (confirm("Are you sure you want to delete this record?")) {
        setLoader(true);
        try {
            await StorageManager.deleteHistoryItem(id, date);
            window.location.reload();
        } catch (err) {
            alert("Delete failed: " + err.message);
        } finally {
            setLoader(false);
        }
    }
}

function togglePasswordVisibility(inputId, btn) {
    const input = document.getElementById(inputId);
    if (!input) return;
    const icon = btn.querySelector('i');
    if (input.type === 'password') {
        input.type = 'text';
        if (icon) {
            icon.classList.remove('fa-eye');
            icon.classList.add('fa-eye-slash');
        }
    } else {
        input.type = 'password';
        if (icon) {
            icon.classList.remove('fa-eye-slash');
            icon.classList.add('fa-eye');
        }
    }
}

