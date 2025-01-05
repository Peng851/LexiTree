import Foundation

enum AffixType: String, Codable {
    case prefix = "prefix"
    case suffix = "suffix"
}

struct Affix: Identifiable, Codable {
    let id: UUID
    let text: String
    let type: AffixType
    let meaning: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case type
        case meaning
    }
} 