//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import AVFoundation

private typealias LocalizeDelegate = JoinMultiSigViewController
private typealias TextViewDelegate = JoinMultiSigViewController


class JoinMultiSigViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AnalyticsProtocol {

    @IBOutlet weak var bottomGradientView: UIView!
    @IBOutlet weak var topGradientView: UIView!
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var placeHolderLbl: UILabel!
    @IBOutlet weak var textView: UITextView!
    
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
    var isGradientOn = false
    
    var qrDelegate: QrDataProtocol?
    var blockchainTransferDelegate: BlockchainTransferProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.mainVC = self
        hideKeyboardWhenTappedAround()
        
        sendAnalyticsEvent(screenName: screenJoinToMs, eventName: screenJoinToMs)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
//            self.sendAnalyticsEvent(screenName: screenQR, eventName: scanGotPermossion)
            camera()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                guard self != nil else {
                    return
                }
                
                if granted {
//                    self.sendAnalyticsEvent(screenName: screenQR, eventName: scanGotPermossion)
                    self!.camera()
                } else {
//                    self.sendAnalyticsEvent(screenName: screenQR, eventName: scanDeniedPermission)
                    self!.alertForGetNewPermission()
                }
            })
        }
    }
    
    override func viewDidLayoutSubviews() {
        if isGradientOn == false {
            setupGradients()
            textView.setContentOffset(CGPoint.zero, animated: false)
        }
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
        
        isGradientOn = true
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
    
    func alertForGetNewPermission() {
        let alert = UIAlertController(title: localize(string: Constants.warningString), message: localize(string: Constants.goToSettingsString), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
            let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
            if UIApplication.shared.canOpenURL(settingsUrl!) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(settingsUrl!, options: [:], completionHandler: { (success) in
                        self.cancelAction(Any.self)
                    })
                } else {
                    UIApplication.shared.openURL(settingsUrl!)
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(_ notification : Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let inset : UIEdgeInsets = UIEdgeInsetsMake(64, 0, keyboardSize.height, 0)
            bottomConstraint.constant = inset.bottom + 16
            if screenHeight == heightOfX {
                bottomConstraint.constant = inset.bottom - 19 //def is 35 but it for top of keyboard
            }
            
            cameraView.alpha = 0.2
            animateLayout()
        }
    }
    
    @objc func keyboardWillHide() {
        cameraView.alpha = 1.0
        bottomConstraint.constant = 16 // Default
        animateLayout()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession?.stopRunning()
        
        if let metatdataObject = metadataObjects.first {
            guard let readableObject = metatdataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            if stringValue.contains("invite code:") {
                sendAnalyticsEvent(screenName: screenJoinToMs, eventName: inviteQrDetected)
                let array = stringValue.components(separatedBy: CharacterSet(charactersIn: ":"))
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                pasteInTextView(string: array[1])
            } else {
                captureSession?.startRunning()
                presentAlert(with: localize(string: Constants.inviteCodeNotFoundString))
            }
//            self.navigationController?.popViewController(animated: true)
//            self.qrDelegate?.qrData(string: stringValue)
        }
    }
    
    
    func pasteInTextView(string: String) {
        textView.text = string.replacingOccurrences(of: " ", with: "")
        placeHolderLbl.isHidden = true
        presenter.validate(inviteCode: textView.text)
    }
}

extension TextViewDelegate: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeHolderLbl.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            placeHolderLbl.isHidden = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            presenter.validate(inviteCode: textView.text)
            return false
        }
        
        if text.count >= inviteCodeCount {
            pasteInTextView(string: text)
            dismissKeyboard()
//            presenter.validate(inviteCode: textView.text)
            return false
        }
        
        if text == " " {        //check for disable space
            return false
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count == inviteCodeCount {
            sendAnalyticsEvent(screenName: screenJoinToMs, eventName: pasteQr)
            presenter.validate(inviteCode: textView.text)
            dismissKeyboard()
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
