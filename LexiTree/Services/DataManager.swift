import Foundation
import SQLite3

enum DatabaseError: Error {
    case connectionFailed
    case queryFailed(String)
    case invalidData
    case fileOperationFailed
    case prepareFailed
    case executionFailed
    case insertFailed
}

@MainActor
final class DataManager {
    static let shared: DataManager = {
        let instance = DataManager()
        return instance
    }()
    
    private var db: OpaquePointer?
    
    nonisolated private init() {
        Task { @MainActor in
            await setupDatabase()
        }
    }
    
    @MainActor
    private func setupDatabase() async {
        do {
            let dbPath = getDocumentsDirectory().appendingPathComponent("lexitree.db").path
            print("📂 数据库路径: \(dbPath)")
            
            // 打开或创建数据库
            if sqlite3_open(dbPath, &db) == SQLITE_OK {
                print("✅ 数据库连接成功")
                // 创建表结构
                createTablesDirectly()
                
                // 检查是否需要导入初始数据
                if try await isEmptyDatabase() {
                    print("📥 数据库为空，准备导入初始数据...")
                    try await importInitialData()
                }
            } else {
                print("❌ 数据库连接失败")
                throw DatabaseError.connectionFailed
            }
        } catch {
            print("❌ 数据库设置失败: \(error)")
        }
    }
    
    private func isEmptyDatabase() async throws -> Bool {
        let query = "SELECT COUNT(*) FROM words;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return true // 如果表不存在，也认为是空数据库
        }
        defer { sqlite3_finalize(statement) }
        
