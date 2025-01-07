import Foundation

class WordParser {
    static func parse(line: String) -> WordData? {
        let components = line.split(separator: "|").map(String.init)
        guard components.count == 5 else { return nil }
        
        // 解析基本信息
        let word = components[0].trimmingCharacters(in: .whitespaces)
        let translation = components[1].trimmingCharacters(in: .whitespaces)
        let pronunciation = components[3].trimmingCharacters(in: .whitespaces)
        
        // 解析单词组成部分
        let wordComponents = parseWordComponents(components[2])
        
        // 解析例句
        let example = parseExample(components[4])
        
        return WordData(
            id: UUID(),
            word: word,
            translation: translation,
            components: wordComponents,
            pronunciation: pronunciation,
            example: example
        )
    }
    
    private static func parseWordComponents(_ input: String) -> [WordData.WordComponent] {
        let parts = input.split(separator: ";").map(String.init)
        return parts.compactMap { part -> WordData.WordComponent? in
            let elements = part.split(separator: ":").map(String.init)
            guard elements.count == 3 else { return nil }
            return WordData.WordComponent(
                part: elements[0].trimmingCharacters(in: .whitespaces),
                type: elements[1].trimmingCharacters(in: .whitespaces),
                meaning: elements[2].trimmingCharacters(in: .whitespaces)
            )
        }
    }
    
    private static func parseExample(_ input: String) -> WordData.Example {
        let parts = input.split(separator: "~").map(String.init)
        let english = parts[0].trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        let chinese = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"")) : ""
        return WordData.Example(english: english, chinese: chinese)
    }
} 