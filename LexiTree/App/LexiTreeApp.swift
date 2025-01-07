import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct LexiTreeApp: App {
    init() {
        print("\n\n")
        print("========================")
        print("🚀 应用程序启动")
        #if os(iOS)
        print("📱 设备名称: \(UIDevice.current.name)")
        #else
        print("💻 设备：Mac")
        #endif
        print("📂 文档目录: \(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)")
        print("📦 Bundle路径: \(Bundle.main.bundlePath)")
        print("========================")
        print("\n")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 