import Foundation

struct ExampleSentence: Codable, Identifiable {
    let id: UUID
    let text: String
    let translation: String
    let wordId: String
} 