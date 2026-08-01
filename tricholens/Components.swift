import SwiftUI

struct PrimaryButton: View {
    let title: String
    var useGradient: Bool = true
    var backgroundColor: Color = .brandPink
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    Group {
                        if useGradient {
                            Color.premiumGradient
                        } else {
                            backgroundColor
                        }
                    }
                )
                .cornerRadius(30)
                .shadow(color: Color.brandPinkDark.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

struct CustomTextField: View {
    let hint: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var iconName: String? = nil
    
    @State private var isVisible: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure && !isVisible {
                        SecureField(hint, text: $text)
                            .foregroundColor(.black)
                    } else {
                        TextField(hint, text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.black)
                    }
                }
                .font(.system(size: 16))
                
                Spacer() // Pushes content to the left
                
                if isSecure {
                    Button(action: {
                        isVisible.toggle()
                    }) {
                        Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(isVisible ? .brandPink : .gray)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 56)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.borderBright, lineWidth: 1.0)
            )
        }
    }
}

struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    var useChevron: Bool = true // Default is now chevron to match Profile/History
    var size: CGFloat = 20
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: useChevron ? "chevron.left" : "arrow.left")
                .foregroundColor(.black)
                .font(.system(size: size, weight: .bold))
        }
    }
}

struct MedicalDisclaimerFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // ── Medical Disclaimer Header ─────────────────────────
            Text("⚠️ Important Medical Disclaimer")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("This result is AI-assisted and provided for informational purposes only. It is not a definitive medical diagnosis. The app does not replace professional medical evaluation. Results may vary based on image quality and conditions. Always consult a qualified dermatologist or healthcare professional before making any medical decisions.")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
                
                Text("This tool is intended for screening support only and not for clinical diagnosis or treatment.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider().padding(.vertical, 6)
            
            // ── Medical Citations Section ─────────────────────────
            VStack(alignment: .leading, spacing: 12) {
                Text("Medical references used for generating this result:")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .italic()
                
                Text("📚 Medical Citations & Sources")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                VStack(alignment: .leading, spacing: 16) {
                    CitationLink(title: "Mayo Clinic – Hair Loss: Diagnosis & Treatment", url: "https://www.mayoclinic.org/diseases-conditions/hair-loss/diagnosis-treatment/drc-20372932")
                    CitationLink(title: "NIH (MedlinePlus) – Androgenetic Alopecia", url: "https://medlineplus.gov/genetics/condition/androgenetic-alopecia/")
                    CitationLink(title: "National Library of Medicine (NCBI) – Trichoscopy in Androgenetic Alopecia (Clinical Study)", url: "https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8143160/")
                }
                
                Text("These references include clinical dermatology research supporting hair density, vellus hair percentage, and miniaturization analysis used in this app.")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1.5)
        )
    }
}

struct CitationLink: View {
    let title: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 14))
                    .padding(.top, 2)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .underline()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Previews

struct Components_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButton(title: "Primary Button") {}
            
            PrimaryButton(title: "Pink Button", useGradient: false) {}
            
            CustomTextField(hint: "Name", text: .constant(""))
            
            CustomTextField(hint: "Secure Field", text: .constant("password"), isSecure: true, iconName: "lock")
            
            BackButton()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
