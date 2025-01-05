import SwiftUI

struct StudyView: View {
    @StateObject private var viewModel = StudyViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // 词根网络图
                    if let root = viewModel.currentRoot {
                        RootNetworkView(root: root)
                            .frame(height: geometry.size.height * 0.6)
                    }
                    
                    // 例句展示
                    if let example = viewModel.currentExample {
                        ExampleSentenceView(example: example)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("词根学习")
        .task {
            await viewModel.loadRandomRoot()
        }
    }
}

struct ExampleSentenceView: View {
    let example: ExampleSentence
    @State private var showTranslation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 英文例句
            Text(example.text)
                .font(.body)
            
            // 中文翻译（点击显示）
            Button {
                withAnimation {
                    showTranslation.toggle()
                }
            } label: {
                if showTranslation {
                    Text(example.translation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                } else {
                    Text("点击显示翻译")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
} 