        if sqlite3_step(statement) == SQLITE_ROW {
            let count = sqlite3_column_int(statement, 0)
            return count == 0
        }
        return true
    }
    
    private func importInitialData() async throws {
        // 添加更多初始数据
        let initialRoots = [
            Root(id: UUID(), text: "act", meaning: "行动", rootDescription: "表示行动或做"),
            Root(id: UUID(), text: "duc", meaning: "引导", rootDescription: "表示引导或带领"),
            Root(id: UUID(), text: "port", meaning: "搬运", rootDescription: "表示搬运或携带"),
            Root(id: UUID(), text: "spect", meaning: "看", rootDescription: "表示看或观察"),
            Root(id: UUID(), text: "struct", meaning: "建造", rootDescription: "表示建造或构建")
        ]
        
        let initialWords = [
            Word(id: UUID(), text: "action", meaning: "行动", root: "act", prefix: nil, suffix: "ion", pronunciation: "/ˈækʃən/"),
            Word(id: UUID(), text: "conduct", meaning: "引导", root: "duc", prefix: "con", suffix: "t", pronunciation: "/kənˈdʌkt/"),
            Word(id: UUID(), text: "export", meaning: "出口", root: "port", prefix: "ex", suffix: nil, pronunciation: "/ˈekspɔːrt/"),
            Word(id: UUID(), text: "inspect", meaning: "检查", root: "spect", prefix: "in", suffix: nil, pronunciation: "/ɪnˈspekt/"),
            Word(id: UUID(), text: "structure", meaning: "结构", root: "struct", prefix: nil, suffix: "ure", pronunciation: "/ˈstrʌktʃər/")
        ]
        
        // 保存根词
        for root in initialRoots {
            do {
                try await saveRoot(root)
                print("✅ 成功保存词根: \(root.text)")
            } catch {
                print("❌ 保存词根失败: \(root.text), 错误: \(error)")
            }
        }
        
        // 保存单词
        for word in initialWords {
            do {
                try await saveWord(word)
                print("✅ 成功保存单词: \(word.text)")
            } catch {
                print("❌ 保存单词失败: \(word.text), 错误: \(error)")
            }
        }
        
        print("✅ 初始数据导入完成")
    }
    
    private func getDocumentsDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory
    }
    
    private func createNewDatabase(at path: String) {
        if let bundleDB = Bundle.main.path(forResource: "lexitree", ofType: "db") {
            try? FileManager.default.copyItem(atPath: bundleDB, toPath: path)
        } else {
            openConnection(at: path)
            createTables()
        }
    }
    
    private func openConnection(at path: String) {
        print("尝试打开数据库连接: \(path)")
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("数据库打开失败: \(String(cString: sqlite3_errmsg(db)))")
            db = nil
        } else {
            print("数据库连接成功")
        }
    }
    
    private func createTables() {
        let createTables = [
            """
            CREATE TABLE IF NOT EXISTS roots (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                meaning TEXT NOT NULL,
                description TEXT NOT NULL
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS words (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                meaning TEXT NOT NULL,
                root_id TEXT NOT NULL,
                prefix TEXT,
                suffix TEXT,
                pronunciation TEXT NOT NULL,
                FOREIGN KEY(root_id) REFERENCES roots(id)
            );
            """
        ]
        
        for sql in createTables {
            if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
                print("Error creating table: \(String(cString: sqlite3_errmsg(db)!))")
            }
        }
    }
    
    // MARK: - Word Operations
    func saveWord(_ word: Word) async throws {
        let query = """
            INSERT INTO words (id, text, meaning, root, prefix, suffix, pronunciation)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (word.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (word.text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (word.meaning as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (word.root as NSString).utf8String, -1, nil)
        if let prefix = word.prefix {
            sqlite3_bind_text(statement, 5, (prefix as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 5)
        }
        if let suffix = word.suffix {
            sqlite3_bind_text(statement, 6, (suffix as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(statement, 6)
        }
        sqlite3_bind_text(statement, 7, (word.pronunciation as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.insertFailed
        }
    }
    
    @MainActor
    func getWords(forRoot root: String) async throws -> [Word] {
        let query = "SELECT id, text, meaning, root, prefix, suffix, pronunciation FROM words WHERE root = ? ORDER BY text;"
        var statement: OpaquePointer?
        var words: [Word] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (root as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let word = Word(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                meaning: String(cString: sqlite3_column_text(statement, 2)),
                root: String(cString: sqlite3_column_text(statement, 3)),
                prefix: sqlite3_column_text(statement, 4).map { String(cString: $0) },
                suffix: sqlite3_column_text(statement, 5).map { String(cString: $0) },
                pronunciation: String(cString: sqlite3_column_text(statement, 6))
            )
            words.append(word)
        }
        
        return words
    }
    
    // MARK: - Root Operations
    @MainActor
    func saveRoot(_ root: Root) async throws {
        let query = """
            INSERT OR REPLACE INTO roots (id, text, meaning, root_description)
            VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (root.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (root.text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (root.meaning as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (root.rootDescription as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed
        }
    }
    
    @MainActor
    func getAllRoots() async throws -> [Root] {
        let query = "SELECT id, text, meaning, description FROM roots ORDER BY text;"
        var statement: OpaquePointer?
        var roots: [Root] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let root = Root(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                meaning: String(cString: sqlite3_column_text(statement, 2)),
                rootDescription: String(cString: sqlite3_column_text(statement, 3))
            )
            roots.append(root)
        }
        
        return roots
    }
    
    // MARK: - Cleanup
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Database Export
    @MainActor
    func exportDatabase() throws -> URL {
        let fileManager = FileManager.default
        let exportURL = fileManager.temporaryDirectory.appendingPathComponent("lexitree_export.db")
        
        // 确保数据库已关闭
        sqlite3_close(db)
        db = nil
        
        let dbPath = getDocumentsDirectory().appendingPathComponent("lexitree.db").path
        try fileManager.copyItem(at: URL(fileURLWithPath: dbPath), 
                               to: exportURL)
        
        // 重新打开数据库
        openConnection(at: dbPath)
        
        return exportURL
    }
    
    // MARK: - Affix Operations
    @MainActor
    func saveAffix(_ affix: Affix) async throws {
        let query = """
            INSERT OR REPLACE INTO affixes (id, text, type, meaning)
            VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (affix.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (affix.text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (affix.type.rawValue as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (affix.meaning as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed
        }
    }
    
    @MainActor
    func getAffixes(ofType type: AffixType? = nil) async throws -> [Affix] {
        let query = type == nil ?
            "SELECT id, text, type, meaning FROM affixes ORDER BY text;" :
            "SELECT id, text, type, meaning FROM affixes WHERE type = ? ORDER BY text;"
        
        var statement: OpaquePointer?
        var affixes: [Affix] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        if let type = type {
            sqlite3_bind_text(statement, 1, (type.rawValue as NSString).utf8String, -1, nil)
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let affix = Affix(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                type: AffixType(rawValue: String(cString: sqlite3_column_text(statement, 2)))!,
                meaning: String(cString: sqlite3_column_text(statement, 3))
            )
            affixes.append(affix)
        }
        
        return affixes
    }
    
    // MARK: - Import/Export
    @MainActor
    func exportToJSON() async throws -> Data {
        let exportData = ExportData(
            words: try await getAllWords(),
            roots: try await getAllRoots(),
            affixes: try await getAffixes(ofType: nil)
        )
        return try JSONEncoder().encode(exportData)
    }
    
    @MainActor
    func importFromJSON(_ data: Data) async throws {
        let importData = try JSONDecoder().decode(ExportData.self, from: data)
        for root in importData.roots {
            try await saveRoot(root)
        }
        for word in importData.words {
            try await saveWord(word)
        }
        for affix in importData.affixes {
            try await saveAffix(affix)
        }
    }
    
    // 新增：获取所有单词
    @MainActor
    func getAllWords() async throws -> [Word] {
        print("开始查询数据库...")
        let query = "SELECT id, text, meaning, root, prefix, suffix, pronunciation FROM words ORDER BY text;"
        var statement: OpaquePointer?
        var words: [Word] = []
        
        guard let db = db else {
            print("数据库连接为空")
            throw DatabaseError.connectionFailed
        }
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            print("SQL准备失败: \(String(cString: sqlite3_errmsg(db)))")
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let word = Word(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                meaning: String(cString: sqlite3_column_text(statement, 2)),
                root: String(cString: sqlite3_column_text(statement, 3)),
                prefix: sqlite3_column_text(statement, 4).map { String(cString: $0) },
                suffix: sqlite3_column_text(statement, 5).map { String(cString: $0) },
                pronunciation: String(cString: sqlite3_column_text(statement, 6))
            )
            words.append(word)
            print("读取到单词: \(word.text)")
        }
        
        print("总共读取到 \(words.count) 个单词")
        return words
    }
    
    func getRoot(byText text: String) async throws -> Root? {
        let query = "SELECT id, text, meaning, description FROM roots WHERE text = ? LIMIT 1;"
        var statement: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (text as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return Root(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                meaning: String(cString: sqlite3_column_text(statement, 2)),
                rootDescription: String(cString: sqlite3_column_text(statement, 3))
            )
        }
        
        return nil
    }
    
    private func copyPresetDatabaseIfNeeded() -> Bool {
        guard let presetPath = Bundle.main.path(forResource: "lexitree", ofType: "db") else {
            return false
        }
        
        let dbPath = getDocumentsDirectory().appendingPathComponent("lexitree.db").path
        
        do {
            if FileManager.default.fileExists(atPath: dbPath) {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: dbPath))
            }
            try FileManager.default.copyItem(at: URL(fileURLWithPath: presetPath), 
                                           to: URL(fileURLWithPath: dbPath))
            return true
        } catch {
            print("Error copying preset database: \(error)")
            return false
        }
    }
    
    // 学习记录相关
    func recordLearningTime(_ minutes: Int) async throws {
        let query = """
            INSERT INTO learning_records (id, date, minutes)
            VALUES (?, date('now'), ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        let id = UUID().uuidString
        sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 2, Int32(minutes))
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed
        }
    }
    
    func getTodayLearningMinutes() async throws -> Int {
        let query = """
            SELECT COALESCE(SUM(minutes), 0)
            FROM learning_records
            WHERE date = date('now');
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw DatabaseError.executionFailed
        }
        
        return Int(sqlite3_column_int(statement, 0))
    }
    
    func getRootRelations(for root: Root) async throws -> [RootRelationData] {
        let query = """
            SELECT r2.*, rr.relation_type, rr.description
            FROM root_relations rr
            INNER JOIN roots r2 ON rr.root2_id = r2.id
            WHERE rr.root1_id = ?
            ORDER BY r2.text;
        """
        
        var statement: OpaquePointer?
        var relations: [RootRelationData] = []
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (root.id.uuidString as NSString).utf8String, -1, nil)
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let relatedRoot = Root(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                meaning: String(cString: sqlite3_column_text(statement, 2)),
                rootDescription: String(cString: sqlite3_column_text(statement, 3))
            )
            
            let relation = RootRelationData(
                root1: root,
                root2: relatedRoot,
                relationType: String(cString: sqlite3_column_text(statement, 4)),
                description: String(cString: sqlite3_column_text(statement, 5))
            )
            
            relations.append(relation)
        }
        
        return relations
    }
    
    func getExample(forRoot root: String) async throws -> ExampleSentence? {
        let query = """
            SELECT s.id, s.text, s.translation, s.word_id
            FROM sentences s
            INNER JOIN words w ON s.word_id = w.id
            WHERE w.root_id = (SELECT id FROM roots WHERE text = ?)
            ORDER BY RANDOM()
            LIMIT 1;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (root as NSString).utf8String, -1, nil)
        
        if sqlite3_step(statement) == SQLITE_ROW {
            return ExampleSentence(
                id: UUID(uuidString: String(cString: sqlite3_column_text(statement, 0)))!,
                text: String(cString: sqlite3_column_text(statement, 1)),
                translation: String(cString: sqlite3_column_text(statement, 2)),
                wordId: String(cString: sqlite3_column_text(statement, 3))
            )
        }
        
        return nil
    }
    
    func exportData() async throws -> ExportData {
        async let words = getAllWords()
        async let roots = getAllRoots()
        async let affixes = getAffixes(ofType: nil)
        
        return try await ExportData(
            words: words,
            roots: roots,
            affixes: affixes
        )
    }
    
    private func createTablesDirectly() {
        let createTableStatements = [
            """
            CREATE TABLE IF NOT EXISTS words (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                meaning TEXT NOT NULL,
                root TEXT NOT NULL,
                prefix TEXT,
                suffix TEXT,
                pronunciation TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS roots (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                meaning TEXT NOT NULL,
                root_description TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS affixes (
                id TEXT PRIMARY KEY,
                text TEXT NOT NULL,
                type TEXT NOT NULL,
                meaning TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS sentences (
                id TEXT PRIMARY KEY,
                word_id TEXT NOT NULL,
                text TEXT NOT NULL,
                translation TEXT NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(word_id) REFERENCES words(id)
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS root_relations (
                id TEXT PRIMARY KEY,
                root1_id TEXT NOT NULL,
                root2_id TEXT NOT NULL,
                relation_type TEXT NOT NULL,
                description TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY(root1_id) REFERENCES roots(id),
                FOREIGN KEY(root2_id) REFERENCES roots(id)
            );
            """,
            """
            CREATE TABLE IF NOT EXISTS learning_records (
                id TEXT PRIMARY KEY,
                date DATE NOT NULL,
                minutes INTEGER NOT NULL,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );
            """
        ]
        
        for statement in createTableStatements {
            var errMsg: UnsafeMutablePointer<Int8>?
            if sqlite3_exec(db, statement, nil, nil, &errMsg) != SQLITE_OK {
                let error = String(cString: errMsg!)
                print("❌ 创建表失败: \(error)")
                sqlite3_free(errMsg)
            } else {
                print("✅ 成功创建表")
            }
        }
        print("✅ 所有数据库表创建完成")
    }
} 