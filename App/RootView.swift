import SwiftUI
import DumplingBreathCore

/// The entire app surface: one dumpling you hold to breathe with, plus a
/// quiet corner button to change the breathing pattern. No tabs, no home
/// screen, no account. (North Star §1.)
struct RootView: View {
    @AppStorage("patternID") private var patternID = BreathingPattern.coherent.id
    @State private var showingPatterns = false

    private var pattern: BreathingPattern {
        BreathingPattern.bundled.first { $0.id == patternID } ?? .coherent
    }

    var body: some View {
        SqueezeView(pattern: pattern)
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
