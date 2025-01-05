import Foundation

@MainActor
protocol WordRepository {
    func fetchWords(forRoot root: String) async throws -> [Word]
    func saveWord(_ word: Word) async throws
    func fetchRoot(byId id: UUID) async throws -> Root?
    func fetchRoot(byText text: String) async throws -> Root?
    func fetchAllRoots() async throws -> [Root]
    func fetchAffixes(ofType type: AffixType?) async throws -> [Affix]
    func fetchAllWords() async throws -> [Word]
    func fetchRootRelations(for root: Root) async throws -> [RootRelationData]
    func fetchExample(forRoot root: String) async throws -> ExampleSentence?
    func getTodayLearningMinutes() async throws -> Int
}

@MainActor
final class SQLiteWordRepository: WordRepository {
    private let db: DataManager
    
    init(db: DataManager) {
        self.db = db
    }
    
    func fetchAllRoots() async throws -> [Root] {
        try await db.getAllRoots()
    }
    
    func fetchWords(forRoot root: String) async throws -> [Word] {
        try await db.getWords(forRoot: root)
    }
    
    func saveWord(_ word: Word) async throws {
        try await db.saveWord(word)
    }
    
    func fetchRoot(byId id: UUID) async throws -> Root? {
        // TODO: 实现
        return nil
    }
    
    func fetchRoot(byText text: String) async throws -> Root? {
        try await db.getRoot(byText: text)
    }
    
    func fetchAffixes(ofType type: AffixType?) async throws -> [Affix] {
        try await db.getAffixes(ofType: type)
    }
    
    func fetchAllWords() async throws -> [Word] {
        print("📚 Repository: 开始从数据库获取单词")
        let words = try await db.getAllWords()
        print("✅ Repository: 获取到 \(words.count) 个单词")
        return words
    }
    
    func fetchRootRelations(for root: Root) async throws -> [RootRelationData] {
        try await db.getRootRelations(for: root)
    }
    
    func fetchExample(forRoot root: String) async throws -> ExampleSentence? {
        try await db.getExample(forRoot: root)
    }
    
    func getTodayLearningMinutes() async throws -> Int {
        try await db.getTodayLearningMinutes()
    }
} 