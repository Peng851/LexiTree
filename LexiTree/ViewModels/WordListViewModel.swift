import SwiftUI

@MainActor
final class WordListViewModel: ObservableObject {
    @Published private(set) var words: [Word] = []
    @Published private(set) var filteredWords: [Word] = []
    private let repository: WordRepository
    private let dataManager: DataManager
    
    init() {
        self.dataManager = DataManager.shared
        self.repository = SQLiteWordRepository(db: dataManager)
    }
    
    func loadAllWords() async {
        do {
            // 确保数据库已初始化
            try await dataManager.initializeDatabase()
            
            print("🔄 开始加载所有单词...")
            words = try await repository.fetchAllWords()
            filteredWords = words
            print("✅ 成功加载 \(words.count) 个单词")
        } catch {
            print("❌ 加载失败: \(error)")
        }
    }
    
    func loadWords(forRoot root: Root) async {
        do {
            words = try await repository.fetchWords(forRoot: root.text)
            filterWords(searchText: "")
        } catch {
            print("Error loading words: \(error)")
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