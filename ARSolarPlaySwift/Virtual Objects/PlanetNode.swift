//
//  PlanetNode.swift
//  ARSolarPlaySwift
//
//  Created by 石高扬 on 2017/11/17.
//  Copyright © 2017年 Alex yang. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class PlanetNode: SCNNode {
    
    /// Planet type
    let planetType:PlanetEnum
    ///
    var node:SCNNode!
    /// Use average of recent virtual object distances to avoid rapid changes in object scale.
    private var recentVirtualObjectDistances = [Float]()
    
    /// Resets the objects poisition smoothing.
    func reset() {
        recentVirtualObjectDistances.removeAll()
    }
    
    init(planet: PlanetEnum) {
        
        self.planetType = planet
        let planetData = planet.getPlanet()
        
        super.init()
        
        let geome = SCNSphere(radius: planetData.radius)
        geome.firstMaterial?.diffuse.contents = planetData.diffuse
        geome.firstMaterial?.specular.contents = planetData.specular
        geome.firstMaterial?.emission.contents = planetData.emission
        geome.firstMaterial?.normal.contents = planetData.normal
        self.position = SCNVector3(planetData.distance, 0, 0)
        
        if(planetData.hasChild!) {
            
            node = SCNNode()
            node.geometry = geome
            node.position = SCNVector3(0, 0, 0)
            self.addChildNode(node)
            
            if !planetData.anxisTime.isZero {
                node.runAction(getPlanetRotation(duration: planetData.anxisTime)) }
        } else {
            
            self.geometry = geome
            if !planetData.anxisTime.isZero {
                self.runAction(getPlanetRotation(duration: planetData.anxisTime)) }
        }
        
        /// addLight as sun
        self.addLight(planet: planet)
        /// addLoop as saturn
        self.addPlanetLoop(planet: planet)
    }
    
    /**
     Set the object's position based on the provided position relative to the `cameraTransform`.
     If `smoothMovement` is true, the new position will be averaged with previous position to
     avoid large jumps.
     
     - Tag: VirtualObjectSetPosition
     */
    func setPosition(_ newPosition: float3, relativeTo cameraTransform: matrix_float4x4, smoothMovement: Bool) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newPosition - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(positionOffsetFromCamera) > 10 {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        
        /*
         Compute the average distance of the object from the camera over the last ten
         updates. Notice that the distance is applied to the vector from
         the camera to the content, so it affects only the percieved distance to the
         object. Averaging does _not_ make the content "lag".
         */
        if smoothMovement {
            let hitTestResultDistance = simd_length(positionOffsetFromCamera)
            
            // Add the latest position and keep up to 10 recent distances to smooth with.
            recentVirtualObjectDistances.append(hitTestResultDistance)
            recentVirtualObjectDistances = Array(recentVirtualObjectDistances.suffix(10))
            
            let averageDistance = recentVirtualObjectDistances.average!
            let averagedDistancePosition = simd_normalize(positionOffsetFromCamera) * averageDistance
            simdPosition = cameraWorldPosition + averagedDistancePosition
        } else {
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
    }
    
    /// - Tag: AdjustOntoPlaneAnchor
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) {
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else { return }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return
        }
        
        // Move onto the plane if it is near it (within 5 centimeters).
        let verticalAllowance: Float = 0.05
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }

    func addPlanet(planet:PlanetEnum) {
        
        let orbitNode = self.getPlanetOribit(planet: planet.getPlanet())
        self.addChildNode(orbitNode)
        
        let planetNode = PlanetNode(planet:planet)
        let rotateNode = SCNNode()
        rotateNode.addChildNode(planetNode)
        
        let planetData = planet.getPlanet()
        let action = getPlanetRotation(duration: planetData.revolutionTime!)
        rotateNode.runAction(action)
        
        self.addChildNode(rotateNode)
    }
    
    func addPlanet(planetNode: PlanetNode) {
        
        let planet = planetNode.planetType
        
        let orbitNode = self.getPlanetOribit(planet: planet.getPlanet())
        self.addChildNode(orbitNode)
        
        let rotateNode = SCNNode()
        rotateNode.addChildNode(planetNode)
        
        let action = getPlanetRotation(duration: planet.getPlanet().revolutionTime!)
        rotateNode.runAction(action)
        
        self.addChildNode(rotateNode)
    }
    // MARK: Private Planet method
    private func getPlanetOribit(planet: Planet) -> SCNNode {
        
        let oribitNode = SCNNode()
        oribitNode.position = SCNVector3(0, 0, 0)
        
        let ringRadius = planet.distance
        oribitNode.geometry = SCNTorus(ringRadius: CGFloat(ringRadius), pipeRadius: 0.0004)
        oribitNode.geometry?.firstMaterial?.multiply.contents = UIColor(red: 255, green: 255, blue: 255, alpha: 0.3)
        
        return oribitNode
    }
    
    private func addPlanetLoop(planet: PlanetEnum) {
        
        if planet == .saturn {
            
            let loopNode = PlanetLoop(planet: planet)
            self.addChildNode(loopNode)
        }
    }
    
    private func addLight(planet: PlanetEnum) {
        
        if planet == .sun {
            
            let lightNode = SCNNode()
            
            lightNode.light = SCNLight()
            lightNode.light?.color = UIColor.white
            lightNode.light?.type = .omni
            node?.addChildNode(lightNode)
            
            /// add sun halo
            let haloNode = SCNNode()
            haloNode.geometry = SCNPlane(width: 1.2, height: 1.2)
            haloNode.rotation = SCNVector4(0, 0, 1, -Float.pi/2)
            haloNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "sun_halo")
            haloNode.geometry?.firstMaterial?.lightingModel = .constant
            haloNode.geometry?.firstMaterial?.writesToDepthBuffer = false
            haloNode.opacity = 0.8
            node?.addChildNode(haloNode)
        }
    }
    
    private func getPlanetRotation(duration: Double) -> SCNAction {
        let action = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: duration)
        let forever = SCNAction.repeatForever(action)
        return forever
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlanetNode {

    /// Returns a `PlanetNode` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> PlanetNode? {
        if let planetNodeRoot = node as? PlanetNode {
            return planetNodeRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `planetNode`.
        return existingObjectContainingNode(parent)
    }
}

extension Collection where Iterator.Element == Float, IndexDistance == Int {
    /// Return the mean of a list of Floats. Used with `recentVirtualObjectDistances`.
    var average: Float? {
        guard !isEmpty else {
            return nil
        }
        
        let sum = reduce(Float(0)) { current, next -> Float in
            return current + next
        }
        
        return sum / Float(count)
    }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}
