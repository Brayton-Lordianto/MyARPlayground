//
//  ContentView.swift
//  test-VR
//
//  Created by Brayton Lordianto on 8/2/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    var body: some View {
        return GreenSpace()
            .ignoresSafeArea()
    }
}
// MARK: make uiviewrepresentable.
// the starting view is in makeuiview
// the coordinator is used to coordinate behaviors during the lifetime
// it is used for foscusing entities
// handle tap is used in the coordinator to handle taps, and generate objects based on tap
struct GreenSpace: UIViewRepresentable {
    // axes mark the anchor origin - center point of the horizontal plane
    // shows the xyz plane of any horizontal view and on every incline
    // I added a package using add package-> enter gh link of entity
    func makeUIView(context: Context) -> ARView {
        let view = ARView()
        
        //MARK: green part
        // Start AR session
        let session = view.session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = session
        coachingOverlay.goal = .horizontalPlane
        view.addSubview(coachingOverlay)
        
        // MARK: focus part
        // Handle ARSession events via delegate
        context.coordinator.view = view
        session.delegate = context.coordinator
        
        // MARK: placing boxes
        // Handle taps
        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleTap)
            )
        )

        
        // Set debug options
#if DEBUG
        view.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
#endif

        
        return view
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // optional class for uiviewrepresentable; remember in playgrounds
    // changes the type of the coordinator and its behaviors
    class Coordinator: NSObject, ARSessionDelegate {
        weak var view: ARView?
        var focusEntity: FocusEntity?
        
        // MARK: focus part
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let view = self.view else { return }
            debugPrint("Anchors added to the scene: ", anchors)
            // use the focus entity dependency
            self.focusEntity = FocusEntity(on: view, style: .classic(color: .yellow))
        }
        
        // MARK: adding the box ON TAP GESTURE
        @objc func handleTap() {
            guard let view = self.view, let focusEntity = self.focusEntity else { return }

            // Create a new anchor to add content to
            let anchor = AnchorEntity()
            view.scene.anchors.append(anchor)

            // Add a Box entity with a blue material
            let box = MeshResource.generateBox(size: 0.5, cornerRadius: 0.05)
            // pretty decent settings
            let textstuff = MeshResource.generateText("WHAT'S UP PEOPLE", font: .boldSystemFont(ofSize: 0.1),  containerFrame: CGRect(), alignment: .center, lineBreakMode: .byTruncatingTail)
            
            let material1 = SimpleMaterial(color: .yellow, isMetallic: true)
            let material2 = SimpleMaterial(color: .blue, isMetallic: false)
            
            // MARK: plus adding the dice
            // materials is the material of the mesh. if put nothing, it becomes a weird candy color
            // using multiple materials is showing no visible changes
            let cubeEntity = ModelEntity(mesh: box, materials: [material2, material1])
            let diceEntity = try! ModelEntity.loadModel(named: "Dice") // from usdz model
            let textEntity = ModelEntity(mesh: textstuff, materials: [material1])
            // ModelEntity(mesh: T##RealityFoundation.MeshResource, materials: T##[RealityFoundation.Material], collisionShapes: T##[RealityFoundation.ShapeResource], mass: T##Float)
            
            // this sets the position, focus entity is where you press, so that becomes the new postion of added
            diceEntity.position = focusEntity.position
            textEntity.position = focusEntity.position + SIMD3(0.5, 0, 0)
            
            // MARK: adding settings to the dice, such as physics
            // get size, must be unscaled, so relative
            let size = diceEntity.visualBounds(relativeTo: diceEntity).extents
            // create a box. ShpaeResource is for collisions
            let boxShape = ShapeResource.generateBox(size: size)
            // make the box a collision so RealityKit can check for collisions
            diceEntity.collision = CollisionComponent(shapes: [boxShape])
            // enable physics by setting a physicsbody component
            diceEntity.physicsBody = PhysicsBodyComponent(
                massProperties: .init(shape: boxShape, mass: 50),
                material: nil,
                mode: .dynamic
            )
            // this works too if you are using a mesh
            let cubePhysics = try! ModelEntity(mesh: box, materials: [material2], collisionShape: boxShape, mass: 10)
            view.debugOptions = [.showAnchorOrigins, .showPhysics]
            
            // MARK: The plane for the dice
            // Create a plane below the dice: so I guess the stuff with mass will fall and not pass the plane
            let planeMesh = MeshResource.generatePlane(width: 2, depth: 2)
            let material = SimpleMaterial(color: .init(white: 1.0, alpha: 0.1), isMetallic: false)
            let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
            planeEntity.position = focusEntity.position
            // is it cuz of static mode?
            planeEntity.physicsBody = PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static)
            planeEntity.collision = CollisionComponent(shapes: [.generateBox(width: 2, height: 0.001, depth: 2)])
            planeEntity.position = focusEntity.position
            anchor.addChild(planeEntity)
            
            // MARK: physics to roll the dice
            diceEntity.addForce([0, 2, 0], relativeTo: nil)
            diceEntity.addTorque([Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4), Float.random(in: 0 ... 0.4)], relativeTo: nil)


            
            // adding multiple is possible. it just spawns both at same time. overlapping
            anchor.addChild(diceEntity)
//            anchor.addChild(cubePhysics)
            anchor.addChild(textEntity)
        }
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}



#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
