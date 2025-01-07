import SwiftUI

struct RootNetworkView: View {
    @StateObject private var viewModel = RootNetworkViewModel()
    let root: Root
    
    var body: some View {
        // 使用NavigationView替代NavigationStack
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 词根信息部分
                    rootInfoSection
                    
                    // 关系列表部分
                    relationsList
                }
                .padding()
            }
            .navigationTitle("词根关系")
            .onAppear {
                Task {
                    await viewModel.loadRelations(for: root)
                }
            }
        }
    }
    
    // 词根信息部分
    private var rootInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(root.text)
                .font(.title)
            Text(root.meaning)
                .foregroundColor(.secondary)
            Text(root.rootDescription)
                .font(.body)
        }
    }
    
    // 关系列表部分
    private var relationsList: some View {
        ForEach(viewModel.relations, id: \.root2.id) { relation in
            NavigationLink(destination: RootDetailView(root: relation.root2)) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(relation.root2.text)
                        .font(.headline)
                    Text(relation.relationType)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text(relation.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }
}

struct RootDetailView: View {
    let root: Root
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RootDetailViewModel()
    
    var body: some View {
        // 使用NavigationView替代NavigationStack
        NavigationView {
            List {
                Section("词根释义") {
                    Text(root.rootDescription)
                        .font(.body)
                }
                
                Section("相关单词") {
                    ForEach(viewModel.words) { word in
                        NavigationLink(destination: WordDetailView(word: word)) {
                            WordRowView(word: word)
                        }
                    }
                }
            }
            .navigationTitle(root.text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadWords(for: root)
            }
        }
    }
}

struct RootNodeView: View {
    let root: Root
    let isCenter: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(root.text)
                .font(.system(size: isCenter ? 24 : 18, weight: .bold))
                .foregroundColor(isCenter ? .red : .primary)
            Text(root.meaning)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: isCenter ? 4 : 2)
    }
}

#Preview {
    RootNetworkView(root: PreviewData.root)
} 