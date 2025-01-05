import Foundation

struct Root: Identifiable, Codable {
    let id: UUID
    let text: String
    let meaning: String
    let rootDescription: String
    var position: CGPoint = .zero
    var words: [Word] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case meaning
        case rootDescription = "description"
    }
    
    // CGPoint 不是 Codable，所以我们不编码 position
    // words 是计算属性，也不需要编码
} 