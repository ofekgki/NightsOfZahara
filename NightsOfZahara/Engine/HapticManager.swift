//  Light wrapper around UIKit haptics, gated by the user's settings.

import UIKit

enum HapticKind {
    case light, success, warning, heavy, selection
}

enum HapticManager {
    static func play(_ kind: HapticKind) {
        guard AppSettings.shared.hapticsOn else { return }
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    /// Map an action outcome tone to an appropriate haptic.
    static func forTone(_ tone: OutcomeTone) {
        switch tone {
        case .good:    play(.light)
        case .epic:    play(.success)
        case .bad:     play(.warning)
        case .neutral: play(.selection)
        }
    }
}
