import Foundation

struct Root: Identifiable, Codable {
    let id: UUID
    let text: String
    let meaning: String
    let rootDescription: String
    var position: CGPoint = .zero
    var words: [Word] = []
    
    enum CodingKeys: String, CodingKey {
        case id, text, meaning
        case rootDescription = "description"
    }
}