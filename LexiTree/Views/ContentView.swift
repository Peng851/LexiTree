import SwiftUI

struct ContentView: View {
    @State private var isInitialized = false
    
    var body: some View {
        TabView {
            NavigationView {
                StudyView()
            }
            .tabItem {
                Label("单词", systemImage: "book")
            }
            
            NavigationView {
                WordListView()
            }
            .tabItem {
                Label("词库", systemImage: "books.vertical")
            }
            
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
        }
        .task {
            if !isInitialized {
                do {
                    try await DataManager.shared.initializeDatabase()
                    isInitialized = true
                } catch {
                    print("❌ 数据库初始化失败: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
} 