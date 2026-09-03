import Foundation

/// The timing of a single breath, in seconds. A pure value type — the entire
/// "what kind of breathing is this" decision lives here and nowhere else.
///
/// Agent 2 (Haptics & breathing science) owns the bundled catalogue below and
/// its clinical rationale.
public struct BreathingPattern: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let detail: String
    public let inhale: Double
    public let holdIn: Double
    public let exhale: Double
    public let holdOut: Double

    public init(id: String, name: String, detail: String,
                inhale: Double, holdIn: Double, exhale: Double, holdOut: Double) {
        self.id = id
        self.name = name
        self.detail = detail
        self.inhale = inhale
        self.holdIn = holdIn
        self.exhale = exhale
        self.holdOut = holdOut
    }

    public var cycleDuration: Double { inhale + holdIn + exhale + holdOut }

    public func duration(of phase: BreathPhase) -> Double {
        switch phase {
        case .inhale:  return inhale
        case .holdIn:  return holdIn
        case .exhale:  return exhale
        case .holdOut: return holdOut
        }
    }
}

extension BreathingPattern {

    /// **Coherent / resonant breathing — the default.** 5.5 s in, 5.5 s out
    /// (≈ 5.45 breaths/min). Paced breathing near ~6 breaths/min sits at the
    /// resonance frequency of the human baroreflex loop, where respiratory and
    /// cardiac rhythms phase-lock and heart-rate-variability amplitude and vagal
    /// (parasympathetic) tone are maximised. Equal in/out, no holds — the least
    /// demanding thing to follow in a bad moment.
    ///
    /// Rationale: Lehrer & Gevirtz, "Heart rate variability biofeedback: how and
    /// why does it work?", *Frontiers in Psychology* 5:756 (2014); Steffen et
    /// al., *Frontiers in Public Health* 5:222 (2017); Shaffer & Ginsberg, "An
    /// Overview of Heart Rate Variability Metrics and Norms", *Frontiers in
    /// Public Health* 5:258 (2017). The 5.5/5.5 figure is the "resonance"
    /// protocol popularised by Elliott & Edmonson, *The New Science of Breath*
    /// (2004), and used by most coherent-breathing apps.
    public static let coherent = BreathingPattern(
        id: "coherent", name: "Coherent", detail: "5.5 in · 5.5 out",
        inhale: 5.5, holdIn: 0, exhale: 5.5, holdOut: 0)

    /// **Box breathing — 4 · 4 · 4 · 4.** Equal inhale / hold / exhale / hold
    /// (16 s cycle, 3.75 breaths/min). The end-inspiratory and end-expiratory
    /// pauses add mild CO₂-tolerance work and a deliberate, countable structure;
    /// used in military "tactical / combat breathing" to hold arousal down before
    /// and during stress.
    ///
    /// Rationale: Röttger et al., "The Effectiveness of Combat Tactical Breathing
    /// as Compared With Prolonged Exhalation", *Applied Psychophysiology and
    /// Biofeedback* 46:19–28 (2021); Divine, *The Way of the SEAL* (2013);
    /// Norris et al. on tactical breathing in performance-under-stress training.
    public static let box = BreathingPattern(
        id: "box", name: "Box", detail: "4 · 4 · 4 · 4",
        inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)

    /// **4-7-8 — wind-down / pre-sleep.** Inhale 4, hold 7, exhale 8, no bottom
    /// pause (19 s cycle, ~3.2 breaths/min). A long retention plus a
    /// double-length exhale pushes hard toward parasympathetic dominance.
    /// Adapted from prāṇāyāma and popularised by Andrew Weil.
    ///
    /// Rationale: Vierra et al., "Turning Down the Stress Response With 4-7-8
    /// Breathing" (2022); Aktaş & Ok, effects of 4-7-8 breathing on dyspnoea /
    /// anxiety (2022). Evidence is still thin and mostly small-sample — offered
    /// as an optional wind-down, never the default, and the 7 s hold is a lot to
    /// ask of a beginner.
    public static let fourSevenEight = BreathingPattern(
        id: "478", name: "4·7·8", detail: "4 in · 7 hold · 8 out",
        inhale: 4, holdIn: 7, exhale: 8, holdOut: 0)

    /// **Extended exhale — 4 in · 6 out.** Exhale half again as long as the
    /// inhale (1 : 1.5 ratio), no holds (10 s cycle, 6 breaths/min — so it also
    /// lands near cardiac resonance). Lengthening the exhale relative to the
    /// inhale raises respiratory sinus arrhythmia and self-reported relaxation
    /// beyond the effect of slowing the rate alone: the parasympathetic branch
    /// acts largely during exhalation.
    ///
    /// Rationale: Van Diest et al., "Inhalation/Exhalation Ratio Modulates the
    /// Effect of Slow Breathing on Heart Rate Variability and Relaxation",
    /// *Applied Psychophysiology and Biofeedback* 39:171–180 (2014); Komori,
    /// "The relaxation effect of prolonged expiratory breathing", *Mental Illness*
    /// 10:6-9 (2018).
    public static let extendedExhale = BreathingPattern(
        id: "extended-exhale", name: "Extended exhale", detail: "4 in · 6 out",
        inhale: 4, holdIn: 0, exhale: 6, holdOut: 0)

    /// **Rest — 3 in · 3 out.** ~10 breaths/min (6 s cycle): the gentlest pace
    /// that still clears the usual "slow breathing" threshold (< ~10 breaths/min
    /// for the HRV / parasympathetic effects), and a small, comfortable step down
    /// from a resting 12–15 breaths/min with no air hunger. A beginner's on-ramp
    /// toward Coherent, and the right default for a first session or for children.
    ///
    /// Rationale: Russo, Santarelli & O'Rourke, "The physiological effects of
    /// slow breathing in the healthy human", *Breathe* 13:298–309 (2017)
    /// (10 breaths/min as the practical slow-breathing threshold).
    public static let rest = BreathingPattern(
        id: "rest", name: "Rest", detail: "3 in · 3 out",
        inhale: 3, holdIn: 0, exhale: 3, holdOut: 0)

    /// Order = the order the picker shows them. Coherent leads (the default);
    /// Rest is the gentle on-ramp; the rest are situational. The picker is a
    /// quiet afterthought — the default has to be right without it.
    public static let bundled: [BreathingPattern] =
        [.coherent, .rest, .extendedExhale, .box, .fourSevenEight]
}
