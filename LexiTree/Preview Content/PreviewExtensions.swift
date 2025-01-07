import SwiftUI

struct PreviewNavigationModifier: ViewModifier {
    func body(content: Content) -> some View {
        NavigationView {
            content
        }
    }
}

#if DEBUG
extension View {
    func previewWithNavigation() -> some View {
        modifier(PreviewNavigationModifier())
    }
}
#endif 