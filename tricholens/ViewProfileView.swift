import SwiftUI

struct ViewProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToLogin = false
    @State private var navigateToUpdate = false
    @State private var user: User? = nil
    
    var body: some View {
        ZStack {
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section (Premium Gradient)
                    VStack(spacing: 0) {
                        // Top Bar
                        ZStack {
                            HStack {
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                
                                Button(action: {
                                    navigateToUpdate = true
                                }) {
                                    Text("Edit")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(20)
                                }
                            }
                            
                            Text("My Profile")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 4) {
                                Text(user?.name ?? "User")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(user?.email ?? "email@example.com")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color.white.opacity(0.9))
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 60)
                    }
                    .background(Color.premiumGradient)
                    .clipShape(RoundedCorner(radius: 40, corners: [.bottomLeft, .bottomRight]))
                    
                    // Details Section (Overlapping)
                    VStack(spacing: 16) {
                        ProfileDetailCard(iconName: "iphone", label: "Mobile Number", value: user?.mobile ?? "Not provided")
                        ProfileDetailCard(iconName: "calendar", label: "Date of Birth", value: user?.dob ?? "Not provided")
                        ProfileDetailCard(iconName: "person.fill", label: "Age", value: user?.age ?? "Not provided")
                        ProfileDetailCard(iconName: "person.2.fill", label: "Gender", value: user?.gender ?? "Not provided")
                        ProfileDetailCard(iconName: "globe", label: "Country", value: user?.country ?? "Not provided")
                        
                        // Sign out Button
                        PrimaryButton(title: "Sign out", useGradient: true) {
                            StorageManager.shared.clearUser()
                            navigateToLogin = true
                        }
                        .padding(.top, 16)
                    }
                    .padding(24)
                    .padding(.top, -40)
                }
            }
        }
        .onAppear {
            user = StorageManager.shared.getUser()
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToLogin) {
            LoginView()
        }
        .navigationDestination(isPresented: $navigateToUpdate) {
            UpdateProfileView()
        }
    }
}

struct ProfileDetailCard: View {
    let iconName: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.brandPinkDark)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .padding(20)
        .glassStyle(cornerRadius: 24)
    }
}

struct ViewProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ViewProfileView()
    }
}
