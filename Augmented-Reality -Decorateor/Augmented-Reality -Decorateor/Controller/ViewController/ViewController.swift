//
//  ViewController.swift
//  Augmented-Reality -Decorateor
//
//  Created by Technobrains on 06/12/22.
//

import UIKit
import ARKit
import RealityKit

class ViewController: UIViewController,ARCoachingOverlayViewDelegate {

    //MARK: - IBOutlet
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var itemCollectionView:UICollectionView!
    var selectedNode: SCNNode? = nil
    var modelNode: SCNNode?
    let arrObjectList: [String] = ["plant","chair", "table","cup", "crismasTree", "fruits","cat"]
    
    //MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR tracking is not supported on this device")
            return
        }
        sceneView.delegate = self
        let moveGesture = UIPanGestureRecognizer(target: self,
                                                     action: #selector(moveModel))
        self.sceneView.addGestureRecognizer(moveGesture)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCoachingOverlay()
        setConfigration()
    }
    //Setup AR session configration for ARWorldTraking object.
    private func setConfigration(){
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical,.horizontal]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}
//MARK: - Set AR overlay and implement delegate method user get idea to set plane location.
extension ViewController{
    fileprivate func setCoachingOverlay() {
        let coachingOverlay = ARCoachingOverlayView()
        
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.goal = .horizontalPlane
    }
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // Overlay will show
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        // Overlay did remove
    }
}

//MARK: - Add pan gesture and move selected object on spacific location
extension ViewController{
    
    private func getNode(at position: CGPoint) -> SCNNode? {
        let nnn = self.sceneView.hitTest(position, options: nil).first(where: {
            $0.node !== modelNode
        })?.node
        
        return nnn
    }
    @objc func moveModel(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self.sceneView)
        
        switch gesture.state {
        case .began:
            selectedNode = getNode(at: location)
        case .changed:
            guard let rayCastQuery = self.sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any) else{return}
            guard let result = sceneView.session.raycast(rayCastQuery).first else{return}
            let transform = result.worldTransform
            let newPosition = SIMD3<Float>(transform.columns.3.x,
                                           transform.columns.3.y,
                                           transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
        default:
            selectedNode = nil
        }
    }
}

//MARK: - ARsessionDelegate to modify AR object.
extension ViewController:ARSessionDelegate,ARSCNViewDelegate{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            plane.firstMaterial?.diffuse.contents = UIImage(named: "BackgroundTiles")
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.x, -0.9)
            //rotate the plane anchor 90 degrees
            //  planeNode.eulerAngles.x = -.pi / 2
            //node.addChildNode(planeNode)
        }
        //Add childNodes
        if anchor.name != nil{
            let scPlane = SCNPlane(width: 1, height: 1)
            scPlane.firstMaterial?.diffuse.contents = UIImage(named: anchor.name!)
            let Scnode = SCNNode(geometry: scPlane)
            let position = SCNVector3(SCNVector3Zero.x, SCNVector3Zero.y, 0.1)
            Scnode.position = position
            Scnode.eulerAngles = SCNVector3(0,0,Double.pi/2)//2
            node.addChildNode(Scnode)
        }
        
    }
    //update AR object delegate method
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor,
           let planeNode = node.childNodes.first,
           let plane = planeNode.geometry as? SCNPlane {
            
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)}
    }
    
}

//MARK: - CollectionView delegate
extension ViewController:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrObjectList.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "arobjectlistcell", for: indexPath) as? ARObjectListCell else{
            return UICollectionViewCell()
        }
        cell.imgARObject.image = UIImage(named: arrObjectList[indexPath.row])
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let currentFrame = sceneView.session.currentFrame {
            
            // Create a transform with a translation of 2 meters in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.z = -2
            print(translation)
            let transform = simd_mul(currentFrame.camera.transform, translation)
            
            // Add a new anchor to the session
            let anchor = ARAnchor(name: arrObjectList[indexPath.row], transform: transform)
            sceneView.session.add(anchor: anchor)
        }}
}


