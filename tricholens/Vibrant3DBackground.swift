import SwiftUI
import SceneKit

struct Vibrant3DBackground: View {
    var body: some View {
        ZStack {
            // Deeper Pink shade background
            LinearGradient(
                colors: [Color(hex: "FED9D9"), Color(hex: "FFCACA")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 3D Scene
            SceneView(
                scene: createFallingHairScene(),
                options: []
            )
            .opacity(0.6) // Increased from 0.5
            .ignoresSafeArea()
            .background(Color.clear)
        }
    }
    
    private func createFallingHairScene() -> SCNScene {
        let scene = SCNScene()
        
        let colors: [UIColor] = [
            UIColor(hex: "FF7070"), // Brand Pink
            UIColor(hex: "FFB2B2"), // Soft Pink
            UIColor(hex: "FF8585"), // Mid Pink
            UIColor(hex: "E07A7A")  // Dark Pink
        ]
        
        // Add "Falling Hair" strands
        for _ in 0..<50 {
            // Make strands very thin and naturally long to look like hair
            let hairLength = CGFloat.random(in: 2.0...5.0)
            let hair = SCNCylinder(radius: 0.008, height: hairLength) // Extremely thin
            let hairNode = SCNNode(geometry: hair)
            
            // Initial random position (starting above view)
            hairNode.position = SCNVector3(
                x: Float.random(in: -8...8),
                y: Float.random(in: 5...15),
                z: Float.random(in: -10 ... -2)
            )
            
            // Random tilt to look natural
            hairNode.eulerAngles = SCNVector3(
                x: Float.random(in: -0.2...0.2),
                y: Float.random(in: 0...Float.pi),
                z: Float.random(in: -0.2...0.2)
            )
            
            let material = SCNMaterial()
            material.diffuse.contents = colors.randomElement()
            material.shininess = 0.5
            hairNode.geometry?.materials = [material]
            
            // Falling Animation
            let fallDistance: Float = 25.0
            let duration = Double.random(in: 6...12)
            
            let fallAction = SCNAction.moveBy(x: CGFloat.random(in: -2...2), y: CGFloat(-fallDistance), z: 0, duration: duration)
            
            // Reset to top to loop effectively
            let resetAction = SCNAction.customAction(duration: 0) { node, _ in
                node.position.y = Float.random(in: 10...15)
                node.position.x = Float.random(in: -8...8)
            }
            
            let sequence = SCNAction.sequence([fallAction, resetAction])
            hairNode.runAction(SCNAction.repeatForever(sequence))
            
            // Subtle swaying/rotating while falling
            let sway = SCNAction.rotateBy(x: 0.3, y: 0.3, z: 0.3, duration: 3)
            hairNode.runAction(SCNAction.repeatForever(SCNAction.sequence([sway, sway.reversed()])))
            
            scene.rootNode.addChildNode(hairNode)
        }
        
        // Add bio-spheres for depth
        for _ in 0..<10 {
            let sphere = SCNSphere(radius: CGFloat.random(in: 0.05...0.15))
            let node = SCNNode(geometry: sphere)
            node.position = SCNVector3(Float.random(in: -5...5), Float.random(in: -10...10), Float.random(in: -12 ... -3))
            
            let mat = SCNMaterial()
            mat.diffuse.contents = colors.randomElement()?.withAlphaComponent(0.6)
            node.geometry?.materials = [mat]
            
            scene.rootNode.addChildNode(node)
        }
        
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(light)
        
        return scene
    }
}

// Extension for UIColor hex support (internal to this file if needed)
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
