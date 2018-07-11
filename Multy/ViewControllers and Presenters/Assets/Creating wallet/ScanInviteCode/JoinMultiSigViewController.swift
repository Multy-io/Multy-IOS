//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import AVFoundation

class JoinMultiSigViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var bottomGradientView: UIView!
    @IBOutlet weak var topGradientView: UIView!
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let presenter = JoinMultiSigPresenter()
    
    let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                              AVMetadataObject.ObjectType.code39,
                              AVMetadataObject.ObjectType.code39Mod43,
                              AVMetadataObject.ObjectType.code93,
                              AVMetadataObject.ObjectType.code128,
                              AVMetadataObject.ObjectType.ean8,
                              AVMetadataObject.ObjectType.ean13,
                              AVMetadataObject.ObjectType.aztec,
                              AVMetadataObject.ObjectType.pdf417,
                              AVMetadataObject.ObjectType.qr,
                              AVMetadataObject.ObjectType.interleaved2of5,
                              AVMetadataObject.ObjectType.itf14,
                              AVMetadataObject.ObjectType.dataMatrix
    ]
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.mainVC = self
        hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            camera()
        }
    }
    
    override func viewDidLayoutSubviews() {
        setupGradients()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupGradients() {
        let colorTop = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.0).cgColor
        let colorBottom = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 100.0).cgColor
        let gradientBottomLayer = CAGradientLayer()
        gradientBottomLayer.colors = [colorTop, colorBottom]
        gradientBottomLayer.locations = [0.3, 1.0]
        gradientBottomLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: bottomGradientView.frame.height)
        bottomGradientView.layer.addSublayer(gradientBottomLayer)
        
        let gradientTopLayer = CAGradientLayer()
        gradientTopLayer.colors = [colorBottom, colorTop]
        gradientTopLayer.locations = [0.0, 0.8]
        gradientTopLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: topGradientView.frame.height)
        topGradientView.layer.addSublayer(gradientTopLayer)
    }
    
    
    func camera() {
        let captureDevice = AVCaptureDevice.devices(for: AVMediaType.video)
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice[0])
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            DispatchQueue.main.async {
                self.videoPreviewLayer?.frame = self.view.layer.bounds
                self.cameraView.layer.addSublayer(self.videoPreviewLayer!)
            }
            
            // Start video capture.
            captureSession?.startRunning()
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
    }
    
    @objc func keyboardWillShow(_ notification : Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let inset : UIEdgeInsets = UIEdgeInsetsMake(64, 0, keyboardSize.height, 0)
            bottomConstraint.constant = inset.bottom + 16
            if screenHeight == heightOfX {
                bottomConstraint.constant = inset.bottom - 19 //def is 35 but it for top of keyboard
            }
            cameraView.alpha = 0.9.
            animateLayout()
        }
    }
    
    @objc func keyboardWillHide() {
        bottomConstraint.constant = 16 // Default
        animateLayout()
    }
    
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    

}
