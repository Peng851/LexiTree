import SwiftUI

@MainActor
final class PreviewHelper: ObservableObject {
    static let shared = PreviewHelper()
    
    @Published private(set) var isLoaded = false
    private let dataManager: DataManager
    
    private init() {
        self.dataManager = DataManager.shared
        Task {
            await setupPreviewData()
        }
    }
    
    private func setupPreviewData() async {
        do {
            let root = PreviewData.sampleRoot
            try await dataManager.saveRoot(root)
            
            let word = PreviewData.sampleWord
            try await dataManager.saveWord(word)
            
            let affix = PreviewData.sampleAffix
            try await dataManager.saveAffix(affix)
            
            isLoaded = true
        } catch {
            print("Error setting up preview data: \(error)")
        }
    }
} 