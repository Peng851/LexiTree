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
            var loadedRoots = try await repository.fetchAllRoots()
            
            for i in loadedRoots.indices {
                loadedRoots[i].words = try await repository.fetchWords(forRoot: loadedRoots[i].text)
            }
            
            roots = loadedRoots
        } catch {
            print("Error loading roots: \(error)")
        }
    }
} 