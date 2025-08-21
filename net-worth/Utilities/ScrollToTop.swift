import SwiftUI
import UIKit

// Enables status-bar tap (time tap) to scroll to top for the active SwiftUI ScrollView.
// Ensures only one UIScrollView has scrollsToTop = true at a time to avoid the system ignoring taps.
private var _currentScrollToTopView: UIScrollView?

struct ScrollToTopEnabler: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        // Find and mark the hosting UIScrollView on next runloop when hierarchy is ready
        DispatchQueue.main.async {
            guard let scroll = enclosingScrollView(for: view) else { return }
            if let prev = _currentScrollToTopView, prev !== scroll { prev.scrollsToTop = false }
            scroll.scrollsToTop = true
            _currentScrollToTopView = scroll
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private func enclosingScrollView(for view: UIView) -> UIScrollView? {
    var node: UIView? = view
    while let v = node {
        if let sv = v as? UIScrollView { return sv }
        node = v.superview
    }
    return nil
}
