import Foundation
import SQLite3

struct WordComponent {
    let text: String
    let type: String
    let meaning: String
}

struct VocabularyEntry {
    let word: String
    let translation: String
    let components: [WordComponent]
    let pronunciation: String
    let exampleEnglish: String
    let exampleChinese: String
    
    var root: WordComponent? {
        components.first { $0.type == "词根" }
    }
    
    var prefix: WordComponent? {
        components.first { $0.type == "前缀" }
    }
    
    var suffix: WordComponent? {
        components.first { $0.type == "后缀" }
    }
}

class DatabaseGenerator {
    static func generateDatabase() {
        do {
            let entries = try loadVocabulary()
            try createDatabase(with: entries)
            print("✅ 数据库生成成功")
        } catch {
            print("❌ 错误: \(error)")
        }
    }
    
    private static func loadVocabulary() throws -> [VocabularyEntry] {
        let fileURL = URL(fileURLWithPath: "vocabulary.txt")
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        
        return content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
            .map { line -> VocabularyEntry in
                let parts = line.components(separatedBy: "|")
                let components = parts[2].components(separatedBy: ";").map { comp -> WordComponent in
                    let details = comp.components(separatedBy: ":")
                    return WordComponent(text: details[0], type: details[1], meaning: details[2])
                }
                
                let examples = parts[4].components(separatedBy: " ~ ")
                let exampleEnglish = examples[0].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let exampleChinese = examples[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                return VocabularyEntry(
                    word: parts[0],
                    translation: parts[1],
                    components: components,
                    pronunciation: parts[3],
                    exampleEnglish: exampleEnglish,
                    exampleChinese: exampleChinese
                )
            }
    }
    
    private static func createDatabase(with entries: [VocabularyEntry]) throws {
        // 删除旧数据库
        if FileManager.default.fileExists(atPath: "lexitree.db") {
            try FileManager.default.removeItem(atPath: "lexitree.db")
        }
        
        var db: OpaquePointer?
        guard sqlite3_open("lexitree.db", &db) == SQLITE_OK else {
            throw DatabaseError.connectionFailed
        }
        defer { sqlite3_close(db) }
        
        // 执行 schema.sql
        let schemaSQL = try String(contentsOfFile: "schema.sql", encoding: .utf8)
        if sqlite3_exec(db, schemaSQL, nil, nil, nil) != SQLITE_OK {
            print("Error executing schema: \(String(cString: sqlite3_errmsg(db!)))")
        }
        
        // 插入数据
        for entry in entries {
            // 插入词根
            if let root = entry.root {
                let rootId = UUID().uuidString
                let rootSQL = """
                    INSERT INTO roots (id, text, meaning, description)
                    VALUES (?, ?, ?, ?);
                """
                var statement: OpaquePointer?
                if sqlite3_prepare_v2(db, rootSQL, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, (rootId as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 2, (root.text as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 3, (root.meaning as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 4, ("来自词根：\(root.text)" as NSString).utf8String, -1, nil)
                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }
            
            // 插入单词
            let wordId = UUID().uuidString
            let wordSQL = """
                INSERT INTO words (id, text, meaning, root, prefix, suffix, pronunciation)
                VALUES (?, ?, ?, ?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, wordSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (wordId as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 2, (entry.word as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 3, (entry.translation as NSString).utf8String, -1, nil)
                sqlite3_bind_text(statement, 4, (entry.root?.text ?? "") as NSString).utf8String, -1, nil)
                if let prefix = entry.prefix {
                    sqlite3_bind_text(statement, 5, (prefix.text as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 5)
                }
                if let suffix = entry.suffix {
                    sqlite3_bind_text(statement, 6, (suffix.text as NSString).utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(statement, 6)
                }
                sqlite3_bind_text(statement, 7, (entry.pronunciation as NSString).utf8String, -1, nil)
                sqlite3_step(statement)
                sqlite3_finalize(statement)
                
                // 插入例句
                let sentenceSQL = """
                    INSERT INTO sentences (id, word_id, text, translation)
                    VALUES (?, ?, ?, ?);
                """
                if sqlite3_prepare_v2(db, sentenceSQL, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_bind_text(statement, 1, UUID().uuidString as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 2, (wordId as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 3, (entry.exampleEnglish as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(statement, 4, (entry.exampleChinese as NSString).utf8String, -1, nil)
                    sqlite3_step(statement)
                    sqlite3_finalize(statement)
                }
            }
        }
        
        print("✅ 数据库生成成功")
    }
} 