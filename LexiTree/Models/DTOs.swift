import Foundation

struct RootDTO: Codable {
    let text: String
    let meaning: String
    let rootDescription: String
    
    enum CodingKeys: String, CodingKey {
        case text
        case meaning
        case rootDescription = "description"
    }
}

struct WordDTO: Codable {
    let text: String
    let meaning: String
    let root: String
    let prefix: String?
    let suffix: String?
    let pronunciation: String
} 