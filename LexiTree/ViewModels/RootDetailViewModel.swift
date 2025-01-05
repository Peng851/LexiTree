import SwiftUI

@MainActor
final class RootDetailViewModel: ObservableObject {
    @Published private(set) var words: [Word] = []
    @Published private(set) var relations: [RootRelationData] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadWords(for root: Root) async {
        do {
            words = try await repository.fetchWords(forRoot: root.text)
            relations = try await repository.fetchRootRelations(for: root)
        } catch {
            print("Error loading words: \(error)")
        }
    }
} 