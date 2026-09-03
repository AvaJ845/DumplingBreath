import SwiftUI
import Foundation
import StoreKit
import DumplingBreathCore

/// The whole app, essentially: press and hold the dumpling to breathe with it.
///
/// Two input models, switched by the `holdToBreathe` setting:
///  - **Hold** (default): press to begin, release to stop. The release is a
///    spring with a little overshoot — letting go of something soft.
///  - **Tap**: a quick tap toggles the session; you can still squeeze the
///    dumpling any time to feel it give under your thumb without changing state.
///
/// VoiceOver and Switch Control always get a plain toggle via an accessibility
/// action, and every phase change is announced.
struct SqueezeView: View {
    let pattern: BreathingPattern
    /// Flipped to `true` by a widget tap / App Intent / Control Center control
    /// (via `RootView`) to auto-start a session. Consumed and reset here.
    var autoStart: Binding<Bool> = .constant(false)
    /// Previews only: force the Reduce Motion path (the environment value is
    /// read-only and can't be overridden in `#Preview`).
    var forceReduceMotion = false

    @State private var engine = BreathingEngine()
    @State private var haptics = HapticChoreographer()

    @State private var isBreathing = false
    @State private var visualOpenness: Double = 0

    // Touch / press feel
    @State private var press: Double = 0
    @State private var touchPoint: UnitPoint = .center
    @State private var hasLiveForce = false
    @State private var touchDownAt: Date = .now
    @State private var touchDrift: CGFloat = 0
    @State private var touchStart: CGPoint = .zero
    @State private var touchStartedSession = false

    @AppStorage("holdToBreathe") private var holdToBreathe = true

    // The one counter the North Star allows: completed sessions, used only to
    // time a single review prompt at the 3rd one. No history, no dates.
    @AppStorage("completedSessions") private var completedSessions = 0
    @AppStorage("reviewPromptedForVersion") private var reviewPromptedForVersion = ""
    @State private var sessionStartedAt: Date?

