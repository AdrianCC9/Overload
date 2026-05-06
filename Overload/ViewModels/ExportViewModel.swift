import Foundation
import SwiftData

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var exportDocument = CSVExportDocument()
    @Published var isExporting = false
    @Published var errorMessage: String?

    private let exportRepository: ExportRepository
    private let sampleDataService: SampleDataService
    private let resetService: TrainingDataResetService

    init(context: ModelContext) {
        self.exportRepository = ExportRepository(context: context)
        self.sampleDataService = SampleDataService(context: context)
        self.resetService = TrainingDataResetService(context: context)
    }

    func prepareExport() {
        errorMessage = nil
        exportDocument = exportRepository.makeExportDocument()
        isExporting = true
    }

    func importLoggedData(from url: URL) -> Int {
        do {
            errorMessage = nil
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let csv = try String(contentsOf: url, encoding: .utf8)
            let result = try exportRepository.importLoggedData(csv: csv)
            return result.importedSetCount
        } catch {
            errorMessage = error.localizedDescription
            return 0
        }
    }

    func loadSampleData() {
        do {
            errorMessage = nil
            try sampleDataService.loadSampleData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearTrainingData() -> Bool {
        do {
            errorMessage = nil
            try resetService.clearTrainingData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
