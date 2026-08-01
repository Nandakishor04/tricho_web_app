import SwiftUI

extension Color {
    static let appPink = Color(hex: "FF8A8A")
    static let appGray = Color(hex: "F5F5F5")
    static let appText = Color(hex: "000000")
    static let appWhite = Color(hex: "FFFFFF")
    static let shadowGrey = Color(hex: "EEEEEE")
    static let appGreen = Color(hex: "90EE90")
    static let textHintGray = Color(hex: "757575")
    static let strokeLightGray = Color(hex: "EEEEEE")
    static let cardBgBlueGray = Color(hex: "F0F4F8")
    static let textDarkGray = Color(hex: "374151")
    static let lightGreen = Color(hex: "E8F5E9")
    
    // Legacy mapping (to avoid breaking existing code immediately)
    static let projectPink = appPink
    static let projectGray = appGray
    static let projectDarkGray = textDarkGray
    static let projectLightGray = strokeLightGray
    static let projectBackground = Color.white
    
    // Black Border Token (formerly borderBright)
    static let borderBright = Color.black
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Premium Design Tokens
extension Color {
    static let brandPink = Color(hex: "FF7070") // Stronger, more vibrant pink
    static let brandPinkDark = Color(hex: "E07A7A") // Stronger dark pink
    static let brandPinkLight = Color(hex: "FFDEDE")
    
    static var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [brandPink, brandPinkDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var lightGradient: LinearGradient {
        LinearGradient(
            colors: [brandPinkLight.opacity(0.3), .white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// Design System Modifiers
struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.04), radius: shadowRadius, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.borderBright, lineWidth: 1.2)
            )
    }
}

extension View {
    func glassStyle(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius))
    }
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Color.brandPink.opacity(0.05).ignoresSafeArea()
            
            // Optimized blobs with smaller blur radii for performance
            Circle()
                .fill(Color.brandPink.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 40)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(Color.brandPinkDark.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 30)
                .offset(x: 180, y: 300)
        }
        .allowsHitTesting(false)
    }
}

// Helper for specific corner rounding (v9.4)
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
