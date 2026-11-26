import Foundation
import SwiftData
import FitOnyCore

extension FitOnyStore {
    internal func ensurePreferencesRecord() throws -> SDUserPreferences {
        let defaultKey = AthletePreferencesSnapshot.defaultKey
        let descriptor = FetchDescriptor<SDUserPreferences>(
            predicate: #Predicate { $0.key == defaultKey }
        )
        if let existing = try fetchFirst(descriptor) {
            return existing
        }
        let created = SDUserPreferences(key: defaultKey)
        context.insert(created)
        try context.save()
        return created
    }

    public func fetchPreferences() throws -> AthletePreferencesSnapshot {
        let record = try ensurePreferencesRecord()
        return AthletePreferencesSnapshot(
            profile: PhysiologicalProfile(rawValue: record.physiologicalProfileRaw) ?? .natural,
            activePhase: MacrocyclePhase(rawValue: record.activePhaseRaw) ?? .hypertrophy,
            activeProgramID: record.activeProgramID,
            currentMesocycleWeek: record.currentMesocycleWeek,
            totalMesocycleWeeks: record.totalMesocycleWeeks,
            lastCompletedModuleCode: record.lastCompletedModuleCode,
            selectedThemeID: record.selectedThemeRaw,
            primaryLanguage: AppLanguage(rawValue: record.primaryLanguageRaw) ?? .da,
            showSecondaryRussianHint: record.showSecondaryRussianHint,
            autoDarkInEveningOrWorkout: record.autoDarkInEveningOrWorkout,
            didSeedBuiltInCatalog: record.didSeedBuiltInCatalog,
            updatedAt: record.updatedAt
        )
    }

    @discardableResult
    public func updatePreferences(
        _ mutate: (inout AthletePreferencesSnapshot) -> Void
    ) throws -> AthletePreferencesSnapshot {
        let record = try ensurePreferencesRecord()
        var snapshot = try fetchPreferences()
        mutate(&snapshot)
        snapshot.currentMesocycleWeek = max(1, min(6, snapshot.currentMesocycleWeek))
        snapshot.totalMesocycleWeeks = max(4, min(6, snapshot.totalMesocycleWeeks))
        snapshot.updatedAt = .now

        record.physiologicalProfileRaw = snapshot.profile.rawValue
        record.activePhaseRaw = snapshot.activePhase.rawValue
        record.activeProgramID = snapshot.activeProgramID
        record.currentMesocycleWeek = snapshot.currentMesocycleWeek
        record.totalMesocycleWeeks = snapshot.totalMesocycleWeeks
        record.lastCompletedModuleCode = snapshot.lastCompletedModuleCode
        record.selectedThemeRaw = snapshot.selectedThemeID
        record.primaryLanguageRaw = snapshot.primaryLanguage.rawValue
        record.showSecondaryRussianHint = snapshot.showSecondaryRussianHint
        record.autoDarkInEveningOrWorkout = snapshot.autoDarkInEveningOrWorkout
        record.didSeedBuiltInCatalog = snapshot.didSeedBuiltInCatalog
        record.updatedAt = snapshot.updatedAt

        try context.save()
        return snapshot
    }

    public func selectedVariantsBySlotID() throws -> [UUID: EquipmentVariant] {
        let records = try context.fetch(FetchDescriptor<SDSlotVariantPreference>())
        var result: [UUID: EquipmentVariant] = [:]
        result.reserveCapacity(records.count)
        for record in records {
            if let variant = EquipmentVariant(rawValue: record.equipmentVariantRaw) {
                result[record.slotID] = variant
            }
        }
        return result
    }

    public func setSelectedVariant(_ variant: EquipmentVariant, forSlotID slotID: UUID) throws {
        let targetSlotID = slotID
        let descriptor = FetchDescriptor<SDSlotVariantPreference>(
            predicate: #Predicate { $0.slotID == targetSlotID }
        )
        if let existing = try fetchFirst(descriptor) {
            existing.equipmentVariantRaw = variant.rawValue
            existing.updatedAt = .now
        } else {
            context.insert(
                SDSlotVariantPreference(
                    slotID: slotID,
                    equipmentVariantRaw: variant.rawValue
                )
            )
        }
        try context.save()
    }
}
