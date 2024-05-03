//
//  DiceView.swift
//  Yeeha!
//
//  Created by Martin Davy on 3/18/24.
//

import SwiftUI
import SceneKit

let diceCategory: Int = 1
let wallCategory: Int = 2
let initialDicePositions: [SCNVector3] = [
    SCNVector3(-0.5, 0, -0.5),
    SCNVector3(0.5, 0, -0.5),
    SCNVector3(-0.5, 0, 0.5),
    SCNVector3(0.5, 0, 0.5),
    SCNVector3(0, 0, -0.5),
    SCNVector3(0, 0, 0.5)
]

public struct DiceView: UIViewRepresentable {
    let scene: SCNScene
    let diceModel : DiceModel
    
    init(diceModel: DiceModel) {
        self.scene = DiceView.createDiceScene(diceModel)
        self.diceModel = diceModel
    }
    
    private static func createDiceScene(_ diceModel: DiceModel) -> SCNScene {
        let scene = SCNScene()
        
        let t = 0.01
        let w = 3.0
        let l = w * 2.0
        
        // Create the walls, floor and dice
        let leftWall = createWall(named: "leftWall", width: t, height: l, length: l, position: SCNVector3(-w, w, 0), color: .green, transparency: 0)
        let rightWall = createWall(named: "rightWall", width: t, height: l, length: l, position: SCNVector3(w, w, 0), color: .red, transparency: 0)
        let backWall = createWall(named: "backWall", width: l, height: l, length: t, position: SCNVector3(0, w, -w), color: .blue, transparency: 0)
        let frontWall = createWall(named: "frontWall", width: l, height: l, length: t, position: SCNVector3(0, w, w), color: .cyan, transparency: 0)
        let roof = createWall(named: "roof", width: l, height: t, length: l, position: SCNVector3(0, l, 0), color: .yellow, transparency: 0)
        let floor = createFloor()
        
        for i in 0..<diceModel.numberOfDice {
            let die = createDie(id: i + 1, value: diceModel.values[i], diceModel: diceModel)
            // Position the dice at the initial positions
            die.position = initialDicePositions[i]
            scene.rootNode.addChildNode(die)
        }
        
        // Add the walls, floor and dice
        scene.rootNode.addChildNode(leftWall)
        scene.rootNode.addChildNode(rightWall)
        scene.rootNode.addChildNode(backWall)
        scene.rootNode.addChildNode(frontWall)
        scene.rootNode.addChildNode(floor)
        scene.rootNode.addChildNode(roof)
        
        // Create and position the camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 8, z: 4)
        cameraNode.eulerAngles = SCNVector3(x: -Float.pi / 3, y: 0, z: 0) // Rotate the camera
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private static func image(from faceString: String, size: CGSize, color: UIColor, backgroundColor: UIColor) -> UIImage? {
        let nsString = NSString(string: faceString)
        let font = UIFont.systemFont(ofSize: size.width)
        let stringAttributes = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color]
        let imageSize = nsString.size(withAttributes: stringAttributes)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: imageSize))
        }
        nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private static func createDie(id: Int, value: Int, diceModel: DiceModel) -> SCNNode {
        let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.1)
        let faceOrder = faceOrderForValue(value)
        
        var materials = [SCNMaterial]()
        for faceValue in faceOrder {
            let material = SCNMaterial()
            let materialName = diceModel.faces[faceValue - 1]
            switch diceModel.faceScheme {
            case .namedImage:
                material.diffuse.contents = UIImage(named: materialName)
            case .string:
                material.diffuse.contents = image(
                    from: materialName,
                    size: CGSize(width: 100, height: 100),
                    color: diceModel.foregroundColor,
                    backgroundColor: diceModel.backgroundColor
                )
            }
            material.name = materialName
            materials.append(material)
        }
        box.materials = materials
        let node = SCNNode(geometry: box)
        node.name = "dice\(id)"
        node.position = SCNVector3(0, 0, 0)
        
        // Add a physics body to the dice node
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.restitution = 0.6 // Bounciness
        physicsBody.friction = 0.5 // Friction
        physicsBody.damping = 0.5 // Damping
        physicsBody.allowsResting = true // Allow the physics body to rest
        node.physicsBody = physicsBody
        
        // Set the category and collision bit masks
        node.physicsBody?.categoryBitMask = diceCategory
        node.physicsBody?.collisionBitMask = diceCategory | wallCategory
        node.physicsBody?.contactTestBitMask = diceCategory | wallCategory
        
        return node
    }
    
    private static func createWall(
        named: String?,
        width: CGFloat,
        height: CGFloat,
        length: CGFloat,
        position: SCNVector3,
        color: UIColor,
        transparency: CGFloat = 1.0
    ) -> SCNNode {
        
        let wall = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
        let material = createMaterial(color: color)
        material.transparency = transparency
        
        wall.materials = [material]
        
        let wallNode = SCNNode(geometry: wall)
        wallNode.name = named
        wallNode.position = position
        
        // Add physics body to the wall
        let wallPhysicsBody = SCNPhysicsBody(type: .static, shape: nil)
        wallPhysicsBody.categoryBitMask = wallCategory
        wallPhysicsBody.collisionBitMask = wallCategory | diceCategory
        wallNode.physicsBody = wallPhysicsBody
        return wallNode
    }
    
    private static func createMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        return material
    }
    
    private static func createFloor() -> SCNNode {
        // Create the floor
        let floor = SCNFloor()
        
        let floorColor = UIColor(red: 0.0/255.0, green: 100.0/255.0, blue: 0.0/255.0, alpha: 1)
        
        let material = SCNMaterial()
        material.diffuse.contents = floorColor
        
        floor.materials = [material]
        let floorNode = SCNNode(geometry: floor)
        floor.name = "floor"
        floorNode.position = SCNVector3(0, 0, 0) // Position the floor just below the dice
        
        // Give the floor a physics body
        let floorPhysicsBody = SCNPhysicsBody(type: .static, shape: nil)
        floorPhysicsBody.restitution = 0.8 // Bounciness
        floorPhysicsBody.friction = 0.5 // Friction
        floorNode.physicsBody = floorPhysicsBody
        
        // Set the category and collision bit masks
        floorNode.physicsBody?.categoryBitMask = wallCategory
        floorNode.physicsBody?.collisionBitMask = wallCategory | diceCategory
        
        return floorNode
    }
    
    public func makeCoordinator() -> Coordinator {
        return Coordinator(scene: scene, diceModel: diceModel)
    }
    
    public func makeUIView(context: Context) -> SCNView {
        
        let scnView = SCNView()
        
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.scene?.physicsWorld.contactDelegate = context.coordinator
        
        context.coordinator.diceNodes = scnView.scene?.rootNode.childNodes.filter { $0.name?.starts(with: "dice") ?? false }
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    public func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.handleRoll(scnView: scnView)
        context.coordinator.handleArrange(scnView: scnView)
    }
    
    public class Coordinator : NSObject, SCNPhysicsContactDelegate {
        let scene: SCNScene
        var diceNodes: [SCNNode]?
        var direction: Float = 1.0 // Variable to alternate the direction of the force
        let diceModel : DiceModel
        var initialFaceDirections : [String: [simd_float3]]
        
        init(scene: SCNScene, diceModel: DiceModel) { // Change this line
            self.scene = scene
            self.diceModel = diceModel
            self.diceNodes = scene.rootNode.childNodes.filter { $0.name?.starts(with: "dice") ?? false }
            self.initialFaceDirections = determineInitialFaceDirections(diceModel: diceModel)
            super.init()
        }
        
        @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            
            print("Handle Tap")
            
            // don't want to select dice while they are rolling
            guard diceModel.roll == false else {
                return
            }
            
            // Get the SCNView
            guard let scnView = gestureRecognize.view as? SCNView else {
                print("sender was not a SCNView - ignoring")
                return
            }
            
            // Get the location of the tap in the SCNView
            let p = gestureRecognize.location(in: scnView)
            
            // Perform a hit test on the view
            let hitResults = scnView.hitTest(p, options: [.searchMode: NSNumber(value: SCNHitTestSearchMode.all.rawValue)])
            
            
            // Filter the hit test results to only include dice nodes
            let diceHitResults = hitResults.filter { $0.node.name?.starts(with: "dice") ?? false }
            
            // Check if the hit test found at least one node
            if let result = diceHitResults.first {
                // Get the node that was tapped
                let node = result.node
                print("Hit a node named: \(String(describing: node.name))")
                toggleSelection(for: node)
            }
        }
        
        private func arrangeDice(positions: [SCNVector3]? = nil) {
            guard let diceNodes = diceNodes, diceModel.arrangeDice else {
                return
            }
            
            for (index, diceNode) in diceNodes.enumerated() {
                guard let dieName = diceNode.name else {
                    print("found diceNode with no name")
                    continue
                }
                
                guard let die = diceModel.getDie(byName: dieName) else {
                    print("unable to find die with name: \(diceNode.name ?? "")")
                    continue
                }
                
                let topValue = die.value
                
                // Update the geometry and materials of the dice node
                if let diceGeometry = diceNode.geometry as? SCNBox {
                    let faceOrder = faceOrderForValue(topValue)
                    
                    var materials = [SCNMaterial]()
                    for faceValue in faceOrder {
                        let material = SCNMaterial()
                        let materialName = diceModel.faces[faceValue - 1]
                        switch diceModel.faceScheme {
                        case .namedImage:
                            material.diffuse.contents = die.isSelected ? UIImage(named: "\(materialName)x") : UIImage(named: materialName)
                        case .string:
                            material.diffuse.contents = image(
                                from: materialName,
                                size: CGSize(width: 100, height: 100),
                                color: die.isSelected ? diceModel.selectedColor : diceModel.foregroundColor,
                                backgroundColor: diceModel.backgroundColor
                            )
                        }
                        material.name = materialName
                        materials.append(material)
                    }
                    diceGeometry.materials = materials
                }
                
                // Position the dice at the new positions
                diceNode.position = positions?[index] ?? initialDicePositions[index]
                
                // Update the initial face directions for the die
                initialFaceDirections = determineInitialFaceDirections(diceModel: diceModel)
            }
            
            diceModel.arrangeDice = false;
        }
        
        func toggleSelection(for node : SCNNode) {
            
            guard let dieName = node.name else {
                print("dice node with no name found!")
                return
            }
            
            // Toggle the selection state of the dice
            diceModel.toggleSelection(byName: dieName)
            let selected = diceModel.isSelected(dieName: dieName)
            
            // Iterate over each material
            for material in node.geometry!.materials {
                guard let materialName = material.name else {
                    print("unnamed material found on die face")
                    continue
                }
                
                // Determine the image name or string to use based on selection state
                switch diceModel.faceScheme {
                case .namedImage:
                    var imageName = String(materialName.prefix(5))
                    if selected {
                        imageName.append("x")
                    }
                    material.diffuse.contents = UIImage(named: imageName)
                case .string:
                    let faceString = String(materialName.prefix(1))
                    let color: UIColor = selected ? diceModel.selectedColor : diceModel.backgroundColor
                    material.diffuse.contents = image(
                        from: faceString,
                        size: CGSize(width: 100, height: 100),
                        color: diceModel.foregroundColor,
                        backgroundColor: color
                    )
                }
            }
        }
        
        func handleArrange(scnView: SCNView) {
            
            if !diceModel.roll {
                arrangeDice()
            }
        }
        
        func handleRoll(scnView: SCNView) {
            if diceModel.roll {
                runSimulation(scnView)
            }
        }
        
        func faceOnTop(diceNode : SCNNode) -> Int? {
            
            // Get the orientation of the dice node as a quaternion
            let orientation = diceNode.presentation.simdOrientation
            
            guard let diceName = diceNode.name else {
                print("found dice node with no name")
                return nil
            }
            
            guard let faceDirections = initialFaceDirections[diceName] else {
                print("unable to find initial face directions for dice named: \(diceName)")
                return nil
            }
            
            // Rotate the up direction in the dice node's local coordinate system to the world coordinate system
            let up = simd_float3(0, 1, 0)
            
            // Find the face direction that is closest to the up direction
            var value = 6 // default to 6
            for i in 0..<3 {  // loop over three unit vectors
                let faceDirection = faceDirections[i]
                let a = simd_dot(up, orientation.act(faceDirection))  // rotate with orientation and project onto 'up'
                if a > 0.7071 { value = i + 1; break }  // is face up?
                if a < -0.7071 { value = 7 - (i + 1); break } // is face down?
            }
            
            return value
        }
        
        public func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
            
            //if let speed = diceNode?.physicsBody?.velocity.length()  {
            guard let diceNodes = diceNodes else {
                return
            }
            
            guard diceModel.roll else {
                return
            }
            
            let anyDiceResting = diceNodes.contains {
                // Exclude selected dice
                if diceModel.isSelected(dieName: $0.name ?? "") {
                    return false
                }
                return $0.physicsBody?.isResting ?? false
            }
            
            if anyDiceResting {
                diceModel.roll = false
                var values = [Int]()
                for diceNode in diceNodes {
                    if let value = faceOnTop(diceNode: diceNode) {
                        diceModel.updateValue(byName: diceNode.name!, with: value)
                        values.append(value)
                    }
                }
                rollComplete()
            }
        }
        
        func rollComplete() {
            DispatchQueue.main.async {
                if let callback = self.diceModel.onRollComplete {
                    callback(self.diceModel.dice.map {$0.value})
                }
                self.diceModel.roll = false
            }
        }
        
        func runSimulation(_ scnView: SCNView) {
            guard let diceNodes = diceNodes else {
                return
            }
            
            // If all dice are selected, do nothing
            if diceNodes.allSatisfy({ diceModel.isSelected(dieName: $0.name ?? "") }) {
                rollComplete()
                return
            }
            
            // Increase gravity
            //scnView.scene?.physicsWorld.gravity = SCNVector3(0, -20, 0) // Default is -9.8
            
            for diceNode in diceNodes {
                
                // if a die is selected, we want don't want it to roll
                guard let dieName = diceNode.name else {
                    print("found die with no name in runSimulation")
                    continue
                }
                if diceModel.isSelected(dieName: dieName) {
                    continue
                }
                
                // Generate random rotation angles
                let randomX = direction * Float(arc4random_uniform(4) + 1) * (Float.pi/8)
                let randomZ = direction * Float(arc4random_uniform(4) + 1) * (Float.pi/8)
                
                // Apply the rotation as a force
                let force = SCNVector3(x: randomX, y: 8, z: randomZ) // Add a slight upward force
                let position = SCNVector3(x: 0.3, y: 0.3, z: 0.3) // Apply the force at an offset from the center of the dice
                diceNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
            }
            
            // Flip the direction for the next tap
            direction *= -1
        }
    }
}

