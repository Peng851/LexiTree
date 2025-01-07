import SwiftUI

@MainActor
final class WordListViewModel: ObservableObject {
    @Published private(set) var words: [Word] = []
    @Published private(set) var filteredWords: [Word] = []
    private let repository: WordRepository
    
    init() {
        self.repository = SQLiteWordRepository(db: DataManager.shared)
    }
    
    func loadWords(forRoot root: Root) async {
        do {
            words = try await repository.fetchWords(forRoot: root.text)
            filterWords(searchText: "")
        } catch {
            print("Error loading words: \(error)")
        }
    }
    
    func loadAllWords() async {
        print("🔄 开始加载单词...")
        do {
            words = try await repository.fetchAllWords()
            filterWords(searchText: "")
            print("✅ 成功加载 \(words.count) 个单词")
            words.forEach { print("📝 \($0.text)") }
        } catch {
            print("❌ 加载失败: \(error)")
        }
    }
    
    func filterWords(searchText: String) {
        if searchText.isEmpty {
            filteredWords = words
        } else {
            filteredWords = words.filter { word in
                word.text.localizedCaseInsensitiveContains(searchText) ||
                word.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
} 