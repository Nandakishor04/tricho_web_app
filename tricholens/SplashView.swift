import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        NavigationStack {
            ZStack {
            PremiumBackground()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo Image
                    Image("logo") // Standardized logo name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)
                        .padding(.bottom, 20)
                    
                    Text("TRICHOLENS")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundColor(.appText)
                        .tracking(2)
                        .padding(.bottom, 40)
                    
                    NavigationLink(destination: LoginView()) {
                        Text("Start")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 60)
                            .background(Color.appPink)
                            .cornerRadius(30)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
