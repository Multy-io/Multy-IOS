//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import CryptoSwift

class InviteCodeViewController: UIViewController {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var qrImgView: UIImageView!
    @IBOutlet weak var shareCodeLbl: UILabel!
    
    
    let presenter = InviteCodePresenter()
    var qrcodeImage: CIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.mainVC = self
        setupUI()
    }

    func setupUI() {
        shareCodeLbl.text = presenter.inviteCode
        shadowView.setShadow(with: #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.3))
        makeQRCode()
    }
    
    
    @IBAction func shareAction(_ sender: Any) {
        let sharedText = "Invite code for MultiSig Wallet in Multy\nPlease join:\n" + shareCodeLbl.text!
        let objectsToShare = [sharedText] as [String]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
        activityVC.completionWithItemsHandler = {(activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                // User canceled
                return
            } else {
                if let appName = activityType?.rawValue {
//                    self.sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(self.wallet!.chain)", eventName: "\(shareToAppWithChainTap)\(self.wallet!.chain)_\(appName)")
                }
            }
        }
        activityVC.setPresentedShareDialogToDelegate()
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: QRCode Activity
    func makeQRCode() {
        let data = ("invite code: " + shareCodeLbl.text!).data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("Q", forKey: "inputCorrectionLevel")
        
        qrcodeImage = filter?.outputImage
        displayQRCodeImage()
    }
    
    func displayQRCodeImage() {
        let scaleX = qrImgView.frame.size.width / qrcodeImage.extent.size.width
        let scaleY = qrImgView.frame.size.height / qrcodeImage.extent.size.height
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        qrImgView.image = self.convert(cmage: transformedImage)
    }
    
    func convert(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        
        return image
    }
    //
}
