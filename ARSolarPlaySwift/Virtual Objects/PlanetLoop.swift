//
//  PlanetLoop.swift
//  ARSolarPlaySwift
//
//  Created by 石高扬 on 2017/12/13.
//  Copyright © 2017年 Alex yang. All rights reserved.
//

import Foundation
import SceneKit

class PlanetLoop: SCNNode {
    
    init(planet: PlanetEnum) {
        
        super.init()
        
        self.opacity = 0.4;
        self.geometry = SCNBox(width: 0.55, height: 0, length: 0.55, chamferRadius: 0)
        self.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "saturn_loop")
        //self.geometry?.firstMaterial?.diffuse.mipFilter = .linear;
        self.rotation = SCNVector4Make(0, 0, 1, Float(30.degreesToRadians));
        //self.geometry?.firstMaterial?.lightingModel = .constant;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


