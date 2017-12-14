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
    
    let planetType:PlanetEnum
    var node:SCNNode!
    
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
        
        //addLight as sun
        self.addLight(planet: planet)
        //addLoop as saturn
        self.addPlanetLoop(planet: planet)
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
            
            //add sun halo
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

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}
