import SwiftUI

struct WordListView: View {
    @StateObject private var viewModel: WordListViewModel
    let root: Root?
    
    init(root: Root? = nil) {
        self.root = root
        _viewModel = StateObject(wrappedValue: WordListViewModel())
    }
    
    var body: some View {
        List {
            ForEach(viewModel.words) { word in
                NavigationLink(value: word) {
                    WordRowView(word: word)
                }
            }
        }
        .navigationTitle(root?.text ?? "单词列表")
        .navigationDestination(for: Word.self) { word in
            WordDetailView(word: word)
        }
        .task {
            await viewModel.loadAllWords()
        }
    }
}

struct WordRowView: View {
    let word: Word
    
    var body: some View {
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
            .font(.headline)
            
            Text(word.meaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WordListView(root: PreviewData.root)
        .modifier(PreviewNavigationModifier())
} 