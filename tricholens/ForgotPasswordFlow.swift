import SwiftUI

struct ForgotPasswordEmailView: View {
    @Environment(\.presentationMode) var presentationMode
    var rootIsActive: Binding<Bool>? = nil
    @State private var email = ""
    @State private var navigateToOtp = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Illustration
                        Image(systemName: "lock.rectangle.stack.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.appPink)
                            .frame(width: 140, height: 140)
                            .padding(.top, 40)
                            .padding(.bottom, 24)
                        
                        Text("Forgot Password?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(.bottom, 8)
                        
                        Text("Enter your registered email address to verify.")
                            .font(.system(size: 16))
                            .foregroundColor(.textHintGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 32)
                        
                        // Form Card
                        VStack(spacing: 24) {
                            CustomTextField(hint: "Email Address", text: $email, keyboardType: .emailAddress, iconName: "envelope")
                            
                            PrimaryButton(title: isLoading ? "VERIFYING..." : "CONTINUE") {
                                verifyEmail()
                            }
                            .disabled(isLoading || email.isEmpty)
                            .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                        }
                    }
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOtp) {
                OtpVerificationView(email: email, rootIsActive: rootIsActive)
            }
            .alert("Verification Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func verifyEmail() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your registered email address"
            showAlert = true
            return
        }
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address"
            showAlert = true
            return
        }
        
        isLoading = true
        NetworkManager.shared.sendOTP(email: email) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success" {
                        navigateToOtp = true
                    } else {
                        errorMessage = response.message
                        showAlert = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

struct OtpVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var otpDigits = ["", "", "", ""]
    @State private var navigateToReset = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    @State private var timeRemaining = 120
    let email: String
    var rootIsActive: Binding<Bool>? = nil
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Focus management for OTP digits
    @FocusState private var focusedField: Int?
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Illustration
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.appPink)
                            .padding(.top, 40)
                            .padding(.bottom, 24)
                        
                        Text("Check your email")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(.bottom, 8)
                        
                        Text("We've sent an OTP to \(email)")
                            .font(.system(size: 16))
                            .foregroundColor(.textHintGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 32)
                        
                        // Form Card
                        VStack(spacing: 24) {
                            HStack(spacing: 12) {
                                ForEach(0..<4) { index in
                                    TextField("", text: $otpDigits[index])
                                        .frame(width: 56, height: 60)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 24, weight: .bold))
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: index)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(focusedField == index ? Color.brandPink : Color.gray.opacity(0.2), lineWidth: 2)
                                        )
                                        .shadow(color: Color.black.opacity(focusedField == index ? 0.05 : 0), radius: 4, x: 0, y: 2)
                                        .onChange(of: otpDigits[index]) { newValue in
                                            if newValue.count > 1 {
                                                otpDigits[index] = String(newValue.prefix(1))
                                            }
                                            if !newValue.isEmpty && index < 3 {
                                                focusedField = index + 1
                                            }
                                        }
                                }
                            }
                            
                            HStack {
                                Text(formattedTime)
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "888888"))
                                
                                Spacer()
                                
                                Button(action: { resendOTP() }) {
                                    Text("Resend Code")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(timeRemaining > 0 ? .gray : .appPink)
                                }
                                .disabled(timeRemaining > 0)
                            }
                            
                            PrimaryButton(title: isLoading ? "VERIFYING..." : "VERIFY OTP") {
                                verifyOtp()
                            }
                            .disabled(isLoading || otpDigits.contains(where: { $0.isEmpty }))
                            .opacity((isLoading || otpDigits.contains(where: { $0.isEmpty })) ? 0.6 : 1.0)
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView(email: email, rootIsActive: rootIsActive)
        }
        .alert("Verification Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            focusedField = 0
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func verifyOtp() {
        let otp = otpDigits.joined()
        isLoading = true
        NetworkManager.shared.verifyOTP(email: email, otp: otp) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success" {
                        navigateToReset = true
                    } else {
                        errorMessage = response.message
                        showAlert = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func resendOTP() {
        timeRemaining = 120
        isLoading = true
        NetworkManager.shared.sendOTP(email: email) { result in
            DispatchQueue.main.async {
                isLoading = false
                // Just show an alert for simplicity
                if case .failure(let error) = result {
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var navigateToSuccess = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    let email: String
    var rootIsActive: Binding<Bool>? = nil
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Illustration
                        Image(systemName: "key.horizontal.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.appPink)
                            .frame(width: 120, height: 120)
                            .padding(.top, 40)
                            .padding(.bottom, 24)
                        
                        Text("Reset Password")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.appText)
                            .padding(.bottom, 8)
                        
                        Text("Enter your new password below")
                            .font(.system(size: 16))
                            .foregroundColor(.textHintGray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 32)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(hint: "New Password", text: $newPassword, isSecure: true, iconName: "lock")
                                
                                Text("Password should contain upper letter, special character and number")
                                    .font(.system(size: 11))
                                    .foregroundColor(newPassword.isEmpty ? .gray : (isPasswordValid ? .brandPinkDark : .red))
                                    .padding(.horizontal, 4)
                            }
                            
                            CustomTextField(hint: "Confirm Password", text: $confirmPassword, isSecure: true, iconName: "lock")
                                .padding(.bottom, 8)
                            
                            PrimaryButton(title: isLoading ? "RESETTING..." : "RESET PASSWORD") {
                                resetPassword()
                            }
                            .disabled(isLoading || newPassword.isEmpty || !isPasswordValid || confirmationDoesNotMatch)
                            .opacity((isLoading || newPassword.isEmpty || !isPasswordValid || confirmationDoesNotMatch) ? 0.6 : 1.0)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToSuccess) {
                ResetSuccessfulView(rootIsActive: rootIsActive)
            }
            .alert("Reset Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private var confirmationDoesNotMatch: Bool {
        !confirmPassword.isEmpty && newPassword != confirmPassword
    }
    
    private var isPasswordValid: Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]).*$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: newPassword)
    }
    
    private func resetPassword() {
        guard isPasswordValid else {
            errorMessage = "Password must contain an uppercase letter, a number, and a special character."
            showAlert = true
            return
        }
        
        guard !newPassword.isEmpty, newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            showAlert = true
            return
        }
        
        isLoading = true
        NetworkManager.shared.resetPassword(email: email, password: newPassword) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success" {
                        navigateToSuccess = true
                    } else {
                        errorMessage = response.message
                        showAlert = true
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

struct ResetSuccessfulView: View {
    @Environment(\.dismiss) var dismiss
    var rootIsActive: Binding<Bool>? = nil
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.appPink)
                    .padding(.bottom, 24)
                
                Text("Reset Successful")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.appText)
                    .padding(.bottom, 12)
                
                Text("Your password has been reset successfully. You can now login with your new password.")
                    .font(.system(size: 16))
                    .foregroundColor(.textHintGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 48)
                
                PrimaryButton(title: "LOGIN NOW") {
                    if let rootIsActive = rootIsActive {
                        rootIsActive.wrappedValue = false
                    } else {
                        dismiss()
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Previews

struct ForgotPasswordPhoneView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ForgotPasswordEmailView()
        }
    }
}

struct OtpVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OtpVerificationView(email: "test@example.com")
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResetPasswordView(email: "test@example.com")
        }
    }
}

struct ResetSuccessfulView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResetSuccessfulView()
        }
    }
}
