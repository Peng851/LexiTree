import SwiftUI

struct RootNetworkView: View {
    @StateObject private var viewModel = RootNetworkViewModel()
    let root: Root
    
    var body: some View {
        // 将复杂的表达式拆分成更小的部分
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
        .task {
            await viewModel.loadRelations(for: root)
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

struct RootRelation: Identifiable {
    let id: UUID
    let type: String
    let startPoint: CGPoint
    let endPoint: CGPoint
    
    var midPoint: CGPoint {
        CGPoint(
            x: (startPoint.x + endPoint.x) / 2,
            y: (startPoint.y + endPoint.y) / 2
        )
    }
}

struct RootDetailView: View {
    let root: Root
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RootDetailViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                Section("词根释义") {
                    Text(root.rootDescription)
                        .font(.body)
                }
                
                Section("相关单词") {
                    ForEach(viewModel.words) { word in
                        NavigationLink {
                            WordDetailView(word: word)
                        } label: {
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
        .task {
            await viewModel.loadWords(for: root)
        }
    }
} 