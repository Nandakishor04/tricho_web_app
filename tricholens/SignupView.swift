import SwiftUI

struct SignupView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var password = ""
    @State private var dob = Date()
    @State private var gender = ""
    @State private var country = ""
    @State private var showDatePicker = false
    
    private let genders = ["Male", "Female", "Other"]
    
    private var isNameValid: Bool {
        fullName.rangeOfCharacter(from: .letters) != nil
    }
    
    private var calculatedAge: Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }
    
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isMobileValid: Bool {
        let mobileRegex = "^[6-9]\\d{9}$"
        let mobilePredicate = NSPredicate(format:"SELF MATCHES %@", mobileRegex)
        return mobilePredicate.evaluate(with: mobile)
    }
    
    private var isAgeValid: Bool {
        calculatedAge >= 15
    }
    
    private var isPasswordValid: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]).*$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && isEmailValid && isMobileValid && isPasswordValid && isAgeValid && !gender.isEmpty
    }
    @State private var navigateToDashboard = false
    @State private var navigateToLogin = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Logo and Headers
                VStack(spacing: 20) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .grayscale(1.0)
                        .brightness(0.3)
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Sign up to get started")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            SignupField(placeholder: "Full Name", text: $fullName, iconName: "person")
                            if !fullName.isEmpty && !isNameValid {
                                Text("Name must contain characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(.brandPinkDark)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SignupField(placeholder: "Email Address", text: $email, keyboardType: .emailAddress, iconName: "envelope")
                            if !email.isEmpty && !isEmailValid {
                                Text("Invalid email format")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SignupField(placeholder: "Mobile Number", text: $mobile, keyboardType: .phonePad, iconName: "iphone")
                            if !mobile.isEmpty && !isMobileValid {
                                Text("Invalid number")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SignupField(placeholder: "Password", text: $password, isSecure: true, iconName: "lock")
                            
                            Text("Password should contain upper letter, special character and number")
                                .font(.system(size: 12))
                                .foregroundColor(password.isEmpty ? .gray : (isPasswordValid ? .brandPinkDark : .red))
                                .padding(.horizontal, 4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            DatePickerField(date: $dob, showPicker: $showDatePicker, iconName: "calendar")
                            if dob != Date() && !isAgeValid {
                                Text("Minimum age is 15 years")
                                    .font(.system(size: 12))
                                    .foregroundColor(.brandPinkDark)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
                        // Gender Selection Field
                        GenderField(selection: $gender, genders: genders, iconName: "person")
                        
                        // Country Field
                        VStack(alignment: .leading, spacing: 4) {
                            SignupField(placeholder: "Country / Region", text: $country, iconName: "globe")
                        }
                        
                        PrimaryButtonView(title: isLoading ? "CREATING..." : "SIGN UP") {
                            signup() // No longer guarded by isFormValid here, signup() handles it with alerts
                        }
                        .padding(.top, 16)
                        
                        // Login Footer
                        HStack {
                            Text("Already have an account? ")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Login")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.brandPinkDark)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(30)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDashboard) {
            DashboardView()
        }
        .alert("Signup Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .overlay {
            if showDatePicker {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDatePicker = false
                        }
                    
                    VStack {
                        Spacer()
                        VStack(spacing: 0) {
                            HStack {
                                Button("Cancel") { showDatePicker = false }
                                Spacer()
                                Button("Done") { showDatePicker = false }
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(Color(white: 0.98))
                            
                            DatePicker("", selection: $dob, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.appPink) // Full solid pink background as requested
                        }
                        .cornerRadius(20)
                        .padding()
                    }
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showDatePicker)
            }
        }
    }
    
    // Sub-components for matching the design layout
    
    private func SignupField(placeholder: String, text: Binding<String>, isSecure: Bool = false, keyboardType: UIKeyboardType = .default, iconName: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                        .foregroundColor(.black)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboardType)
                        .foregroundColor(.black)
                }
            }
            .font(.system(size: 18))
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(Color(white: 0.96))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.borderBright, lineWidth: 1.0)
        )
    }
    
    private func DatePickerField(date: Binding<Date>, showPicker: Binding<Bool>, iconName: String) -> some View {
        Button(action: {
            showPicker.wrappedValue = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Text(date.wrappedValue == Date() ? "Date of birth" : getFormattedDate(date.wrappedValue))
                    .foregroundColor(date.wrappedValue == Date() ? .gray.opacity(0.8) : .black)
                    .font(.system(size: 18))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(Color(white: 0.96))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.borderBright, lineWidth: 1.0)
            )
        }
    }
    
    private func getFormattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func GenderField(selection: Binding<String>, genders: [String], iconName: String) -> some View {
        Menu {
            Picker("Gender", selection: selection) {
                ForEach(genders, id: \.self) {
                    Text($0)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                if selection.wrappedValue.isEmpty {
                    Text("Gender")
                        .foregroundColor(.gray.opacity(0.8))
                        .font(.system(size: 18))
                } else {
                    Text(selection.wrappedValue)
                        .foregroundColor(.black)
                        .font(.system(size: 18))
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .frame(height: 60)
            .background(Color(white: 0.96))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.borderBright, lineWidth: 1.0)
            )
        }
    }
    
    private func PrimaryButtonView(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color.brandPink) // Solid vibrant pink
                .cornerRadius(30)
                .opacity(isLoading ? 0.6 : 1.0)
        }
        .disabled(isLoading) // Only disable while loading, not when fields empty
    }
    
    private func signup() {
        if fullName.isEmpty {
            errorMessage = "Please enter your Full Name"
            showAlert = true
            return
        }
        if !isNameValid {
            errorMessage = "Full Name must contain letters"
            showAlert = true
            return
        }
        if email.isEmpty {
            errorMessage = "Please enter your Email Address"
            showAlert = true
            return
        }
        if mobile.isEmpty {
            errorMessage = "Please enter your Mobile Number"
            showAlert = true
            return
        }
        if password.isEmpty {
            errorMessage = "Please create a Password"
            showAlert = true
            return
        }
        if dob == Date() { // Assuming person has to pick a date
            errorMessage = "Please select your Date of Birth"
            showAlert = true
            return
        }
        if !isAgeValid {
            errorMessage = "You must be at least 15 years old to sign up"
            showAlert = true
            return
        }
        if gender.isEmpty || gender == "Gender" {
            errorMessage = "Please select your Gender"
            showAlert = true
            return
        }
        
        isLoading = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dateFormatter.string(from: dob)
        
        NetworkManager.shared.signup(
            name: fullName,
            email: email,
            mobile: mobile,
            dob: dobString,
            gender: gender,
            age: "\(calculatedAge)",
            country: country.isEmpty ? "Not Specified" : country, // Keep logic, default if empty
            password: password
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if response.status == "success" {
                        if var user = response.user {
                            user.country = country.isEmpty ? "Not Specified" : country
                            StorageManager.shared.saveUser(user)
                            isLoading = false
                            navigateToDashboard = true
                        } else {
                            // If user is nil (new backend behavior), call login automatically
                            NetworkManager.shared.login(username: email, password: password) { loginResult in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    switch loginResult {
                                    case .success(let loginResponse):
                                        if var loggedUser = loginResponse.user {
                                            loggedUser.country = country.isEmpty ? "Not Specified" : country
                                            StorageManager.shared.saveUser(loggedUser)
                                            navigateToDashboard = true
                                        } else {
                                            errorMessage = "Signup successful, but failed to load profile. Please log in manually."
                                            showAlert = true
                                        }
                                    case .failure(let error):
                                        errorMessage = "Signup successful, but login failed: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                }
                            }
                        }
                    } else {
                        isLoading = false
                        errorMessage = response.message
                        showAlert = true
                    }
                case .failure(let error):
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignupView()
        }
    }
}
