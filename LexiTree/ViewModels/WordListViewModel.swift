import SwiftUI

@MainActor
final class WordListViewModel: ObservableObject {
    @Published private(set) var words: [Word] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadWords(forRoot root: String) async {
        do {
            words = try await repository.fetchWords(forRoot: root)
        } catch {
            print("Error loading words: \(error)")
        }
    }
    
    func loadAllWords() async {
        print("🔄 开始加载单词...")
        do {
            words = try await repository.fetchAllWords()
            print("✅ 成功加载 \(words.count) 个单词")
            words.forEach { print("📝 \($0.text)") }
        } catch {
            print("❌ 加载失败: \(error)")
        }
    }
} 