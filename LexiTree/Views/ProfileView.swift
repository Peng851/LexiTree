import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedAccent = "en-US"
    
    var body: some View {
        List {
            Section("学习统计") {
                HStack {
                    Text("已学单词")
                    Spacer()
                    Text("\(viewModel.learnedWordsCount)")
                }
                HStack {
                    Text("已掌握词根")
                    Spacer()
                    Text("\(viewModel.masteredRootsCount)")
                }
                HStack {
                    Text("今日学习时长")
                    Spacer()
                    Text("\(viewModel.todayLearningMinutes) 分钟")
                }
            }
            
            // 暂时移除分享功能
            // Section("分享") {
            //     ShareSheet()
            // }
        }
        .navigationTitle("我的")
        .task {
            await viewModel.loadStatistics()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
} 