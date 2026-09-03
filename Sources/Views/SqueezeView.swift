import SwiftUI
import DumplingBreathCore

/// The whole app, essentially: press and hold the dumpling to breathe with it.
/// A tap-to-toggle alternative is offered for accessibility (`holdToBreathe`).
///
/// SCAFFOLD — Agent 1 owns the feel: pressure-responsive squish, a satisfying
/// release spring, VoiceOver polish, Reduce Motion / Reduce Transparency paths.
struct SqueezeView: View {
    let pattern: BreathingPattern

    @State private var engine = BreathingEngine()
    @State private var haptics = HapticChoreographer()
    @State private var isBreathing = false
    @State private var visualOpenness: Double = 0

    @AppStorage("holdToBreathe") private var holdToBreathe = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color("Canvas", bundle: .main)
                .ignoresSafeArea()

            VStack(spacing: 56) {
                dumpling
                Text(isBreathing ? engine.phase.label : "Hold to breathe")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .animation(.easeInOut(duration: 0.4), value: engine.phase)
                    .accessibilityHidden(true)
            }
        }
        .onAppear { haptics.prepare() }
        .onDisappear { teardown() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { stop() }
        }
        .onChange(of: pattern) { _, newValue in
            engine.pattern = newValue
        }
        .task {
            engine.pattern = pattern
            engine.onTick = { openness, phase, progress in
                visualOpenness = openness
                haptics.update(openness: openness, phase: phase, phaseProgress: progress)
            }
        }
    }

    private var dumpling: some View {
        DumplingShape(openness: reduceMotion ? 0.55 : visualOpenness)
            .fill(dumplingFill)
            .frame(width: 240, height: 240)
            .scaleEffect(reduceMotion ? (0.88 + 0.12 * visualOpenness) : 1)
            .shadow(color: .black.opacity(0.12), radius: 26, y: 12)
            .contentShape(Circle())
            .gesture(holdToBreathe ? holdGesture : nil)
            .onTapGesture { if !holdToBreathe { toggle() } }
            .accessibilityElement()
            .accessibilityLabel("Breathing dumpling")
            .accessibilityHint(holdToBreathe
                ? "Touch and hold to breathe together."
                : "Double tap to start or stop.")
            .accessibilityValue(isBreathing ? engine.phase.label : "Resting")
            .accessibilityAddTraits(.isButton)
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in start() }
            .onEnded { _ in stop() }
    }

    private func toggle() { isBreathing ? stop() : start() }

    private func start() {
        guard !isBreathing else { return }
        isBreathing = true
        haptics.begin()
        engine.start()
    }

    private func stop() {
        guard isBreathing else { return }
        isBreathing = false
        engine.stop()
        haptics.end()
        withAnimation(.easeOut(duration: 1.2)) { visualOpenness = 0 }
    }

    private func teardown() {
        stop()
        haptics.teardown()
    }

    private var dumplingFill: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.99, green: 0.96, blue: 0.91),
                     Color(red: 0.93, green: 0.86, blue: 0.76)],
            startPoint: .top, endPoint: .bottom)
    }
}

#Preview {
    SqueezeView(pattern: .coherent)
}