    @Environment(\.requestReview) private var requestReview
    @Environment(\.accessibilityReduceMotion) private var environmentReduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.scenePhase) private var scenePhase

    /// Shorter than this and it was a stray tap, not a breath break.
    private static let minMeaningfulSession: TimeInterval = 40

    private var reduceMotion: Bool { environmentReduceMotion || forceReduceMotion }

    @ScaledMetric(relativeTo: .largeTitle) private var scaledSide: CGFloat = 264
    private var side: CGFloat { min(scaledSide, 320) }

    var body: some View {
        ZStack {
            Color("Canvas", bundle: .main).ignoresSafeArea()

            VStack(spacing: 52) {
                dumpling
                caption
            }
        }
        .onAppear { haptics.prepare() }
        .onDisappear { teardown() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { stop() }
        }
        .onChange(of: pattern) { _, newValue in engine.pattern = newValue }
        .onChange(of: engine.phase) { _, newPhase in announce(newPhase) }
        .onChange(of: autoStart.wrappedValue) { _, want in
            guard want else { return }
            autoStart.wrappedValue = false
            engine.pattern = pattern
            start()
        }
        .task {
            engine.pattern = pattern
            engine.onTick = { openness, phase, progress in
                visualOpenness = openness
                haptics.update(openness: openness, phase: phase, phaseProgress: progress)
            }
        }
    }

    // MARK: Dumpling + touch

    private var dumpling: some View {
        DumplingView(openness: displayOpenness,
                     press: press,
                     touch: touchPoint,
                     isActive: isBreathing,
                     side: side,
                     forceReduceMotion: forceReduceMotion)
            .overlay {
                TouchTracker(onBegan: touchBegan(at:force:),
                             onMoved: touchMoved(at:force:),
                             onEnded: touchEnded)
                    .frame(width: side, height: side)
            }
            .frame(width: side, height: side)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Breathing dumpling")
            .accessibilityValue(isBreathing ? engine.phase.label : "At rest")
            .accessibilityHint(holdToBreathe
                ? "Touch and hold to breathe together. Double tap to toggle instead."
                : "Double tap to start or stop.")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default) { toggle() }
    }

    /// Openness never drops to a hard zero at rest — a shallow idle fill keeps
    /// the dumpling looking alive (the shader adds the wobble on top).
    private var displayOpenness: Double {
        isBreathing ? visualOpenness : max(visualOpenness, 0.1)
    }

    private var caption: some View {
        Text(isBreathing ? engine.phase.label
                         : (holdToBreathe ? "Hold to breathe" : "Tap to breathe"))
            .font(.callout.weight(.medium))
            .foregroundStyle(.secondary)
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            .multilineTextAlignment(.center)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: reduceMotion ? 0.5 : 0.35),
                       value: engine.phase)
            .animation(.easeInOut(duration: 0.3), value: isBreathing)
            .accessibilityHidden(true)   // the dumpling element carries this
    }

    // MARK: Touch handling

    private func touchBegan(at location: CGPoint, force: CGFloat) {
        touchDownAt = .now
        touchStart = location
        touchDrift = 0
        updateTouch(location)
        applyPress(force: force)
        if holdToBreathe {
            // Begin straight away so a real hold feels immediate; `touchEnded`
            // decides whether a *quick tap* should instead latch it on/off.
            touchStartedSession = !isBreathing
            start()
        }
    }

    private func touchMoved(at location: CGPoint, force: CGFloat) {
        let dx = location.x - touchStart.x, dy = location.y - touchStart.y
        touchDrift = max(touchDrift, (dx * dx + dy * dy).squareRoot())
        updateTouch(location)
        applyPress(force: force)
    }

    private func touchEnded() {
        hasLiveForce = false
        // Let go of something soft: underdamped spring, dips slightly past zero.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.42)) { press = 0 }
        withAnimation(.easeOut(duration: 0.3)) { touchPoint = .center }

        let quickTap = Date().timeIntervalSince(touchDownAt) < 0.4 && touchDrift < 20

        if holdToBreathe {
            if quickTap {
                // Tap-to-toggle layered on top of hold: a fresh tap latches the
                // session on and leaves it running; a tap while it's already
                // running stops it. A real hold always stops on release.
                if !touchStartedSession { stop() }
            } else {
                stop()
            }
        } else if quickTap {
            toggle()
        }
    }

    private func updateTouch(_ location: CGPoint) {
        let p = UnitPoint(x: clamp01(location.x / side),
                          y: clamp01(location.y / side))
        if reduceMotion {
            touchPoint = p
        } else {
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.72)) {
                touchPoint = p
            }
        }
    }

    private func applyPress(force: CGFloat) {
        if force > 0.01 {
            hasLiveForce = true
            withAnimation(.interactiveSpring(response: 0.16, dampingFraction: 0.7)) {
                press = 0.2 + 0.8 * Double(force)
            }
        } else if !hasLiveForce {
            // No force sensor: ramp toward a firm press while the thumb is down.
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                press = 0.85
            }
        }
    }

    // MARK: Session

    private func toggle() { isBreathing ? stop() : start() }

    private func start() {
        guard !isBreathing else { return }
        isBreathing = true
        sessionStartedAt = Date()
        haptics.begin()
        engine.start()
        announce(engine.phase)
    }

    private func stop() {
        guard isBreathing else { return }
        isBreathing = false
        engine.stop()
        haptics.end()
        withAnimation(.easeOut(duration: 1.2)) { visualOpenness = 0 }
        if voiceOver {
            AccessibilityNotification.Announcement("Resting").post()
        }
        completeSession()
    }

    /// A session that actually lasted: log it to Health if the person opted in,
    /// and — exactly once, ever — invite a review at the 3rd one. Stray taps
    /// (under `minMeaningfulSession`) don't count and aren't logged.
    private func completeSession() {
        guard let started = sessionStartedAt else { return }
        sessionStartedAt = nil
        let elapsed = Date().timeIntervalSince(started)
        guard elapsed >= Self.minMeaningfulSession else { return }

        Task { await MindfulSessionLogger.shared.logIfPermitted(duration: elapsed) }

        completedSessions += 1
        guard completedSessions == 3 else { return }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard reviewPromptedForVersion != version else { return }
        reviewPromptedForVersion = version
        requestReview()
    }

    private func teardown() {
        stop()
        haptics.teardown()
    }

    private func announce(_ phase: BreathPhase) {
        guard isBreathing, voiceOver else { return }
        AccessibilityNotification.Announcement(phase.label).post()
    }

    private func clamp01(_ x: CGFloat) -> Double { Double(min(max(x, 0), 1)) }
}

// MARK: - Previews

#Preview("Default — hold to breathe") {
    SqueezeView(pattern: .coherent)
}

#Preview("Tap to toggle") {
    SqueezeView(pattern: .box)
        .onAppear { UserDefaults.standard.set(false, forKey: "holdToBreathe") }
}

#Preview("Reduce Motion") {
    SqueezeView(pattern: .coherent, forceReduceMotion: true)
}

#Preview("Dark mode") {
    SqueezeView(pattern: .fourSevenEight)
        .preferredColorScheme(.dark)
}

#Preview("Large Dynamic Type") {
    SqueezeView(pattern: .coherent)
        .environment(\.dynamicTypeSize, .accessibility3)
}
