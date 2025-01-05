import SwiftUI

@MainActor
final class RootListViewModel: ObservableObject {
    @Published private(set) var roots: [Root] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadRoots() async {
        do {
            roots = try await repository.fetchAllRoots()
        } catch {
            print("Error loading roots: \(error)")
        }
    }
} 