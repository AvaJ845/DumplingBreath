import SwiftUI
import DumplingBreathCore

/// The entire app surface: one dumpling you hold to breathe with, plus a
/// quiet corner button to change the breathing pattern. No tabs, no home
/// screen, no account. (North Star §1.)
struct RootView: View {
    @AppStorage("patternID") private var patternID = BreathingPattern.coherent.id
    @State private var showingPatterns = false
    @State private var autoStart = false
    @Environment(\.scenePhase) private var scenePhase

    private var pattern: BreathingPattern {
        BreathingPattern.bundled.first { $0.id == patternID } ?? .coherent
    }

    var body: some View {
        SqueezeView(pattern: pattern, autoStart: $autoStart)
            .overlay(alignment: .topTrailing) {
                Button {
                    showingPatterns = true
                } label: {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.title3)
                        .padding(24)
                        .contentShape(Rectangle())
                }
                .tint(.secondary)
                .accessibilityLabel("Choose breathing pattern")
            }
            .sheet(isPresented: $showingPatterns) {
                PatternPicker(selection: $patternID)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            // A widget's whole-tile tap deep-links in here…
            .onOpenURL { url in
                if let id = SessionRequestStore.patternID(from: url) {
                    beginRequestedSession(patternID: id)
                }
            }
            // …while the App Intent and Control Center control leave a request
            // in the app group for us to pick up when we next become active.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, let id = SessionRequestStore.consumePendingRequest() {
                    beginRequestedSession(patternID: id)
                }
            }
    }

    /// Honour a start request from outside the app. An empty id means "just
    /// start with whatever pattern is already selected."
    private func beginRequestedSession(patternID id: String) {
        if !id.isEmpty, BreathingPattern.bundled.contains(where: { $0.id == id }) {
            patternID = id
        }
        showingPatterns = false
        autoStart = true
    }
}

private struct PatternPicker: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(BreathingPattern.bundled) { pattern in
                Button {
                    selection = pattern.id
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pattern.name).foregroundStyle(.primary)
                            Text(pattern.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if pattern.id == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                                .accessibilityLabel("Selected")
                        }
                    }
                }
            }
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RootView()
}
