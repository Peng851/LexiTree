import SwiftUI

struct StudyView: View {
    @StateObject private var viewModel = StudyViewModel()
    
    var body: some View {
        List {
            if let root = viewModel.currentRoot {
                Section {
                    HStack {
                        Text(root.text)
                            .font(.title2)
                        Text(root.meaning)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("相关单词") {
                    ForEach(viewModel.relatedWords) { word in
                        NavigationLink(destination: WordDetailView(word: word)) {
                            HStack {
                                Text(word.text)
                                Spacer()
                                Text(word.meaning)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("单词")
        .task {
            await viewModel.loadInitialData()
        }
    }
} 