import Foundation
import SwiftData

@MainActor
final class ExportRepository {
    private let context: ModelContext
    private let exportService = CSVExportService()
    private let importService = CSVImportService()

    init(context: ModelContext) {
        self.context = context
    }

    func makeExportDocument() -> CSVExportDocument {
        exportService.makeExportDocument(context: context)
    }

    func importLoggedData(csv: String) throws -> CSVImportResult {
        try importService.importLoggedData(csv: csv, context: context)
    }
}
