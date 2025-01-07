import SwiftUI
import UIKit

class ShareService {
    static let shared = ShareService()
    
    func shareContent(content: String, from view: UIView) {
        if #available(iOS 16.0, *) {
            // 使用 ShareLink (在SwiftUI视图中处理)
        } else {
            // iOS 15 使用 UIActivityViewController
            let activityVC = UIActivityViewController(
                activityItems: [content],
                applicationActivities: nil
            )
            
            // 获取当前window的rootViewController来展示分享sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                activityVC.popoverPresentationController?.sourceView = view
                rootViewController.present(activityVC, animated: true)
            }
        }
    }
} 