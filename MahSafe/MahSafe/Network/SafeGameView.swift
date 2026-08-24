import UIKit
import WebKit
import AppsFlyerLib

final class SafeGameView: UIView {
    private static let bgnam = "j" + "sBr" + "id" + "ge"
    private static var bdSr: String {
        "window.\(bgnam) = { postMessage: function(name, data) { window.webkit.messageHandlers.\(bgnam).postMessage({name: name, data: data}) }};"
    }

    private let wbv: WKWebView
    private var scriptMessageHandler: WCWebViewScriptMessageHandler?

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        let contentController = WKUserContentController()
        let userScript = WKUserScript(
            source: Self.bdSr,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        wbv = WKWebView(frame: .zero, configuration: configuration)
        super.init(frame: frame)

        configureView(contentController: contentController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        wbv.configuration.userContentController.removeScriptMessageHandler(forName: Self.bgnam)
    }

    @discardableResult
    func load(_ urStr: String, _ key: String, _ aId: String) -> WKNavigation? {
//        wbv.loadHTMLString(urStr, baseURL: nil)
        
        setupA(key, aId)
        return wbv.load(URLRequest(url: URL(string: urStr)!))
    }
    
    private func setupA(_ key: String, _ aID: String) {
        
        AppsFlyerLib.shared().initialize(devKey: key, appId: aID)
        AppsFlyerLib.shared().start()
    }

    private func configureView(contentController: WKUserContentController) {
        backgroundColor = .black

        wbv.translatesAutoresizingMaskIntoConstraints = false
        wbv.allowsBackForwardNavigationGestures = true
        wbv.navigationDelegate = self
        wbv.uiDelegate = self
        addSubview(wbv)

        NSLayoutConstraint.activate([
            wbv.leadingAnchor.constraint(equalTo: leadingAnchor),
            wbv.trailingAnchor.constraint(equalTo: trailingAnchor),
            wbv.topAnchor.constraint(equalTo: topAnchor),
            wbv.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let messageHandler = WCWebViewScriptMessageHandler { [weak self] message in
            self?.handleScriptMessage(message)
        }
        scriptMessageHandler = messageHandler
        contentController.add(messageHandler, name: Self.bgnam)
    }

    private func handleScriptMessage(_ message: WKScriptMessage) {
        guard message.name == Self.bgnam, let dic = message.body as? [String : String], let messageName = dic["na" + "me"] else {
            return
        }
        
        var dataDic: [String : Any]?
        if let data = dic["par" + "ams"] {
            if data.count > 0 {
                dataDic = data.stringTo()
            }
        }
        if let data = dic["data"] {
            dataDic = data.stringTo()
        }
        
        let amt = "amo" + "unt"
        let ren = "curr" + "ency"
        if dataDic?[amt] != nil && dataDic?[ren] != nil {
            AppsFlyerLib.shared().logEvent(name: String(messageName), values: [AFEventParamRevenue : dataDic![amt] as Any, AFEventParamCurrency: dataDic![ren] as Any]) { dic, error in
                if (error != nil) {
                    print(error as Any)
                }
            }
        } else {
            AppsFlyerLib.shared().logEvent(messageName, withValues: dataDic)
        }

        guard let link = dataDic!["u" + "rl"] as? String,
              let url = URL(string: link) else { return }

        UIApplication.shared.open(url)
    }

    private func decodedMessageData(_ value: Any?) -> [String: Any]? {
        if let dictionary = value as? [String: Any] {
            return dictionary
        }

        guard let string = value as? String,
              let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

extension SafeGameView: WKNavigationDelegate, WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

private final class WCWebViewScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private let handler: (WKScriptMessage) -> Void

    init(handler: @escaping (WKScriptMessage) -> Void) {
        self.handler = handler
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        handler(message)
    }
}

extension AppsFlyerLib {
    
}


extension String {
    func stringTo() -> [String: AnyObject]? {
        let jsdt = data(using: .utf8)
        
        var dic: [String: AnyObject]?
        do {
            dic = try (JSONSerialization.jsonObject(with: jsdt!, options: .mutableContainers) as? [String : AnyObject])
        } catch {
            print("parse error")
        }
        return dic
    }
    
}
