import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WordDetailView: View {
    let word: Word
    @State private var example: ExampleSentence?
    
    var body: some View {
        List {
            Section("词义") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let prefix = word.prefix {
                            Text(prefix)
                                .foregroundColor(.blue)
                        }
                        Text(word.root)
                            .foregroundColor(.red)
                        if let suffix = word.suffix {
                            Text(suffix)
                                .foregroundColor(.green)
                        }
                    }
                    .font(.title2)
                    
                    Text(word.pronunciation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(word.meaning)
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
            
            if let example = example {
                Section("例句") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(example.text)
                            .font(.body)
                        Text(example.translation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                ShareButton(content: "\(word.text): \(word.meaning)")
            }
        }
        .navigationTitle(word.text)
        .task {
            do {
                example = try await DataManager.shared.fetchExample(forWord: word.id)
            } catch {
                print("❌ 加载例句失败: \(error)")
            }
        }
    }
}

// 修改后的 ShareSheet 实现
struct ShareSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ShareLink(item: text) {
                Label("分享", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        } else {
            Button(action: {
                shareContent()
            }) {
                Label("分享", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    
    private func shareContent() {
        #if canImport(UIKit)
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                dismiss()
            }
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}

#Preview {
    WordDetailView(word: PreviewData.words[0])
        .modifier(PreviewNavigationModifier())
} 