func arraysAreEqual(array1: [simd_float3], array2: [simd_float3]) -> Bool {
    guard array1.count == array2.count else {
        return false
    }
    
    for (vector1, vector2) in zip(array1, array2) {
        if vector1 != vector2 {
            return false
        }
    }
    
    return true
}

func determineInitialFaceDirections(diceModel: DiceModel) -> [String: [simd_float3]] {
    
    var initialOrientations : [String: [simd_float3]] = [:]
    
    // build a map of dice node names to orientations
    for i in 0..<diceModel.values.count {
        let faceDirections = determineFaceDirections(topValue: diceModel.values[i])
        initialOrientations["dice\(i+1)"] = faceDirections
    }
    
    return initialOrientations
}

func faceImagesFromValue(value: Int) -> [String] {
    let order = faceOrderForValue(value)
    return order.map { "dice\($0)" }
}

func faceOrderForValue(_ value: Int) -> [Int] {
    switch value {
    case 1:
        return [2, 3, 5, 4, 1, 6] // 2-front, 3-right, 5-back, 4-left, 1-top, 6-bottom
    case 2:
        return [1, 4, 6, 3, 2, 5] // 1-front, 4-right, 6-back, 3-left, 2-top, 5-bottom
    case 3:
        return [1, 2, 6, 5, 3, 4] // 1-front, 2-right, 6-back, 5-left, 3-top, 4-bottom
    case 4:
        return [6, 2, 1, 5, 4, 3] // 1-front, 5-right, 6-back, 2-left, 4-top, 3-bottom
    case 5:
        return [4, 6, 3, 1, 5, 2] // 1-front, 3-right, 6-back, 4-left, 5-top, 2-bottom
    case 6:
        return [3, 2, 4, 5, 6, 1] // 3-front, 2-right, 4-back, 5-left, 6-top, 1-bottom
    default:
        return []
    }
}

