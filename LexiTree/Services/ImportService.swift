import Foundation

class ImportService {
    static let shared = ImportService()
    
    func importData() async throws {
        let db = DataManager.shared
        try await db.importWordsFromFile()
    }
} 