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
    private var nodes = [SCNNode]()
    
    private let lastDistStr = "Last distance: "
    private let totalDistStr = "Total distance: "
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = false
        
        let screenSize: CGRect = UIScreen.main.bounds
        positionUIElements(CGSize(width: screenSize.width, height: screenSize.height))
        
        distanceText.textAlignment = .center
        distanceText.backgroundColor = UIColor.lightText
        distanceText.layer.cornerRadius = 5
        distanceText.layer.borderWidth = 1
        distanceText.layer.borderColor = UIColor.black.cgColor
        distanceText.isUserInteractionEnabled = false
        resetDistanceLabelText()
        view.addSubview(distanceText)
        
        resetButton.backgroundColor = UIColor.lightText
        resetButton.setTitle("Reset ", for: .normal)
        resetButton.addTarget(self, action: #selector(resetButtonAction), for: .touchUpInside)
        resetButton.layer.cornerRadius = 5
        resetButton.layer.borderWidth = 1
        resetButton.layer.borderColor = UIColor.black.cgColor
        view.addSubview(resetButton)
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
                let begin = nodes[i]
                let end = nodes[i+1]
                totalDistance += begin.position.distance(vector: end.position)
                let lineNode = lineBetweenNodes(nodeA: begin, nodeB: end)
                sceneView.scene.rootNode.addChildNode(lineNode)
            }
            distanceText.text = lastDistStr + String(format:"%.2f m", lastDistance) + "\n" +
                totalDistStr + String(format:"%.2f m", totalDistance)
       }
    }
    
    func resetDistanceLabelText() {
        distanceText.text = lastDistStr + "0.0 m\n" + totalDistStr + "0.0 m"
    }
    
    @objc func resetButtonAction(_ sender: UIButton!) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
            node.removeFromParentNode()
        }
        nodes.removeAll()
        resetDistanceLabelText()
    }

    func lineBetweenNodes(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        let positions: [Float32] = [nodeA.position.x, nodeA.position.y, nodeA.position.z, nodeB.position.x, nodeB.position.y, nodeB.position.z]
        let positionData = Data(bytes: positions, count: MemoryLayout<Float32>.size * positions.count)
        let indices: [Int32] = [0, 1]
        let indexData = Data(bytes: indices, count: MemoryLayout<Int32>.size * indices.count)
        
        let source = SCNGeometrySource(
            data: positionData,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: indices.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float32>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<Float32>.size * 3)
        let element = SCNGeometryElement(
            data: indexData,
            primitiveType: SCNGeometryPrimitiveType.line,
            primitiveCount: indices.count,
            bytesPerIndex: MemoryLayout<Int32>.size)
        
        let line = SCNGeometry(sources: [source], elements: [element])
        return SCNNode(geometry: line)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        positionUIElements(size)
    }
    
    func positionUIElements(_ size: CGSize) {
        let screenWidth = size.width
        let screenHeight = size.height
        let margin: CGFloat = 70.0
        let buttonHeight: CGFloat = 50.0
        distanceText.frame = CGRect(x: screenWidth * 0.5 - 100.0, y: screenHeight - margin, width: 200.0, height: buttonHeight)
        resetButton.frame = CGRect(x: screenWidth - margin, y: screenHeight - margin, width: 60.0, height: buttonHeight)
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
