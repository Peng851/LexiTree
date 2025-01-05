import SwiftUI

@MainActor
final class RootNetworkViewModel: ObservableObject {
    @Published private(set) var relations: [RootRelationData] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadRelations(for root: Root) async {
        do {
            relations = try await repository.fetchRootRelations(for: root)
        } catch {
            print("Error loading relations: \(error)")
        }
    }
}

// 数据模型
struct RootRelationData {
    let root1: Root
    let root2: Root
    let relationType: String
    let description: String
} 