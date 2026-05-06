import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExportViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    SettingsContentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .task {
                if viewModel == nil {
                    viewModel = ExportViewModel(context: modelContext)
                }
            }
        }
    }
}

private struct SettingsContentView: View {
    @ObservedObject var viewModel: ExportViewModel
    @AppStorage(OverloadTheme.accentPreferenceKey) private var accentRawValue = AppAccentColor.red.rawValue
    @State private var exportMessage: String?
    @State private var isConfirmingClearData = false
    @State private var isImportingLoggedData = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Accent Color")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)

                        HStack(spacing: 10) {
                            ForEach(AppAccentColor.allCases) { accent in
                                Button {
                                    accentRawValue = accent.rawValue
                                } label: {
                                    Circle()
                                        .fill(accent.color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if accentRawValue == accent.rawValue {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.weight(.heavy))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .overlay {
                                            Circle()
                                                .stroke(OverloadTheme.primaryText.opacity(accentRawValue == accent.rawValue ? 0.9 : 0.18), lineWidth: 2)
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(accent.label)
                            }
                        }
                    }
                }

                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Ownership")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text("All training data is stored locally with SwiftData. Export creates one CSV with logged sets only.")
                            .font(.subheadline)
                            .foregroundStyle(OverloadTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        RedPrimaryButton(title: "Export Logged Data", systemImage: "square.and.arrow.up") {
                            exportMessage = nil
                            viewModel.prepareExport()
                        }

                        Button {
                            exportMessage = nil
                            isImportingLoggedData = true
                        } label: {
                            Label("Import Logged Data", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(OverloadTheme.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            SessionHistoryView()
                        } label: {
                            Label("Session History", systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(OverloadTheme.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Demo")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text("Load templates, planned workouts, and completed sessions for testing analytics.")
                            .font(.subheadline)
                            .foregroundStyle(OverloadTheme.secondaryText)

                        Button {
                            viewModel.loadSampleData()
                            exportMessage = viewModel.errorMessage ?? "Sample data loaded."
                        } label: {
                            Label("Load Sample Data", systemImage: "tray.and.arrow.down.fill")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(OverloadTheme.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                DarkCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reset")
                            .font(.headline)
                            .foregroundStyle(OverloadTheme.primaryText)
                        Text("Clear workouts, templates, planned days, sessions, and analytics. The exercise library stays available.")
                            .font(.subheadline)
                            .foregroundStyle(OverloadTheme.secondaryText)

                        Button(role: .destructive) {
                            isConfirmingClearData = true
                        } label: {
                            Label("Clear Training Data", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(OverloadTheme.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: OverloadTheme.cornerRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                        .foregroundStyle(OverloadTheme.secondaryText)
                }
            }
            .padding(16)
        }
        .navigationTitle("Settings")
        .overloadScreenBackground()
        .fileExporter(
            isPresented: Binding(
                get: { viewModel.isExporting },
                set: { viewModel.isExporting = $0 }
            ),
            document: viewModel.exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "Overload Logged Data.csv"
        ) { result in
            switch result {
            case .success:
                exportMessage = "Export ready."
            case .failure(let error):
                exportMessage = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingLoggedData,
            allowedContentTypes: [.commaSeparatedText, .plainText]
        ) { result in
            switch result {
            case .success(let url):
                let importedRows = viewModel.importLoggedData(from: url)
                exportMessage = viewModel.errorMessage ?? "Imported \(importedRows) logged sets."
            case .failure(let error):
                exportMessage = error.localizedDescription
            }
        }
        .confirmationDialog(
            "Clear training data?",
            isPresented: $isConfirmingClearData,
            titleVisibility: .visible
        ) {
            Button("Clear Training Data", role: .destructive) {
                if viewModel.clearTrainingData() {
                    exportMessage = "Training data cleared."
                } else {
                    exportMessage = viewModel.errorMessage
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
