import Foundation
import SwiftData

@MainActor
final class ExportViewModel: ObservableObject {
    @Published var exportDocument = CSVExportDocument()
    @Published var isExporting = false
    @Published var errorMessage: String?

    private let exportRepository: ExportRepository
    private let sampleDataService: SampleDataService

    init(context: ModelContext) {
        self.exportRepository = ExportRepository(context: context)
        self.sampleDataService = SampleDataService(context: context)
    }

    func prepareExport() {
        exportDocument = exportRepository.makeExportDocument()
        isExporting = true
    }

    func loadSampleData() {
        do {
            try sampleDataService.loadSampleData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

