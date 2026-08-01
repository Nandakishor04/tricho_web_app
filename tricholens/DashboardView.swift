import SwiftUI

struct DashboardView: View {
    @State private var navigateToProfile = false
    @State private var navigateToHistory = false
    @State private var navigateToDiagnose = false
    @State private var navigateToHub = false
    @State private var showSupport = false
    @State private var user: User? = nil
    
    var body: some View {
        ZStack {
            Vibrant3DBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Header Section (Bordered)
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good \(getTimeOfDay()),")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Text(user?.name ?? "User")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        // Profile Avatar
                        Button(action: { navigateToProfile = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandPink.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.brandPink)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Primary Action: New Diagnosis
                    Button(action: { navigateToDiagnose = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New AI Analysis")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Check your scalp health in seconds.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "viewfinder.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                        .padding(28)
                        .frame(maxWidth: .infinity)
                        .background(Color.premiumGradient)
                        .cornerRadius(30)
                        .shadow(color: Color.brandPink.opacity(0.3), radius: 15, x: 0, y: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.black, lineWidth: 2) // More prominent
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Secondary Actions Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Explore")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                            
                            // History Card
                            SmallDashboardCard(
                                title: "History",
                                icon: "clock.fill",
                                color: .white,
                                accentColor: .brandPink
                            ) {
                                navigateToHistory = true
                            }
                            
                            // Hair Care Hub
                            SmallDashboardCard(
                                title: "Care Hub",
                                icon: "leaf.fill",
                                color: .white,
                                accentColor: .brandPink
                            ) {
                                navigateToHub = true
                            }
                            
                            // Profile
                            SmallDashboardCard(
                                title: "Profile",
                                icon: "gearshape.fill",
                                color: .white,
                                accentColor: .brandPink
                            ) {
                                navigateToProfile = true
                            }
                            
                            // Support
                            SmallDashboardCard(
                                title: "Help",
                                icon: "questionmark.circle.fill",
                                color: .white,
                                accentColor: .brandPink
                            ) {
                                showSupport = true
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSupport) {
            SupportView()
        }
        .navigationDestination(isPresented: $navigateToProfile) {
            ViewProfileView()
        }
        .navigationDestination(isPresented: $navigateToHistory) {
            HistoryView()
        }
        .navigationDestination(isPresented: $navigateToDiagnose) {
            DiagnoseView()
        }
        .navigationDestination(isPresented: $navigateToHub) {
            HairCareHubView()
        }
        .onAppear {
            user = StorageManager.shared.getUser()
            
            // Sync history
            NetworkManager.shared.fetchHistory { result in
                if case .success(let items) = result {
                    StorageManager.shared.syncHistoryWithServerItems(items)
                }
            }
        }
    }
    
    private func getTimeOfDay() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<21: return "Evening"
        default: return "Night"
        }
    }
}

struct SmallDashboardCard: View {
    var title: String
    var icon: String
    var color: Color
    var accentColor: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.25)) // Increased from 0.1
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(35)
            .overlay(
                RoundedRectangle(cornerRadius: 35)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
        }
    }
}

struct SupportView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Shade
                Color(hex: "FFF4F4").ignoresSafeArea()
                
                ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Welcome
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to use Tricholens")
                            .font(.system(size: 30, weight: .bold))
                        Text("Follow these steps for accurate AI analysis.")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Step 1
                    HelpStepItem(
                        icon: "lightbulb.fill",
                        title: "1. Good Lighting",
                        description: "Use your app in a well-lit room. Natural light is best for high-quality scalp images."
                    )
                    
                    // Step 2
                    HelpStepItem(
                        icon: "camera.viewfinder",
                        title: "2. Capture Clearly",
                        description: "Hold the camera steady and focus on the scalp area where hair is thinning. Avoid blurry shots."
                    )
                    
                    // Step 3
                    HelpStepItem(
                        icon: "brain.head.profile",
                        title: "3. Wait for AI",
                        description: "The AI takes about 3 seconds to analyze the patterns. Ensure you have a stable internet connection."
                    )
                    
                    // Step 4
                    HelpStepItem(
                        icon: "doc.text.magnifyingglass",
                        title: "4. Review Report",
                        description: "Check your results in the History section. You can see density, ratio, and vellus hair details."
                    )
                    
                    VStack(alignment: .center, spacing: 12) {
                        Text("Need more help?")
                            .font(.headline)
                        Text("Contact us at support@tricholens.com")
                            .foregroundColor(.brandPink)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    
                    Spacer()
                }
                .padding(24)
            }
          }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.brandPink)
                }
            }
        }
    }
}

struct HelpStepItem: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.brandPink)
                .frame(width: 40)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black, lineWidth: 1.5)
        )
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
