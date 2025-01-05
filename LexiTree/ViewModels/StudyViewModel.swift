import SwiftUI

@MainActor
final class StudyViewModel: ObservableObject {
    @Published private(set) var roots: [Root] = []
    @Published private(set) var currentRoot: Root?
    @Published private(set) var currentExample: ExampleSentence?
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadRandomRoot() async {
        do {
            let allRoots = try await repository.fetchAllRoots()
            if let root = allRoots.randomElement() {
                currentRoot = root
                // 加载该词根的一个随机例句
                if let example = try await repository.fetchExample(forRoot: root.text) {
                    currentExample = example
                }
            }
        } catch {
            print("Error loading root: \(error)")
        }
    }
    
    func loadRoots() async {
        do {
            roots = try await repository.fetchAllRoots()
        } catch {
            print("Error loading roots: \(error)")
        }
    }
}

struct ExampleSentence: Identifiable {
    let id: UUID
    let text: String
    let translation: String
    let wordId: String
}