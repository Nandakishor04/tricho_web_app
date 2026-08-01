import SwiftUI

struct HairCareHubView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToTips = false
    @State private var navigateToTricholensAbout = false
    @State private var navigateToPolicy = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
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
                
                Text("Hair Care Hub")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 24)
            .frame(height: 70)
            .background(Color.white)
            
            ZStack {
                Color(hex: "FFF4F4").ignoresSafeArea() // Stronger pink shade
                
                ScrollView {
                    VStack(spacing: 20) {
                        HubMenuCard(title: "Hair Tips", icon: "sparkles", description: "Expert advice for hair growth and maintenance") {
                            navigateToTips = true
                        }
                        
                        HubMenuCard(title: "Tricholens", icon: "leaf.fill", description: "Track and understand your personal hair health mission") {
                            navigateToTricholensAbout = true
                        }
                        
                        HubMenuCard(title: "Privacy Policy", icon: "shield.lefthalf.filled", description: "How we protect and manage your clinical data") {
                            navigateToPolicy = true
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToTips) {
            HairTipsListView()
        }
        .navigationDestination(isPresented: $navigateToTricholensAbout) {
            TricholensAboutView()
        }
        .navigationDestination(isPresented: $navigateToPolicy) {
            PrivacyPolicyView()
        }
    }
}

struct HubMenuCard: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.brandPinkDark)
                    .frame(width: 60, height: 60)
                    .background(Color.brandPink.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.4))
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.borderBright, lineWidth: 0.6)
            )
        }
    }
}

// MARK: - SubViews

struct HairTipsListView: View {
    @Environment(\.presentationMode) var presentationMode
    let tips = [
        Tip(title: "Stay Hydrated", description: "Drinking enough water keeps your hair roots hydrated and prevents breakage."),
        Tip(title: "Avoid Excessive Heat", description: "Minimize use of hair dryers and straighteners. Heat damages hair protein structure."),
        Tip(title: "Eat Protein-Rich Food", description: "Hair is made of protein (keratin). Include eggs, nuts, and fish in your diet."),
        Tip(title: "Massage Your Scalp", description: "Regular scalp massages improve blood circulation, stimulating hair growth."),
        Tip(title: "Use Satin Pillowcases", description: "Satin reduces friction against the hair cuticle, preventing frizz and breakage."),
        Tip(title: "Trim Regularly", description: "Getting a trim every 8-12 weeks helps remove split ends and maintain hair strength.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.black)
                    }
                    Spacer()
                }
                Text("Hair Tips").font(.system(size: 22, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 24).frame(height: 70).background(Color.white)
            
            ZStack {
                Color.brandPink.opacity(0.20).ignoresSafeArea() // Stronger pink tint
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(tips) { tip in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tip.title).font(.system(size: 18, weight: .bold)).foregroundColor(.brandPinkDark)
                                Text(tip.description).font(.system(size: 15)).foregroundColor(.black.opacity(0.8)).lineSpacing(4)
                            }
                            .padding(20).frame(maxWidth: .infinity, alignment: .leading).glassStyle(cornerRadius: 24)
                        }
                        
                        MedicalDisclaimerFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    .padding(24)
                    
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct TricholensAboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.black)
                    }
                    Spacer()
                }
                Text("About Tricholens").font(.system(size: 24, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 24).frame(height: 70).background(Color.white)
            
            ZStack {
                Color.brandPink.opacity(0.20).ignoresSafeArea() // Stronger pink tint
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your personal hair health companion")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            JourneyCard(title: "Our Mission", 
                                        content: "Tricholens helps people understand, track, and improve their hair health using technology and expert medical guidance.")
                            
                            JourneyCard(title: "What We Do", 
                                        items: [
                                            "Provide hair health quizzes and assessments",
                                            "Allow users to track hair growth with photos",
                                            "Connect users with qualified doctors",
                                            "Offer professional feedback and prescriptions"
                                        ])
                            
                            JourneyCard(title: "Why Tricholens?", 
                                        content: "Hair concerns can affect confidence and well-being. Our goal is to make professional hair care guidance accessible, convenient, and personalized.")
                            
                            JourneyCard(title: "Medical Collaboration", 
                                        content: "We work with licensed doctors who review reports and hair images to provide safe and professional recommendations.")
                        }
                        .padding(.bottom, 30)
                        
                        MedicalDisclaimerFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).foregroundColor(.black)
                    }
                    Spacer()
                }
                Text("Privacy Policy").font(.system(size: 24, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 24).frame(height: 70).background(Color.white)
            
            ZStack {
                Color.brandPink.opacity(0.20).ignoresSafeArea() // Stronger pink tint
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        JourneyCard(title: "1. About Tricholens",
                                    content: "Tricholens is an AI-powered trichoscopy diagnostic application designed to assist clinicians and patients in the early detection and monitoring of scalp and hair disorders, with a primary focus on Androgenetic Alopecia (AGA).\n\nAndrogenetic Alopecia is the most prevalent form of hair loss, affecting both men and women worldwide. Characterised by progressive follicular miniaturisation driven by androgen sensitivity, AGA can significantly impact an individual's quality of life and self-confidence. Early and accurate diagnosis is critical to slowing progression and tailoring effective treatment strategies.\n\nHow Tricholens Works:\nUsing your device camera or photo library, Tricholens captures high-resolution scalp images and analyses them through a calibrated deep-learning model trained on clinical trichoscopy datasets. The system evaluates key trichoscopic parameters including:\n\n• Hair follicle density (hairs/cm²)\n• Miniaturised hair ratio (%)\n• Scalp condition classification (AGA, Oily Scalp, Healthy)\n• Vellus-to-terminal hair distribution\n\nResults are generated instantly and presented alongside a structured clinical observation, enabling informed decisions by both practitioners and patients. All diagnoses conducted within Tricholens are intended to supplement — not replace — professional medical consultation. Users are encouraged to share their Tricholens report with a qualified dermatologist or trichologist for a comprehensive evaluation.")

                        JourneyCard(title: "2. Information We Collect",
                                    content: "We collect basic personal information such as your name, email address, phone number, date of birth, and location when you create an account.\n\nWe also collect health-related inputs such as scalp images, patient history, treatment records, and diagnostic results to provide personalised clinical services.")

                        JourneyCard(title: "3. How We Use Your Information",
                                    items: [
                                        "Provide AI-powered scalp and hair health assessments",
                                        "Allow clinicians to review diagnostic reports and images",
                                        "Manage patient records, treatment history, and follow-ups",
                                        "Improve model accuracy and overall application performance"
                                    ], listHeader: "Your information is used to:")

                        JourneyCard(title: "4. Hair Images & Medical Data",
                                    content: "Scalp images and diagnostic results you submit are processed securely within the application and are shared only with registered clinicians for professional review.\n\nTricholens does not sell, distribute, or publicly disclose your personal, medical, or biometric data to any third party. All data handling is conducted in accordance with applicable data protection regulations.")
                        .padding(.bottom, 20)

                        MedicalDisclaimerFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct JourneyCard: View {
    let title: String
    var content: String? = nil
    var items: [String]? = nil
    var listHeader: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.brandPinkDark)
            
            if let content = content {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.8))
                    .lineSpacing(4)
            }
            
            if let items = items {
                if let listHeader = listHeader {
                    Text(listHeader)
                        .font(.system(size: 15))
                        .foregroundColor(.black.opacity(0.8))
                }
                
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.8))
                            .lineSpacing(4)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.95))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
}
