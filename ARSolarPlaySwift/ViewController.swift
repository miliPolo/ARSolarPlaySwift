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

class ViewController: UIViewController{

    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var sceneView: VirtualObjectARView!
    
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// the planetnode is loaded.
    lazy var isObjectVisible = false;
    
    /// the root node of solar system
    lazy var sunNode = initSunNode()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "com.shigy.ARSolarPlaySwift")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSceneView()
    }
    
    func initSceneView() {
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        /// debug options
        //sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin,ARSCNDebugOptions.showFeaturePoints];
        
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Res/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        
        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        addObjectButton.addTarget(self, action: #selector(initPlanetNode), for: UIControlEvents.touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(initPlanetNode))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    @objc func initPlanetNode() {
        
        guard !isObjectVisible else { return }
        
        ///Used to determine whether palnet node is loaded
        isObjectVisible = true
        
        /// planetnode is added, hide the add button
        addObjectButton.isHidden = true

        
        
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
                statusViewController.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
                return
        }
        
        virtualObjectInteraction.selectedObject = sunNode
            sunNode.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.sunNode)
        }
    }
    
    func initSunNode() -> PlanetNode {
        
        let sunNode = PlanetNode(planet: .sun)
        let earthNode = PlanetNode(planet: .earth)
        
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
        
        return sunNode
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
        
    }
    
    // MARK: - Scene content setup
    
    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        
        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }
    
    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        statusViewController.scheduleMessage("FIND A SURFACE TO PLACE AN OBJECT", inSeconds: 7.5, messageType: .planeEstimation)
    }
   
    // MARK: - Focus Square
    
    func updateFocusSquare() {
  
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
    }
    
    /// - Tag: restartExperience
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        
        //reset object state
        isObjectVisible = false
        
        statusViewController.cancelAllScheduledMessages()
        
        /// remove all node from sceneview
        self.sunNode.removeFromParentNode()
        self.sunNode.reset()
        
        //reset addObjectBtn state
        addObjectButton.isHidden = false
        addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
        addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        
        resetTracking()
        
        // Disable restart for a while in order to give the session time to restart.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        //blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            //self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
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
}
