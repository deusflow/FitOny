import Foundation
import SwiftData
import FitOnyCore

/// Единый координатор локальной базы данных SwiftData и репозиториев FitOny.
@MainActor
public final class FitOnyStore {
    public let container: ModelContainer
    public let storeURL: URL?

    internal let encoder: JSONEncoder
    internal let decoder: JSONDecoder

    public init(container: ModelContainer, storeURL: URL? = nil) {
        self.container = container
        self.storeURL = storeURL

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    internal var context: ModelContext {
        container.mainContext
    }

    /// Открывает постоянную SQLite-базу SwiftData, при смене версии схемы делает авто-снимок и сеет встроенный каталог PureGym.
    public static func makePersistentStore(directoryURL: URL? = nil) throws -> FitOnyStore {
        let baseDirectory: URL
        if let directoryURL {
            baseDirectory = directoryURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            baseDirectory = appSupport.appendingPathComponent("FitOny", isDirectory: true)
        }

        try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

        let storeURL = baseDirectory.appendingPathComponent("FitOny.store")
        let backupsURL = baseDirectory.appendingPathComponent("Backups/PreMigration", isDirectory: true)

        try DatabaseSnapshotService.snapshotBeforeMigrationIfNeeded(
            storeURL: storeURL,
            backupsDirectoryURL: backupsURL
        )

        let schema = Schema(versionedSchema: FitOnySchemaV1.self)
        let config = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: FitOnyMigrationPlan.self,
            configurations: [config]
        )

        try DatabaseSnapshotService.recordSchemaVersion(storeURL: storeURL)

        let store = FitOnyStore(container: container, storeURL: storeURL)
        try store.seedBuiltInCatalogIfNeeded()
        return store
    }

    /// Создаёт изолированное хранилище в оперативной памяти (для SwiftUI Previews и автотестов).
    public static func makeInMemoryStore(seedBuiltInCatalog: Bool = true) throws -> FitOnyStore {
        let schema = Schema(versionedSchema: FitOnySchemaV1.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: FitOnyMigrationPlan.self,
            configurations: [config]
        )

        let store = FitOnyStore(container: container, storeURL: nil)
        if seedBuiltInCatalog {
            try store.seedBuiltInCatalogIfNeeded()
        }
        return store
    }

    internal func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    internal func decode<T: Decodable>(_ type: T.Type, from data: Data, entity: String) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw FitOnyDatabaseError.invalidEncodedPayload(entity: entity)
        }
    }

    internal func fetchFirst<M: PersistentModel>(_ descriptor: FetchDescriptor<M>) throws -> M? {
        var limited = descriptor
        limited.fetchLimit = 1
        return try context.fetch(limited).first
    }

    internal func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let year = comps.year ?? 1970
        let month = comps.month ?? 1
        let day = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