/**
 Find the vector positions of the dice values 1,2 and 3.
 Once we have those, the others can be inferred because opposing faces add up to 7
 the dice value are ordered: front(0), right(1), back(2), left(3), top(4), bottom(5),
 So if the value 1 is at index 0, it is the front face, and so first the vector will be (0, 0, 1).
 If the value 1 is at index 1, it is the right face, and the first vector will be (1, 0, 0) and so on
 */
func determineFaceDirections(topValue: Int) -> [simd_float3] {
    let faceOrder = faceOrderForValue(topValue)
    var faceDirections: [simd_float3] = []
    
    for i in 0..<3 {
        if let index = faceOrder.firstIndex(of: i + 1) {
            switch index {
            case 0:
                faceDirections.append(simd_float3(0, 0, 1)) // it is the front face (z = 1)
            case 1:
                faceDirections.append(simd_float3(1, 0, 0)) // right face (x = 1)
            case 2:
                faceDirections.append(simd_float3(0, 0, -1)) // back face (z = -1)
            case 3:
                faceDirections.append(simd_float3(-1, 0, 0)) // left face (x= -1)
            case 4:
                faceDirections.append(simd_float3(0, 1, 0)) // top face (y=1)
            case 5:
                faceDirections.append(simd_float3(0, -1, 0)) // bottom face (y=-1)
            default:
                break
            }
        }
    }
    
    return faceDirections
}

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
}

extension UIColor {
    func blended(withFraction fraction: CGFloat, of color: UIColor) -> UIColor {
        let fraction = max(min(fraction, 1), 0)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(
            red: r1 * (1 - fraction) + r2 * fraction,
            green: g1 * (1 - fraction) + g2 * fraction,
            blue: b1 * (1 - fraction) + b2 * fraction,
            alpha: a1 * (1 - fraction) + a2 * fraction
        )
    }
}

extension UIImage {
    func tinted(with color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        guard let cgImage = self.cgImage else { return self }
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}

