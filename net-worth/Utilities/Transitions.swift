import SwiftUI

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .move(edge: .trailing).combined(with: .opacity)
    }
}
