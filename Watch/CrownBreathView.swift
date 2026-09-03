import SwiftUI
import DumplingBreathCore

/// The whole Watch app: a dumpling, a phase word, and the Crown. Tap to start
/// or stop. Turn the Crown to change the pace. Nothing else on screen.
struct CrownBreathView: View {
    @State private var session = WatchBreathSession()
    @State private var crown: Double = 5.5
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var displayOpenness: Double {
        session.isRunning ? session.openness : 0.5
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                WatchDumpling(openness: displayOpenness, reduceMotion: reduceMotion)
                    .frame(width: 104, height: 104)
                    .animation(.easeInOut(duration: 0.35), value: displayOpenness)

                Text(session.isRunning ? session.phase.label : paceLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
        }
        .focusable()
        .digitalCrownRotation(
            $crown,
            from: 3.0, through: 8.0, by: 0.5,
            sensitivity: .low,
            isContinuous: false,
            isHapticFeedbackEnabled: true)
        .onChange(of: crown) { _, value in
            session.secondsPerPhase = value
        }
        .onTapGesture {
            session.toggle()
        }
        .onAppear {
            session.secondsPerPhase = crown
        }
        .onDisappear {
            session.stop()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing dumpling")
        .accessibilityValue(session.isRunning ? session.phase.label : "Resting, \(paceLabel)")
        .accessibilityHint("Double tap to start or stop. Turn the Digital Crown to change the pace.")
        .accessibilityAddTraits(.isButton)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: crown = min(8.0, crown + 0.5)
            case .decrement: crown = max(3.0, crown - 0.5)
            @unknown default: break
            }
            session.secondsPerPhase = crown
        }
    }

    private var paceLabel: String {
        let s = crown.rounded() == crown ? String(Int(crown)) : String(format: "%.1f", crown)
        return "\(s)s each way"
    }
}

/// A dumpling for the small screen: a plump blob that fills and empties. Under
/// Reduce Motion it cross-fades scale instead of squashing.
struct WatchDumpling: View {
    var openness: Double
    var reduceMotion: Bool = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let o = min(max(openness, 0), 1)
            let squash = reduceMotion ? 1.0 : 0.76 + 0.24 * o
            let scale = reduceMotion ? 0.82 + 0.18 * o : 1.0

            RoundedRectangle(cornerRadius: side * 0.5, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.99, green: 0.96, blue: 0.91),
                                 Color(red: 0.93, green: 0.86, blue: 0.76)],
                        startPoint: .top, endPoint: .bottom))
                .frame(width: side * scale, height: side * squash * scale)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.black.opacity(0.12))
                        .frame(width: side * 0.4, height: side * 0.09)
                        .offset(y: side * 0.05 * scale)
                }
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    CrownBreathView()
}
