import SwiftUI
import SceneKit

struct Hair3DBackground: View {
    var body: some View {
        ZStack {
            // Base background
            Color.white.ignoresSafeArea()
            
            // 3D Scene
            SceneView(
                scene: createHairScene(),
                options: [.allowsCameraControl]
            )
            .opacity(0.15) // Subtle presence
            .ignoresSafeArea()
        }
    }
    
    private func createHairScene() -> SCNScene {
        let scene = SCNScene()
        
        // Root scalp sphere
        let scalp = SCNSphere(radius: 2.0)
        let scalpNode = SCNNode(geometry: scalp)
        scalpNode.position = SCNVector3(x: 0, y: -2.5, z: 0)
        scalpNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink.withAlphaComponent(0.1)
        scene.rootNode.addChildNode(scalpNode)
        
        // Add "Hair Strands"
        for i in 0..<15 {
            let strandHeight = Double.random(in: 1.0...2.5)
            let strand = SCNCylinder(radius: 0.02, height: strandHeight)
            let strandNode = SCNNode(geometry: strand)
            
            // Position on top of the sphere
            let angle = Double(i) * (Double.pi * 2 / 15)
            let radius = 1.0
            strandNode.position = SCNVector3(
                x: Float(cos(angle) * radius),
                y: -1.0,
                z: Float(sin(angle) * radius)
            )
            
            strandNode.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
            
            // Animation for the strand
            let rotate = SCNAction.rotateBy(x: 0.1, y: 0.2, z: 0, duration: Double.random(in: 3...5))
            let sequence = SCNAction.sequence([rotate, rotate.reversed()])
            strandNode.runAction(SCNAction.repeatForever(sequence))
            
            scene.rootNode.addChildNode(strandNode)
        }
        
        // Light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // Slow rotation of the whole world
        let worldRotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 40)
        scene.rootNode.runAction(SCNAction.repeatForever(worldRotate))
        
        return scene
    }
}
