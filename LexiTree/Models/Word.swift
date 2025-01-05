import Foundation

struct Word: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let meaning: String
    let root: String
    let prefix: String?
    let suffix: String?
    let pronunciation: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case meaning
        case root
        case prefix
        case suffix
        case pronunciation
    }
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // 实现 Equatable
    static func == (lhs: Word, rhs: Word) -> Bool {
        lhs.id == rhs.id
    }
} 