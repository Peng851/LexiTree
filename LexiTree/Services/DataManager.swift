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
    static let shared = DataManager()
    private var db: OpaquePointer?
    private var isInitialized = false
    
    private init() { }
    
    func initializeDatabase() async throws {
        guard !isInitialized else { return }
        
        let dbPath = getDocumentsDirectory().appendingPathComponent("lexitree.db").path
        print("📂 数据库路径: \(dbPath)")
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("✅ 数据库连接成功")
            createTablesDirectly()
            
            // 先复制words.txt文件
            if try await copyWordsFile() {
                print("✅ words.txt文件复制成功")
            }
            
            isInitialized = true
            
            if try await isEmptyDatabase() {
                print("📥 数据库为空，准备导入数据...")
                try await importWordsFromFile()
            }
        } else {
            throw DatabaseError.connectionFailed
        }
    }
    
    // 添加一个检查方法
    private func ensureInitialized() async throws {
        if !isInitialized {
            try await initializeDatabase()
        }
    }
    
    private func setupDatabase() async {
        do {
            try await initializeDatabase()
            
            if try await isEmptyDatabase() {
                print("📥 准备导入初始数据...")
                try await ImportService.shared.importData()
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
        try await ensureInitialized()
        
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
        try await ensureInitialized()
        
        let query = """
            INSERT OR REPLACE INTO roots (id, text, meaning, description)
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
            throw DatabaseError.insertFailed
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
        try await ensureInitialized()
        
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
            DROP TABLE IF EXISTS sentences;
            DROP TABLE IF EXISTS root_relations;
            DROP TABLE IF EXISTS learning_records;
            DROP TABLE IF EXISTS words;
            DROP TABLE IF EXISTS roots;
            DROP TABLE IF EXISTS affixes;
            """,
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
                root TEXT NOT NULL,
                prefix TEXT,
                suffix TEXT,
                pronunciation TEXT NOT NULL
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
    
    func importWordsFromFile() async throws {
        let fileManager = FileManager.default
        let documentsPath = getDocumentsDirectory().path
        let wordsPath = (documentsPath as NSString).appendingPathComponent("words.txt")
        
        print("📄 尝试读取words.txt文件:")
        print("  路径: \(wordsPath)")
        
        // 检查文件是否存在
        if !fileManager.fileExists(atPath: wordsPath) {
            print("❌ 文件不存在")
            return
        }
        
        // 检查文件权限
        if let attributes = try? fileManager.attributesOfItem(atPath: wordsPath) {
            print("  文件大小: \(attributes[.size] ?? 0) bytes")
            print("  创建时间: \(attributes[.creationDate] ?? Date())")
            print("  权限: \(attributes[.posixPermissions] ?? 0)")
        }
        
        // 尝试读取文件内容
        do {
            let content = try String(contentsOfFile: wordsPath, encoding: .utf8)
            print("✅ 成功读取文件内容")
            try await importContent(content)
        } catch let error {
            print("❌ 读取失败:")
            print("  错误类型: \(type(of: error))")
            print("  错误描述: \(error.localizedDescription)")
        }
    }
    
    private func importContent(_ content: String) async throws {
        print("\n📄 文件内容分析:")
        print("  总字符数: \(content.count)")
        print("  原始内容预览: \(content.prefix(100))...")
        
        let lines = content.components(separatedBy: .newlines)
        print("\n📝 行数分析:")
        print("  总行数: \(lines.count)")
        print("  非空行数: \(lines.filter { !$0.isEmpty }.count)")
        
        // 检查每一行
        for (index, line) in lines.enumerated() {
            print("\n🔍 第 \(index + 1) 行:")
            print("  长度: \(line.count)")
            print("  内容: \(line.prefix(50))...")
            print("  是否为空: \(line.isEmpty)")
            
            if !line.isEmpty {
                if let wordData = WordParser.parse(line: line) {
                    try await saveWordData(wordData)
                    print("  ✅ 成功解析并保存")
                } else {
                    print("  ❌ 解析失败")
                }
            }
        }
        
        print("\n📊 导入统计:")
        print("  总行数: \(lines.count)")
        print("  成功导入: \(lines.filter { !$0.isEmpty && WordParser.parse(line: $0) != nil }.count)")
    }
    
    private func saveWordData(_ wordData: WordData) async throws {
        // 保存词根和词缀
        for component in wordData.components {
            if component.type == "词根" {
                let root = Root(
                    id: UUID(),
                    text: component.part,
                    meaning: component.meaning,
                    rootDescription: "来自单词：\(wordData.word)"
                )
                try await saveRoot(root)
            } else {
                let affix = Affix(
                    id: UUID(),
                    text: component.part,
                    type: component.type == "前缀" ? .prefix : .suffix,
                    meaning: component.meaning
                )
                try await saveAffix(affix)
            }
        }
        
        // 保存单词
        let word = Word(
            id: wordData.id,
            text: wordData.word,
            meaning: wordData.translation,
            root: wordData.components.first { $0.type == "词根" }?.part ?? "",
            prefix: wordData.components.first { $0.type == "前缀" }?.part,
            suffix: wordData.components.first { $0.type == "后缀" }?.part,
            pronunciation: wordData.pronunciation
        )
        try await saveWord(word)
        
        // 保存例句
        let sentence = ExampleSentence(
            id: UUID(),
            text: wordData.example.english,
            translation: wordData.example.chinese,
            wordId: word.id.uuidString
        )
        try await saveSentence(sentence)
    }
    
    @MainActor
    func saveSentence(_ sentence: ExampleSentence) async throws {
        let query = """
            INSERT INTO sentences (id, word_id, text, translation)
            VALUES (?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed
        }
        defer { sqlite3_finalize(statement) }
        
        sqlite3_bind_text(statement, 1, (sentence.id.uuidString as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 2, (sentence.wordId as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 3, (sentence.text as NSString).utf8String, -1, nil)
        sqlite3_bind_text(statement, 4, (sentence.translation as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed
        }
    }
    
    private func copyWordsFile() async throws -> Bool {
        let fileManager = FileManager.default
        
        // 1. 获取源文件路径（直接使用项目根目录）
        let projectRoot = "/Users/peng/Desktop/LexiTree"  // 这里需要根据实际路径修改
        let sourcePath = "\(projectRoot)/Database/words.txt"
        
        // 2. 获取目标文件路径
        let destURL = getDocumentsDirectory().appendingPathComponent("words.txt")
        
        print("📄 复制words.txt:")
        print("  源文件路径: \(sourcePath)")
        print("  目标路径: \(destURL.path)")
        
        // 3. 验证源文件
        guard fileManager.fileExists(atPath: sourcePath) else {
            print("❌ 源文件不存在")
            return false
        }
        
        // 4. 读取源文件内容
        do {
            let sourceContent = try String(contentsOfFile: sourcePath, encoding: .utf8)
            let sourceLines = sourceContent.components(separatedBy: .newlines)
            print("  源文件内容:")
            print("    - 总行数: \(sourceLines.count)")
            print("    - 第一行: \(sourceLines.first ?? "")")
            
            // 5. 写入目标文件
            try sourceContent.write(to: destURL, atomically: true, encoding: .utf8)
            
            // 6. 验证复制后的文件
            let copiedContent = try String(contentsOf: destURL, encoding: .utf8)
            let copiedLines = copiedContent.components(separatedBy: .newlines)
            print("  复制后的文件:")
            print("    - 总行数: \(copiedLines.count)")
            print("    - 第一行: \(copiedLines.first ?? "")")
            
            return true
        } catch {
            print("❌ 文件操作失败: \(error)")
            return false
        }
    }
} 