import Foundation

struct ExportData: Codable {
    let words: [Word]
    let roots: [Root]
    let affixes: [Affix]
} 