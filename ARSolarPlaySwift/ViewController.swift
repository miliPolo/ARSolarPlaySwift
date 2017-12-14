//
//  ViewController.swift
//  ARSolarPlaySwift
//
//  Created by 石高扬 on 2017/10/28.
//  Copyright © 2017年 Alex yang. All rights reserved.
//

let cen_dis = 0.5

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSceneView()
    }
    
    func initSceneView() {
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,ARSCNDebugOptions.showFeaturePoints];
        
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func initPlanetNode() {
        

        let earthNode = PlanetNode(planet: .earth)
        let sunNode = PlanetNode(planet: .sun)
        
        sunNode.addPlanet(planet: .mercury)
        sunNode.addPlanet(planet: .venus)
        sunNode.addPlanet(planet: .mars)
        sunNode.addPlanet(planet: .jupiter)
        sunNode.addPlanet(planet: .saturn)
        sunNode.addPlanet(planet: .uranus)
        sunNode.addPlanet(planet: .neptune)
        sunNode.addPlanet(planet: .pluto)
        
        earthNode.addPlanet(planet: .moon)
        sunNode.addPlanet(planetNode: earthNode)
        
        sunNode.position = SCNVector3(0, -0.5, -2)
        
        sceneView.scene.rootNode.addChildNode(sunNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initPlanetNode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
