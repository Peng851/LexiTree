import Foundation

struct WordData: Codable, Identifiable {
    let id: UUID
    let word: String
    let translation: String
    let components: [WordComponent]
    let pronunciation: String
    let example: Example
    
    struct WordComponent: Codable {
        let part: String
        let type: String
        let meaning: String
    }
    
    struct Example: Codable {
        let english: String
        let chinese: String
    }
} 