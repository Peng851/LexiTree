import SwiftUI

struct ShareButton: View {
    let content: String
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ShareLink(item: content) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        } else {
            Button {
                shareContent()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func shareContent() {
        // 获取当前视图的UIView用于展示分享sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        ShareService.shared.shareContent(
            content: content,
            from: rootViewController.view
        )
    }
} 