import Foundation

@MainActor
class StudyViewModel: ObservableObject {
    @Published var currentRoot: Root?
    @Published var relatedWords: [Word] = []
    
    private let dataManager = DataManager.shared
    
    func loadInitialData() async {
        // 加载默认词根 "port"
        if let root = try? await dataManager.fetchRoot(byText: "port") {
            self.currentRoot = root
            // 加载相关单词
            if let words = try? await dataManager.fetchWords(byRoot: "port") {
                self.relatedWords = words
            }
        }
    }
}