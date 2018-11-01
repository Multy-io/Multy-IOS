//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit
import BigInt
//import TrustKeystore
import RealmSwift
//import URLNavigator
import WebKit
import Branch

protocol BrowserCoordinatorDelegate: class {
    func didUpdateHistory(coordinator: BrowserCoordinator)
    func didLoadUrl(url: String)
}

final class BrowserCoordinator: NSObject {
    let wallet: UserWalletRLM
    let urlString: String

    lazy var browserViewController: BrowserViewController = {
        let controller = BrowserViewController(wallet: wallet, urlString: urlString)
        controller.delegate = self
        print("\n\ncontroller.delegate = self: \(self)\n\nbrowserViewController: \(controller)")
        controller.webView.uiDelegate = self
        return controller
    }()

    weak var delegate: BrowserCoordinatorDelegate?

    init(wallet: UserWalletRLM, urlString: String) {
        self.wallet = wallet
        self.urlString = urlString
    }

    func start() {
        browserViewController.goHome()
    }

    func openURL(_ url: URL) {
        browserViewController.goTo(url: url)
    }
}

extension BrowserCoordinator: BrowserViewControllerDelegate {
    func runAction(action: BrowserAction) {
        switch action {
        case .navigationAction(let navAction):
            switch navAction {
            case .home:
                browserViewController.goHome()
            case .enter(let string):
                openURL(URL(string: string) ?? URL(string: "http://google.com")!)
                browserViewController.webView.goBack()
            case .goBack:
                browserViewController.webView.goBack()
            default: break
            }
        }
    }

    func didVisitURL(url: URL, title: String) {
        delegate?.didLoadUrl(url: url.absoluteString)
    }
}

extension BrowserCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            browserViewController.webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        if isDebug {
            print("runJavaScriptAlertPanelWithMessage:" + message)
        }
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("runJavaScriptConfirmPanelWithMessage:" + message)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("runJavaScriptTextInputPanelWithPrompt:" + prompt)
    }
    
    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        print(elementInfo.linkURL)
        
        return true
    }
}
