import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var learnedWordsCount = 0
    @Published private(set) var masteredRootsCount = 0
    @Published private(set) var todayLearningMinutes = 0
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadStatistics() async {
        do {
            let words = try await repository.fetchAllWords()
            learnedWordsCount = words.count
            
            let roots = try await repository.fetchAllRoots()
            masteredRootsCount = roots.count
            
            todayLearningMinutes = try await repository.getTodayLearningMinutes()
        } catch {
            print("Error loading statistics: \(error)")
        }
    }
} 