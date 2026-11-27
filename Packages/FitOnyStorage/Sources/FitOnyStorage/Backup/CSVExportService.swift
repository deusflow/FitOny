import Foundation
import FitOnyCore

/// Экспорт истории выполненных подходов в стандартную таблицу `CSV` (RFC 4180).
@MainActor
public enum CSVExportService {
    public static let headerRow = [
        "set_id",
        "session_id",
        "completed_at",
        "module_code",
        "exercise_code",
        "exercise_name",
        "equipment_variant",
        "set_index",
        "is_warmup",
        "is_drop_step",
        "weight_kg",
        "completed_reps",
        "left_reps",
        "right_reps",
        "rir",
        "estimated_1rm_kg",
        "peak_hr_bpm",
        "hrr60_drop_bpm",
        "slowdown_percent"
    ].joined(separator: ",")

    public static func exportCompletedSetsCSV(
        from store: FitOnyStore,
        language: AppLanguage = .da
    ) throws -> String {
        let catalog = try store.fetchCatalog()
        let sessionsByID = Dictionary(
            uniqueKeysWithValues: try store.fetchWorkoutSessions().map { ($0.id, $0) }
        )
        let sets = try store.fetchCompletedSets()

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        var lines: [String] = [headerRow]
        lines.reserveCapacity(sets.count + 1)

        for set in sets {
            let exercise = catalog.exercisesByID[set.exerciseID]
            let session = sessionsByID[set.sessionID]
            let exerciseCode = exercise?.code ?? set.exerciseID.uuidString
            let exerciseName = exercise?.name.resolved(for: language) ?? exerciseCode
            let moduleCode = session?.moduleCode ?? ""
            let e1rm: String
            if !set.isWarmup, let est = E1RMCalculator.estimate(weightKg: set.weightKg, reps: set.completedReps, rir: set.rir) {
                e1rm = formatDecimal(est)
            } else {
                e1rm = ""
            }

            let fields: [String] = [
                set.id.uuidString,
                set.sessionID.uuidString,
                isoFormatter.string(from: set.completedAt),
                escapeCSV(moduleCode),
                escapeCSV(exerciseCode),
                escapeCSV(exerciseName),
                set.equipmentVariant.rawValue,
                String(set.setIndex),
                set.isWarmup ? "true" : "false",
                set.isDropStep ? "true" : "false",
                formatDecimal(set.weightKg),
                String(set.completedReps),
                set.leftSideReps.map(String.init) ?? "",
                set.rightSideReps.map(String.init) ?? "",
                String(set.rir),
                e1rm,
                set.peakHeartRate.map(String.init) ?? "",
                set.hrr60Drop.map(String.init) ?? "",
                set.concentricSlowdownPercent.map(formatDecimal) ?? ""
            ]
            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    internal static func escapeCSV(_ raw: String) -> String {
        guard raw.contains(",") || raw.contains("\"") || raw.contains("\n") || raw.contains("\r") else {
            return raw
        }
        let doubledQuotes = raw.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(doubledQuotes)\""
    }

    private static func formatDecimal(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }
}
