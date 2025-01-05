import SwiftUI

struct RootListView: View {
    @StateObject private var viewModel = RootListViewModel()
    
    var body: some View {
        List(viewModel.roots) { root in
            NavigationLink {
                WordListView(root: root)
            } label: {
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
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(root.text)
                        .font(.headline)
                    Text(root.meaning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(root.words.count)词")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if isExpanded {
                Text(root.rootDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
}

#Preview {
    RootListView()
        .modifier(PreviewNavigationModifier())
} 