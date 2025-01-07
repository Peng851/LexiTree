import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                WordListView()
            }
            .tabItem {
                Label("单词", systemImage: "book")
            }
            .onAppear {
                print("🔍 单词页面出现")
                // 打印文档目录路径
                print("📂 文档目录：\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].path)")
                // 打印 Bundle 路径
                print("📦 Bundle 路径：\(Bundle.main.bundlePath)")
            }
            
            NavigationView {
                StudyView()
            }
            .tabItem {
                Label("学习", systemImage: "brain.head.profile")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
        }
    }
}

#Preview {
    ContentView()
} 