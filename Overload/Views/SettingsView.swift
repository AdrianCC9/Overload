import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExportViewModel?
    @State private var exportMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    DarkCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data Ownership")
                                .font(.headline)
                                .foregroundStyle(OverloadTheme.primaryText)
                            Text("All training data is stored locally with SwiftData. Export creates a folder of analytics-ready CSV files.")
                                .font(.subheadline)
                                .foregroundStyle(OverloadTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            RedPrimaryButton(title: "Export All Data", systemImage: "square.and.arrow.up") {
                                viewModel?.prepareExport()
                            }

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
                                viewModel?.loadSampleData()
                                exportMessage = "Sample data loaded."
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
            .task {
                if viewModel == nil {
                    viewModel = ExportViewModel(context: modelContext)
                }
            }
            .fileExporter(
                isPresented: Binding(
                    get: { viewModel?.isExporting ?? false },
                    set: { viewModel?.isExporting = $0 }
                ),
                document: viewModel?.exportDocument ?? CSVExportDocument(),
                contentType: .folder,
                defaultFilename: "Overload CSV Export"
            ) { result in
                switch result {
                case .success:
                    exportMessage = "Export ready."
                case .failure(let error):
                    exportMessage = error.localizedDescription
                }
            }
        }
    }
}
