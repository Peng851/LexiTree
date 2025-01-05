import SwiftUI

struct PreviewData {
    static let sampleWord = Word(
        id: UUID(),
        text: "import",
        meaning: "进口，输入",
        root: "port",
        prefix: "im",
        suffix: nil,
        pronunciation: "ɪmˈpɔːrt"
    )
    
    static let sampleRoot = Root(
        id: UUID(),
        text: "port",
        meaning: "港口，运输",
        rootDescription: "来自拉丁语 portare，表示携带、运输"
    )
    
    static let words = [sampleWord]
    static let root = sampleRoot
    
    static let sampleAffix = Affix(
        id: UUID(),
        text: "im",
        type: .prefix,
        meaning: "使...，向内"
    )
} 