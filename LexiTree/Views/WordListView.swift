import SwiftUI

struct WordListView: View {
    @StateObject private var viewModel: WordListViewModel
    @State private var searchText = ""
    let root: Root?
    
    init(root: Root? = nil) {
        self.root = root
        _viewModel = StateObject(wrappedValue: WordListViewModel())
    }
    
    var body: some View {
        List {
            ForEach(viewModel.filteredWords) { word in
                NavigationLink(destination: WordDetailView(word: word)) {
                    WordRowView(word: word)
                }
            }
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) { newValue in
            viewModel.filterWords(searchText: newValue)
        }
        .navigationTitle(root?.text ?? "单词列表")
        .task {
            if let root = root {
                await viewModel.loadWords(forRoot: root)
            } else {
                await viewModel.loadAllWords()
            }
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
    NavigationView {
        WordListView(root: PreviewData.root)
    }
} 