import Foundation

/// Создаёт автоматические резервные снимки SQLite-базы перед миграцией схемы SwiftData.
public enum DatabaseSnapshotService {
    private static let versionMarkerFilename = "schema-version.txt"

    public static var currentSchemaVersionString: String {
        let v = FitOnySchemaV1.versionIdentifier
        return "\(v.major).\(v.minor).\(v.patch)"
    }

    /// Проверяет сохранённую версию схемы и при несовпадении копирует базу (.store/.wal/.shm) до открытия ModelContainer.
    @discardableResult
    public static func snapshotBeforeMigrationIfNeeded(
        storeURL: URL,
        backupsDirectoryURL: URL,
        currentVersion: String = currentSchemaVersionString,
        maxSnapshotsToKeep: Int = 5
    ) throws -> URL? {
        let fileManager = FileManager.default
        let markerURL = storeURL.deletingLastPathComponent().appendingPathComponent(versionMarkerFilename)

        guard fileManager.fileExists(atPath: storeURL.path) else {
            return nil
        }

        let previousVersion = (try? String(contentsOf: markerURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Создаём снимок, если маркер отсутствует (старая база без маркера) или версия схемы изменилась.
        guard previousVersion != currentVersion else {
            return nil
        }

        let label = "pre-migration-\(previousVersion ?? "unknown")-to-\(currentVersion)"
        let snapshotURL = try createSnapshot(
            storeURL: storeURL,
            backupsDirectoryURL: backupsDirectoryURL,
            label: label,
            maxSnapshotsToKeep: maxSnapshotsToKeep
        )
        return snapshotURL
    }

    /// Фиксирует актуальную версию схемы после успешного открытия/миграции ModelContainer.
    public static func recordSchemaVersion(
        storeURL: URL,
        version: String = currentSchemaVersionString
    ) throws {
        let markerURL = storeURL.deletingLastPathComponent().appendingPathComponent(versionMarkerFilename)
        try version.write(to: markerURL, atomically: true, encoding: .utf8)
    }

    /// Делает полную копию SQLite-файлов базы (.store, -wal, -shm) в папку снимков.
    @discardableResult
    public static func createSnapshot(
        storeURL: URL,
        backupsDirectoryURL: URL,
        label: String = "manual",
        maxSnapshotsToKeep: Int = 5
    ) throws -> URL {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: backupsDirectoryURL, withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate]
        let timestamp = formatter.string(from: .now).replacingOccurrences(of: ":", with: "-")
        let snapshotFolder = backupsDirectoryURL.appendingPathComponent("\(timestamp)-\(label)", isDirectory: true)
        try fileManager.createDirectory(at: snapshotFolder, withIntermediateDirectories: true)

        let candidates = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]

        for sourceURL in candidates where fileManager.fileExists(atPath: sourceURL.path) {
            let destinationURL = snapshotFolder.appendingPathComponent(sourceURL.lastPathComponent)
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        }

        try pruneOldSnapshots(in: backupsDirectoryURL, keepingNewest: maxSnapshotsToKeep)
        return snapshotFolder
    }

    private static func pruneOldSnapshots(in backupsDirectoryURL: URL, keepingNewest count: Int) throws {
        guard count > 0 else { return }
        let fileManager = FileManager.default
        let items = try fileManager.contentsOfDirectory(
            at: backupsDirectoryURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        let sorted = items.sorted { lhs, rhs in
            let d1 = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let d2 = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return d1 > d2
        }

        if sorted.count > count {
            for obsolete in sorted.dropFirst(count) {
                try? fileManager.removeItem(at: obsolete)
            }
        }
    }
}
