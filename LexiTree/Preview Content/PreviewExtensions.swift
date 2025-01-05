import SwiftUI

struct PreviewNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        NavigationStack {
            content
        }
    }
}

extension View {
    func previewWithNavigation() -> some View {
        modifier(PreviewNavigationModifier())
    }
} 