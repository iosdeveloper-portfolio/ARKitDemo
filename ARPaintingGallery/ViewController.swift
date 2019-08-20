
import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var galleryScene : SCNScene?
    var galleryNode : SCNNode?
    var rotateLeftButton : UIButton?
    var rotateRightButton : UIButton?
    var reloadButton : UIButton?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
        // Create a new scene
        galleryScene = SCNScene(named: "art.scnassets/Gallery/export.dae")
        
        let node = SCNNode()
        let nodeArray = galleryScene?.rootNode.childNodes
        
        for childNode in nodeArray! {
            node.addChildNode(childNode as SCNNode)
        }
        
        galleryNode = node
        galleryScene?.rootNode.addChildNode(node)
        addTapGestureToSceneView()
        
        rotateLeftButton = UIButton(frame: CGRect(x: self.sceneView.frame.width - 50, y: self.sceneView.frame.height - 50, width: 40 , height: 40))
        rotateLeftButton?.addTarget(self, action: #selector(rotateLeft(sender:)), for: [.touchUpInside])
        self.view .addSubview(rotateLeftButton!)
        rotateLeftButton?.isHidden = true
        rotateLeftButton?.setImage(#imageLiteral(resourceName: "left-arrow-120"), for: .normal)
        
        rotateRightButton = UIButton(frame: CGRect(x: 10, y: self.sceneView.frame.height - 50, width: 40 , height: 40))
        rotateRightButton?.addTarget(self, action: #selector(rotateRight(sender:)), for: [.touchUpInside])
        self.view .addSubview(rotateRightButton!)
        rotateRightButton?.isHidden = true
        rotateRightButton?.setImage(#imageLiteral(resourceName: "right-arrow-120"), for: .normal)
        
        reloadButton = UIButton(frame: CGRect(x: self.sceneView.frame.width - 50, y: 30, width: 40 , height: 40))
        reloadButton?.addTarget(self, action: #selector(reload(sender:)), for: [.touchUpInside])
        self.view .addSubview(reloadButton!)
        reloadButton?.isHidden = true
        reloadButton?.setImage(#imageLiteral(resourceName: "refresh-80"), for: .normal)
    }
   
    @objc func rotateLeft(sender: Any){
        let action = SCNAction.rotateTo(x: CGFloat(galleryNode!.eulerAngles.x), y: CGFloat(galleryNode!.eulerAngles.y), z: CGFloat(galleryNode!.eulerAngles.z) - CGFloat(0.1), duration: 0.1)
        galleryNode?.runAction(action)
    }
    
    @objc func rotateRight(sender: Any){
        let action = SCNAction.rotateTo(x: CGFloat(galleryNode!.eulerAngles.x), y: CGFloat(galleryNode!.eulerAngles.y), z: CGFloat(galleryNode!.eulerAngles.z) + CGFloat(0.1), duration: 0.1)
        galleryNode?.runAction(action)
    }
    
    @objc func reload(sender: Any){
        galleryNode?.removeFromParentNode()
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        sceneView.session.run(configuration, options: .removeExistingAnchors)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addFrameToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        reloadButton?.isHidden = true
        rotateRightButton?.isHidden = true
        rotateLeftButton?.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:-  gesture recognizers
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addFrameToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(resize(recognizer:)))
        sceneView.addGestureRecognizer(pinchGesture)
    }
    
    @objc func resize(recognizer: UIPinchGestureRecognizer){
        let oldPosition = galleryNode?.position
        let action = SCNAction.scale(by: recognizer.scale, duration: 0.1)
        galleryNode?.runAction(action)
        recognizer.scale = 1
        galleryNode?.position = oldPosition!
    }
    
    @objc func addFrameToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {

        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, options: [SCNHitTestOption.categoryBitMask : 100])
        
        guard let hitResult = hitTestResults.first else {
            return
        }
        
        let translation = hitResult.localCoordinates
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        galleryNode?.pivot = SCNMatrix4MakeTranslation(0, -1.01 ,0)
        galleryNode?.position = SCNVector3(x,y,z)
        galleryNode?.scale = SCNVector3(1.5,1.5,1.5)
        
        galleryNode?.eulerAngles.x = .pi/2
        
        hitResult.node.addChildNode(galleryNode!)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.debugOptions = []
        sceneView.session.run(configuration)
        
        sceneView.removeGestureRecognizer(recognizer)
        rotateRightButton?.isHidden = false
        rotateLeftButton?.isHidden = false
        reloadButton?.isHidden = false
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let plane = SCNPlane(width: 10, height: 10)
        
        plane.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.3)
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        planeNode.categoryBitMask = 100
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let _ = planeNode.geometry as? SCNPlane
            else { return }
        
        _ = CGFloat(planeAnchor.extent.x)
        _ = CGFloat(planeAnchor.extent.z)
        
        _ = CGFloat(planeAnchor.center.x)
        _ = CGFloat(planeAnchor.center.y)
        _ = CGFloat(planeAnchor.center.z)
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
    
    public var eulerAngles: SCNVector3 {
        get {
            let qw = sqrt(1 + self.columns.0.x + self.columns.1.y + self.columns.2.z) / 2.0
            let qx = (self.columns.2.y - self.columns.1.z) / (qw * 4.0)
            let qy = (self.columns.0.z - self.columns.2.x) / (qw * 4.0)
            let qz = (self.columns.1.x - self.columns.0.y) / (qw * 4.0)
            
            // roll (x-axis rotation)
            let sinr = +2.0 * (qw * qx + qy * qz)
            let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
            let roll = atan2(sinr, cosr)
            
            // pitch (y-axis rotation)
            let sinp = +2.0 * (qw * qy - qz * qx)
            var pitch: Float
            if fabs(sinp) >= 1 {
                pitch = copysign(Float.pi / 2, sinp)
            } else {
                pitch = asin(sinp)
            }
            
            // yaw (z-axis rotation)
            let siny = +2.0 * (qw * qz + qx * qy)
            let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
            let yaw = atan2(siny, cosy)
            
            return SCNVector3(roll, pitch, yaw)
        }
    }
}

