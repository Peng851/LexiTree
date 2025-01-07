import SwiftUI

struct RootListView: View {
    @StateObject private var viewModel = RootListViewModel()
    
    var body: some View {
        List(viewModel.roots) { root in
            NavigationLink(destination: WordListView(root: root)) {
                RootRowView(root: root)
            }
        }
        .navigationTitle("词根列表")
        .task {
            await viewModel.loadRoots()
        }
    }
}

struct RootRowView: View {
    let root: Root
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(root.text)
                .font(.headline)
            HStack {
                Text(root.meaning)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(root.words.count) 个单词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    RootListView()
        .modifier(PreviewNavigationModifier())
} 