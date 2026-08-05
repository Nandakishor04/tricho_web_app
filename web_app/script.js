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
            // Normalize for result.html compatibility
            if (!item.patient && item.patient_name) {
                item.patient = {
                    name: item.patient_name,
                    age: item.age,
                    gender: item.gender,
                    family_history: item.family_history,
                    duration: item.duration,
                    treatment: item.treatment_history,
                    doctor_comments: item.doctor_comments
                };
            }
            if (!item.vellus && item.vellus_hair) item.vellus = item.vellus_hair;

            // Normalize image URL
            if (item.image_url && !item.image_url.startsWith('http')) {
                let filename = item.image_url;
                if (filename.startsWith('uploads/')) filename = filename.replace('uploads/', '');
                if (filename.startsWith('/')) filename = filename.substring(1);
                item.image_url = API_BASE_URL + 'images/' + filename;
            }
        });

        const combined = [...items];

        // Sort by date descending
        combined.sort((a, b) => new Date(b.date || b.diagnosis_date) - new Date(a.date || a.diagnosis_date));

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

    static async getProfile(params) {
        return await this.postForm('get_profile', params);
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

    const publicPages = ['login.html', 'signup.html', 'forgot_password.html', 'index.html', 'about.html', 'privacy.html', 'tips.html', 'haircare.html'];

    if (!user && !publicPages.includes(currentPage)) {
        console.log("Redirecting to login...");
        navigate('login.html');
    }
    
    // Automatically fetch fresh profile in the background
    if (user) {
        const queryParams = {};
        if (user.id) queryParams.user_id = user.id;
        if (user.email) queryParams.email = user.email;
        if (user.name) queryParams.username = user.name;

        NetworkManager.getProfile(queryParams).then(res => {
            if (res.status === 'success' && res.user) {
                StorageManager.saveUser(res.user);
                // Optionally dispatch an event so UI can update immediately if currently looking at it
                window.dispatchEvent(new Event('profileUpdated'));
            }
        }).catch(err => console.error("Failed to fetch fresh profile:", err));
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
        const user = checkAuth();
        let selectedSampleBlob = null;

        window.loadSampleImage = async () => {
            try {
                const response = await fetch('sample_scalp.jpg');
                const blob = await response.blob();
                selectedSampleBlob = blob;
                
                const preview = document.getElementById('image-preview');
                const placeholder = document.getElementById('upload-placeholder');
                const warning = document.getElementById('invalid-warning');
                
                preview.src = 'sample_scalp.jpg';
                preview.style.display = 'block';
                placeholder.style.display = 'none';
                if (warning) warning.style.display = 'none';
                
                // Clear manual file input
                document.getElementById('image-input').value = "";
                // Save preview
                localStorage.setItem('temp_preview', 'sample_scalp.jpg');
            } catch (err) {
                console.error("Failed to load sample image:", err);
            }
        };

        const imageInput = document.getElementById('image-input');
        const preview = document.getElementById('image-preview');
        const placeholder = document.getElementById('upload-placeholder');
        const diagnoseBtn = document.getElementById('diagnose-btn');

        if (imageInput && preview && placeholder) {
            imageInput.addEventListener('change', (e) => {
                const file = e.target.files[0];
                selectedSampleBlob = null; // Clear sample selection
                const warning = document.getElementById('invalid-warning');
                if (warning) warning.style.display = 'none';

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
            // Remove the strict 'required' attribute since we can now use sample image
            imageInput.required = false;

            diagnosisForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const user = StorageManager.getUser();
                if (!user) return;

                const imageFile = document.getElementById('image-input').files[0];
                if (!imageFile && !selectedSampleBlob) {
                    alert("Please select a scalp image or use the sample image.");
                    return;
                }

                const formData = new FormData();
                if (imageFile) {
                    formData.append('image', imageFile);
                } else if (selectedSampleBlob) {
                    formData.append('image', selectedSampleBlob, 'sample_scalp.jpg');
                }

                formData.append('patient_name', document.getElementById('patient-name').value);
                formData.append('age', document.getElementById('age').value);
                formData.append('gender', document.getElementById('gender').value);
                formData.append('family_history', document.getElementById('family-history').checked ? "Yes" : "No");
                formData.append('duration', document.getElementById('duration').value);
                formData.append('treatment_history', document.getElementById('treatment').value);
                formData.append('doctor_comments', document.getElementById('comments').value);
                formData.append('user_id', user.id);

                setLoader(true);
                const warning = document.getElementById('invalid-warning');
                if (warning) warning.style.display = 'none';

                // Artificial delay to match Swift code's 3-second rule
                const startTime = Date.now();

                // Timeout promise for 10 seconds
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('Timeout')), 10000);
                });

                try {
                    const res = await Promise.race([
                        NetworkManager.diagnose(formData),
                        timeoutPromise
                    ]);
                    
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
                            if (warning && (res.message || "").toLowerCase().includes("invalid image")) {
                                warning.style.display = 'block';
                                warning.scrollIntoView({ behavior: 'smooth' });
                            } else {
                                alert(res.message || "Diagnosis failed");
                            }
                        }
                        setLoader(false);
                    }, remaining);
                } catch (err) {
                    console.error("Diagnosis Error:", err);
                    if (err.message === 'Timeout') {
                        if (warning) {
                            warning.style.display = 'block';
                            warning.scrollIntoView({ behavior: 'smooth' });
                        } else {
                            alert("Invalid image. Please upload a clear scalp image.");
                        }
                    } else {
                        alert("Diagnosis failed: " + err.message + "\nPlease check your connection or try again later.");
                    }
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
                        return `
                            <div class="history-item" onclick="viewDiagnosisDetail(${index})" style="cursor:pointer; display: flex; align-items: center; justify-content: space-between;">
                                <div style="display: flex; align-items: center;">
                                    <img src="${item.image_url ? (item.image_url.startsWith('http') ? item.image_url : API_BASE_URL + 'images/' + (item.image_url.startsWith('uploads/') ? item.image_url.replace('uploads/', '') : (item.image_url.startsWith('/') ? item.image_url.substring(1) : item.image_url))) : 'https://via.placeholder.com/60'}" class="history-item-img" onerror="this.src='https://via.placeholder.com/60'">
                                    <div class="history-item-info">
                                        <h4>${item.condition || 'Scalp Condition'}</h4>
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

        // Refresh latest history automatically
        const user = StorageManager.getUser();
        if (user) {
            NetworkManager.getHistory(user.id).then(res => {
                if (res.status === 'success') {
                    StorageManager.syncHistory(res.history);
                    renderHistory(); // Re-render with new data
                }
            }).catch(err => console.error("Failed to refresh history", err));
        }

        // Search functionality
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                renderHistory(e.target.value);
            });
        }
    }

    if (currentPage === 'profile.html') {
        const renderProfile = () => {
            const user = StorageManager.getUser();
            if (user) {
                document.getElementById('profile-name').innerText = user.name || "User";
                document.getElementById('profile-email').innerText = user.email || user.username || user.id || "Not logged in";
                document.getElementById('val-mobile').innerText = user.mobile || user.phone || "Not provided";
                document.getElementById('val-dob').innerText = user.dob || "Not provided";
                document.getElementById('val-age').innerText = user.age || "Not provided";
                document.getElementById('val-gender').innerText = user.gender || "Not provided";
                document.getElementById('val-country').innerText = user.country || "Not provided";
            }
        };
        
        renderProfile();
        
        // Listen for the background sync event
        window.addEventListener('profileUpdated', renderProfile);

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

        let resetEmail = "";

        // Step 1: Send OTP
        document.getElementById('forgot-email-form').onsubmit = async (e) => {
            e.preventDefault();
            resetEmail = document.getElementById('forgot-email').value;
            setLoader(true);
            if (loaderText) loaderText.innerText = "Sending OTP...";
            try {
                const res = await NetworkManager.sendOTP(resetEmail);
                if (res.status === 'success') {
                    if (res.message && res.message.includes('1234')) {
                        alert(res.message);
                    }
                    step1.style.display = 'none';
                    step2.style.display = 'block';
                } else {
                    alert(res.message || "Failed to send OTP");
                }
            } catch (err) {
                alert("Connection error: " + err.message);
            } finally {
                setLoader(false);
            }
        };

        // Step 2: Verify OTP
        document.getElementById('forgot-otp-form').onsubmit = async (e) => {
            e.preventDefault();
            const otp = document.getElementById('forgot-otp').value;
            setLoader(true);
            if (loaderText) loaderText.innerText = "Verifying OTP...";
            try {
                const res = await NetworkManager.verifyOTP(resetEmail, otp);
                if (res.status === 'success') {
                    step2.style.display = 'none';
                    step3.style.display = 'block';
                } else {
                    alert(res.message || "Invalid OTP");
                }
            } catch (err) {
                alert("Connection error: " + err.message);
            } finally {
                setLoader(false);
            }
        };

        // Step 3: Reset Password
        document.getElementById('forgot-reset-form').onsubmit = async (e) => {
            e.preventDefault();
            const pass = document.getElementById('new-password').value;
            const confirmPass = document.getElementById('confirm-password').value;

            if (pass !== confirmPass) {
                alert("Passwords do not match!");
                return;
            }

            setLoader(true);
            if (loaderText) loaderText.innerText = "Resetting Password...";
            try {
                const res = await NetworkManager.resetPassword(resetEmail, pass);
                if (res.status === 'success') {
                    alert("Password reset successfully! Please login with your new password.");
                    navigate('login.html');
                } else {
                    alert(res.message || "Failed to reset password");
                }
            } catch (err) {
                alert("Connection error: " + err.message);
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
