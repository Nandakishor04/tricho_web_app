import SwiftUI

struct LoginView: View {
    @State private var identifier = ""
    @State private var password = ""
    @State private var navigateToDashboard = false
    @State private var navigateToSignup = false
    @State private var navigateToForgotPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            ScrollView {
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
                            Text("Welcome Back")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("Sign in to continue")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    
                    // Login Card
                    VStack(spacing: 20) {
                        CustomTextField(hint: "Email Address", text: $identifier, keyboardType: .emailAddress, iconName: "envelope")
                        
                        VStack(alignment: .trailing, spacing: 12) {
                            CustomTextField(hint: "Password", text: $password, isSecure: true, iconName: "lock")
                            
                            Button(action: {
                                navigateToForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.brandPink.opacity(0.8))
                            }
                        }
                        
                        PrimaryButton(title: isLoading ? "LOGGING IN..." : "LOGIN", useGradient: false, backgroundColor: Color.brandPink) {
                            login()
                        }
                        .disabled(isLoading)
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.borderBright, lineWidth: 1.0)
                    )
                    .padding(.horizontal, 24)
                    
//                    // Signup Footer
//                    HStack {
//                        Text("Don't have an account? ")
//                            .font(.system(size: 16))
//                            .foregroundColor(.gray)
//                        
//                        Button(action: {
//                            navigateToSignup = true
//                        }) {
//                            Text("Sign Up")
//                                .font(.system(size: 16, weight: .bold))
//                                .foregroundColor(.brandPink.opacity(0.8))
//                        }
//                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToDashboard) {
            DashboardView()
        }
        .navigationDestination(isPresented: $navigateToSignup) {
            SignupView()
        }
        .navigationDestination(isPresented: $navigateToForgotPassword) {
            ForgotPasswordEmailView(rootIsActive: $navigateToForgotPassword)
        }
        .alert("Login Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }
    
    private func login() {
        guard !identifier.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showAlert = true
            return
        }
        
        isLoading = true
        NetworkManager.shared.login(username: identifier, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    if response.status == "success", let user = response.user {
                        StorageManager.shared.saveUser(user)
                        navigateToDashboard = true
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LoginView()
        }
    }
}
