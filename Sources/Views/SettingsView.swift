import SwiftUI
import CoreHaptics
import HealthKit
import DumplingBreathCore

/// The one settings surface. Everything a person might want to adjust, nothing
/// they shouldn't have to think about. No account section, because there is no
/// account. (North Star §1.)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("holdToBreathe") private var holdToBreathe = true
    @Bindable private var haptics = HapticSettings.shared
    @Bindable private var health = HealthConsent.shared

    private let deviceHasHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let healthAvailable = HKHealthStore.isHealthDataAvailable()

    var body: some View {
        NavigationStack {
            Form {
                breathingSection
                hapticsSection
                if healthAvailable { healthSection }
                privacySection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Breathing

    private var breathingSection: some View {
        Section {
            Picker("Start a session by", selection: $holdToBreathe) {
                Text("Holding the dumpling").tag(true)
                Text("Tapping once").tag(false)
            }
        } header: {
            Text("Breathing")
        } footer: {
            Text(holdToBreathe
                 ? "Press and hold to breathe together; let go to stop. A quick tap also works."
                 : "Tap once to start, tap again to stop. Squeeze the dumpling any time to feel it give.")
        }
    }

    // MARK: Haptics

    private var hapticsSection: some View {
        Section {
            Toggle("Haptics", isOn: $haptics.isEnabled)

            if haptics.isEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Strength")
                        .font(.subheadline)
                    Slider(value: $haptics.intensityScale, in: 0...1) {
                        Text("Haptic strength")
                    } minimumValueLabel: {
                        Image(systemName: "wave.3.left").imageScale(.small)
                    } maximumValueLabel: {
                        Image(systemName: "wave.3.right").imageScale(.small)
                    }
                    .accessibilityValue("\(Int(haptics.intensityScale * 100)) percent")
                }

                Toggle("Soft tone instead of silence", isOn: $haptics.audioFallbackEnabled)
            }
        } header: {
            Text("Haptics")
        } footer: {
            if !deviceHasHaptics {
                Text("This device has no Taptic Engine, so the breath can't be felt. Turn on “Soft tone instead of silence” to hear a gentle cue that swells and fades with each breath — it respects the silent switch.")
            } else if haptics.isEnabled {
                Text("The dumpling’s rhythm plays through the Taptic Engine — a swell as you breathe in, a release as you breathe out.")
            } else {
                Text("The breath will still show on screen.")
            }
        }
    }

    // MARK: Health

    private var healthSection: some View {
        Section {
            Toggle("Log Mindful Minutes", isOn: $health.logMindfulMinutes)
                .onChange(of: health.logMindfulMinutes) { _, on in
                    if on { Task { await MindfulSessionLogger.shared.requestAuthorization() } }
                }

            if #available(iOS 18.0, *) {
                Toggle("Log a moment of calm", isOn: $health.logStateOfMind)
                    .onChange(of: health.logStateOfMind) { _, on in
                        if on { Task { await MindfulSessionLogger.shared.requestAuthorization() } }
                    }
            }
        } header: {
            Text("Health")
        } footer: {
            Text("Off by default. When on, a finished session is written to the Health app on this device — nothing is sent anywhere, because Dumpling Breath has no way to reach the internet.")
        }
    }

    // MARK: Privacy

    private var privacySection: some View {
        Section {
            Label("No account, ever", systemImage: "person.slash")
            Label("No analytics, no tracking", systemImage: "eye.slash")
            Label("No network connection at all", systemImage: "wifi.slash")
        } header: {
            Text("Privacy")
        } footer: {
            Text("Dumpling Breath collects nothing. Your settings live on this device. There is no server, no sign-in, and no data to leak. Version \(appVersion).")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }
}

#Preview {
    SettingsView()
}

#Preview("Dark") {
    SettingsView().preferredColorScheme(.dark)
}
