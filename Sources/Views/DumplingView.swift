import SwiftUI
import Foundation

/// The dumpling itself — a warm, plump silhouette that a Metal `distortionEffect`
/// squishes in real time. `SqueezeView` owns the gesture, the session and all
/// accessibility; this view is a pure function of its inputs.
///
/// Motion budget:
///  - Normal: the shader carries inflate/deflate, the thumb dimple, and a
///    barely-there idle wobble. A `TimelineView` clock runs at 30 fps at rest,
///    60 fps during a session or a press.
///  - Reduce Motion: no shader, no wobble, no morph — openness cross-fades as a
///    uniform scale + opacity, and a press is a gentle uniform push-in.
struct DumplingView: View {

    /// 0 = deflated, 1 = inflated. The breath.
    var openness: Double
    /// Dimple depth under the thumb. Slightly negative on release → a soft pop.
    var press: Double
    /// Where the thumb is, in 0…1 of the frame. `.center` when nothing is held.
    var touch: UnitPoint
    /// A session is running — suppresses the at-rest wobble.
    var isActive: Bool
    /// Frame edge length in points. A little Dynamic-Type headroom, capped.
    var side: CGFloat = 264
    /// Previews only: force the Reduce Motion path (the environment value is
    /// read-only and can't be overridden in `#Preview`).
    var forceReduceMotion = false

    @Environment(\.accessibilityReduceMotion) private var environmentReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    private var reduceMotion: Bool { environmentReduceMotion || forceReduceMotion }

    /// Silhouette inset inside the frame, so the wobble / release-pop has room
    /// to push past the resting outline without clipping.
    private var inset: CGFloat { side * 0.10 }

    var body: some View {
        Group {
            if reduceMotion {
                reducedDumpling
            } else {
                TimelineView(.animation(minimumInterval: liveClock ? 1.0 / 60.0
                                                                   : 1.0 / 24.0,
                                        paused: idleClockPaused)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: 1_000)
                    shaderDumpling(time: t)
                }
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }

    /// 60 fps only when there is real motion to resolve; otherwise a slow clock
    /// just for the idle wobble.
    private var liveClock: Bool { isActive || abs(press) > 0.0001 }

    /// Hold the idle wobble still in Low Power Mode — a calm app should be a
    /// good citizen. Real motion (a session, a press) still animates.
    private var idleClockPaused: Bool {
        !liveClock && ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: Normal path — the shader

    private func shaderDumpling(time: TimeInterval) -> some View {
        let wobble: Double = isActive ? 0 : 0.6   // still at rest, calm during a session
        return filledDumpling(openness: 0.62)
            .distortionEffect(
                ShaderLibrary.dumplingSquish(
                    .float2(CGSize(width: side, height: side)),
                    .float(Float(openness)),
                    .float2(CGPoint(x: touch.x * side, y: touch.y * side)),
                    .float(Float(press)),
                    .float(Float(time)),
                    .float(Float(wobble))),
                maxSampleOffset: CGSize(width: 110, height: 110))
            .overlay { highlight }
            .shadow(color: shadowColor, radius: 26, y: 14)
    }

    // MARK: Reduce Motion path — scale + opacity cross-fade

    private var reducedDumpling: some View {
        filledDumpling(openness: 0.62)
            .overlay { highlight }
            .scaleEffect(0.90 + 0.10 * clamped(openness))
            .scaleEffect(1 - 0.03 * max(0, press))
            .opacity(0.82 + 0.18 * clamped(openness))
            .shadow(color: shadowColor, radius: 22, y: 12)
            .animation(.easeInOut(duration: 0.5), value: openness)
            .animation(.easeOut(duration: 0.35), value: press)
    }

    // MARK: Pieces

    private func filledDumpling(openness o: Double) -> some View {
        DumplingShape(openness: o)
            .fill(fillStyle)
            .padding(inset)
    }

    /// A soft light on the upper body that leans a little toward the thumb, so
    /// the surface reads as rounded and responsive. Never the primary breath
    /// signal — size and motion carry that.
    private var highlight: some View {
        let anchor = UnitPoint(x: 0.36 + (touch.x - 0.5) * 0.18,
                               y: 0.30 + (touch.y - 0.5) * 0.18)
        return RadialGradient(
            colors: [.white.opacity(reduceTransparency ? 0.42 : 0.6),
                     .white.opacity(0.0)],
            center: anchor, startRadius: 0, endRadius: side * 0.44)
            .padding(inset)
            .mask {
                DumplingShape(openness: 0.62).fill(.black).padding(inset)
            }
            .allowsHitTesting(false)
    }

    private var fillStyle: LinearGradient {
        let top = colorScheme == .dark
            ? Color(red: 0.93, green: 0.87, blue: 0.77)
            : Color(red: 0.995, green: 0.965, blue: 0.915)
        let bottom = colorScheme == .dark
            ? Color(red: 0.79, green: 0.69, blue: 0.56)
            : Color(red: 0.93, green: 0.85, blue: 0.73)
        return LinearGradient(colors: [top, bottom],
                              startPoint: .top, endPoint: .bottom)
    }

    private var shadowColor: Color {
        .black.opacity(colorScheme == .dark ? 0.5 : 0.14)
    }

    private func clamped(_ x: Double) -> Double { min(max(x, 0), 1) }
}

// MARK: - Previews

#Preview("Openness 0 / 0.5 / 1") {
    HStack(spacing: 12) {
        ForEach([0.0, 0.5, 1.0], id: \.self) { o in
            DumplingView(openness: o, press: 0, touch: .center, isActive: true, side: 180)
        }
    }
    .padding()
    .background(Color("Canvas", bundle: .main))
}

#Preview("Pressed — thumb dimple") {
    DumplingView(openness: 0.7, press: 0.9,
                 touch: UnitPoint(x: 0.68, y: 0.6), isActive: true)
        .padding()
        .background(Color("Canvas", bundle: .main))
}

#Preview("Release pop") {
    DumplingView(openness: 0.5, press: -0.18, touch: .center, isActive: true)
        .padding()
        .background(Color("Canvas", bundle: .main))
}

#Preview("At rest — idle wobble") {
    DumplingView(openness: 0.12, press: 0, touch: .center, isActive: false)
        .padding()
        .background(Color("Canvas", bundle: .main))
}

#Preview("Reduce Motion — deflated") {
    DumplingView(openness: 0.05, press: 0, touch: .center,
                 isActive: false, forceReduceMotion: true)
        .padding()
        .background(Color("Canvas", bundle: .main))
}

#Preview("Reduce Motion — inflated") {
    DumplingView(openness: 1.0, press: 0, touch: .center,
                 isActive: true, forceReduceMotion: true)
        .padding()
        .background(Color("Canvas", bundle: .main))
}

#Preview("Dark mode") {
    DumplingView(openness: 0.8, press: 0, touch: .center, isActive: true)
        .padding()
        .background(Color("Canvas", bundle: .main))
        .preferredColorScheme(.dark)
}
