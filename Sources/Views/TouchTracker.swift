import SwiftUI
import UIKit

/// A thin UIKit touch layer under the dumpling. It exists for one thing SwiftUI
/// gestures don't give us: the **force** of the press on devices that report it
/// (`forceTouchCapability`). Where force isn't measurable it still reports the
/// touch location and `SqueezeView` ramps a synthetic strength instead.
///
/// Raw touches only — no tap/hold semantics (the caller decides) and no
/// accessibility. VoiceOver / Switch Control users drive the dumpling through
/// `SqueezeView`'s accessibility actions, never through this view.
struct TouchTracker: UIViewRepresentable {
    /// location in the view's coordinate space, normalised force 0…1 (0 if the
    /// device can't measure it). All invoked on the main actor.
    var onBegan: @MainActor (CGPoint, CGFloat) -> Void
    var onMoved: @MainActor (CGPoint, CGFloat) -> Void
    var onEnded: @MainActor () -> Void

    func makeUIView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.apply(self)
        return view
    }

    func updateUIView(_ view: TrackingView, context: Context) {
        view.apply(self)
    }

    final class TrackingView: UIView {
        private var onBegan: (@MainActor (CGPoint, CGFloat) -> Void)?
        private var onMoved: (@MainActor (CGPoint, CGFloat) -> Void)?
        private var onEnded: (@MainActor () -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isMultipleTouchEnabled = false
            backgroundColor = .clear
            isAccessibilityElement = false
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) unused") }

        func apply(_ tracker: TouchTracker) {
            onBegan = tracker.onBegan
            onMoved = tracker.onMoved
            onEnded = tracker.onEnded
        }

        /// Only accept touches inside the inscribed circle — the dumpling's real
        /// footprint — so the corners of the square stay inert.
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let r = min(bounds.width, bounds.height) / 2
            let c = CGPoint(x: bounds.midX, y: bounds.midY)
            return hypot(point.x - c.x, point.y - c.y) <= r * 1.05
        }

        private func force(of touch: UITouch) -> CGFloat {
            guard traitCollection.forceTouchCapability == .available,
                  touch.maximumPossibleForce > 0 else { return 0 }
            return min(1, touch.force / touch.maximumPossibleForce)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onBegan?(t.location(in: self), force(of: t))
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let t = touches.first else { return }
            onMoved?(t.location(in: self), force(of: t))
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            onEnded?()
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            onEnded?()
        }
    }
}
