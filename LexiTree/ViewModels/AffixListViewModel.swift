import Foundation

@MainActor
final class AffixListViewModel: ObservableObject {
    @Published private(set) var affixes: [Affix] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadAffixes() async {
        do {
            affixes = try await repository.fetchAffixes(ofType: nil)
        } catch {
            print("Error loading affixes: \(error)")
        }
    }
} 