//
//  ViewController.swift
//  my-measure
//
//  Created by Juha-Pekka Arimaa on 01/09/2017.
//  Copyright © 2017 justus. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var distanceText = UITextView()
    private let resetButton = UIButton()
    private var nodes: [SCNNode] = []
    
    private let lastDistStr = "Last distance: "
    private let totalDistStr = "Total distance: "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = false
        
        distanceText.textAlignment = .center
        distanceText.backgroundColor = UIColor.lightText
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        distanceText.frame = CGRect(x: screenWidth * 0.5 - 100, y: screenHeight - 70, width: 200, height: 50)
        distanceText.layer.cornerRadius = 5
        distanceText.layer.borderWidth = 1
        distanceText.layer.borderColor = UIColor.black.cgColor
        distanceText.isUserInteractionEnabled = false
        view.addSubview(distanceText)
        resetDistanceLabel()
        
        resetButton.frame = CGRect(x: screenWidth - 70, y: screenHeight - 70, width: 60, height: 50)
        resetButton.backgroundColor = UIColor.lightText
        resetButton.setTitle("Reset ", for: .normal)
        resetButton.addTarget(self, action: #selector(resetButtonAction), for: .touchUpInside)
        resetButton.layer.cornerRadius = 5
        resetButton.layer.borderWidth = 1
        resetButton.layer.borderColor = UIColor.black.cgColor
        self.view.addSubview(resetButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitFeature = results.last else {
            return
        }
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41, hitTransform.m42, hitTransform.m43)
        
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        sphere.firstMaterial?.lightingModel = .constant
        sphere.firstMaterial?.isDoubleSided = true
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = hitPosition
        sceneView.scene.rootNode.addChildNode(sphereNode)
        nodes.append(sphereNode)
        
        if nodes.count > 1 {
            let lastNode = nodes[nodes.count-1]
            let secondLastNode = nodes[nodes.count-2]
            let lastDistance = lastNode.position.distance(vector: secondLastNode.position)
            var totalDistance: Float = 0.0
            for i in 0..<nodes.count-1 {
                totalDistance += nodes[i].position.distance(vector: nodes[i+1].position)
            }
            distanceText.text = lastDistStr + String(format:"%.2f m", lastDistance) + "\n" +
                totalDistStr + String(format:"%.2f m", totalDistance)
        }
    }
    
    func resetDistanceLabel() {
        distanceText.text = lastDistStr + "0.0 m\n" + totalDistStr + "0.0 m"
    }
    
    @objc func resetButtonAction(_ sender: UIButton!) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
        nodes.removeAll()
        resetDistanceLabel()
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
