import Foundation
import SwiftData
import FitOnyCore

/// Первая версионированная схема локальной базы данных FitOny (SwiftData).
public enum FitOnySchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            SDUserPreferences.self,
            SDExerciseRecord.self,
            SDProgramRecord.self,
            SDExerciseLoadStateRecord.self,
            SDWorkoutSessionRecord.self,
            SDCompletedSetRecord.self,
            SDNightBiometricsRecord.self,
            SDMorningCheckInRecord.self,
            SDSlotVariantPreference.self
        ]
    }

    @Model
    public final class SDUserPreferences {
        @Attribute(.unique) public var key: String
        public var physiologicalProfileRaw: String
        public var activePhaseRaw: String
        public var activeProgramID: UUID?
        public var currentMesocycleWeek: Int
        public var totalMesocycleWeeks: Int
        public var lastCompletedModuleCode: String?
        public var selectedThemeRaw: String
        public var primaryLanguageRaw: String
        public var showSecondaryRussianHint: Bool
        public var autoDarkInEveningOrWorkout: Bool
        public var didSeedBuiltInCatalog: Bool
        public var updatedAt: Date

        public init(
            key: String = AthletePreferencesSnapshot.defaultKey,
            physiologicalProfileRaw: String = PhysiologicalProfile.natural.rawValue,
            activePhaseRaw: String = MacrocyclePhase.hypertrophy.rawValue,
            activeProgramID: UUID? = nil,
            currentMesocycleWeek: Int = 1,
            totalMesocycleWeeks: Int = 6,
            lastCompletedModuleCode: String? = nil,
            selectedThemeRaw: String = "fitOnyPink",
            primaryLanguageRaw: String = AppLanguage.da.rawValue,
            showSecondaryRussianHint: Bool = true,
            autoDarkInEveningOrWorkout: Bool = true,
            didSeedBuiltInCatalog: Bool = false,
            updatedAt: Date = .now
        ) {
            self.key = key
            self.physiologicalProfileRaw = physiologicalProfileRaw
            self.activePhaseRaw = activePhaseRaw
            self.activeProgramID = activeProgramID
            self.currentMesocycleWeek = currentMesocycleWeek
            self.totalMesocycleWeeks = totalMesocycleWeeks
            self.lastCompletedModuleCode = lastCompletedModuleCode
            self.selectedThemeRaw = selectedThemeRaw
            self.primaryLanguageRaw = primaryLanguageRaw
            self.showSecondaryRussianHint = showSecondaryRussianHint
            self.autoDarkInEveningOrWorkout = autoDarkInEveningOrWorkout
            self.didSeedBuiltInCatalog = didSeedBuiltInCatalog
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class SDExerciseRecord {
        @Attribute(.unique) public var id: UUID
        public var code: String
        public var isCustom: Bool
        public var isCompound: Bool
        public var payloadJSON: Data
        public var updatedAt: Date

        public init(
            id: UUID,
            code: String,
            isCustom: Bool,
            isCompound: Bool,
            payloadJSON: Data,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.code = code
            self.isCustom = isCustom
            self.isCompound = isCompound
            self.payloadJSON = payloadJSON
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class SDProgramRecord {
        @Attribute(.unique) public var id: UUID
        public var slug: String
        public var isCustom: Bool
        public var recommendedDaysPerWeek: Int
        public var defaultMesocycleWeeks: Int
        public var payloadJSON: Data
        public var updatedAt: Date

        public init(
            id: UUID,
            slug: String,
            isCustom: Bool,
            recommendedDaysPerWeek: Int,
            defaultMesocycleWeeks: Int,
            payloadJSON: Data,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.slug = slug
            self.isCustom = isCustom
            self.recommendedDaysPerWeek = recommendedDaysPerWeek
            self.defaultMesocycleWeeks = defaultMesocycleWeeks
            self.payloadJSON = payloadJSON
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class SDExerciseLoadStateRecord {
        @Attribute(.unique) public var compositeKey: String
        public var exerciseID: UUID
        public var equipmentVariantRaw: String
        public var baselineWorkingWeightKg: Double
        public var sessionTargetWeightKg: Double
        public var updatedAt: Date

        public init(
            compositeKey: String,
            exerciseID: UUID,
            equipmentVariantRaw: String,
            baselineWorkingWeightKg: Double,
            sessionTargetWeightKg: Double,
            updatedAt: Date = .now
        ) {
            self.compositeKey = compositeKey
            self.exerciseID = exerciseID
            self.equipmentVariantRaw = equipmentVariantRaw
            self.baselineWorkingWeightKg = baselineWorkingWeightKg
            self.sessionTargetWeightKg = sessionTargetWeightKg
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class SDWorkoutSessionRecord {
        @Attribute(.unique) public var id: UUID
        public var programID: UUID
        public var moduleCode: String
        public var moduleTitleJSON: Data
        public var weekNumber: Int
        public var weekRoleRaw: String
        public var phaseRaw: String
        public var startedAt: Date
        public var finishedAt: Date?
        public var isCompleted: Bool
        public var notes: String?

        public init(
            id: UUID,
            programID: UUID,
            moduleCode: String,
            moduleTitleJSON: Data,
            weekNumber: Int,
            weekRoleRaw: String,
            phaseRaw: String,
            startedAt: Date,
            finishedAt: Date? = nil,
            isCompleted: Bool = false,
            notes: String? = nil
        ) {
            self.id = id
            self.programID = programID
            self.moduleCode = moduleCode
            self.moduleTitleJSON = moduleTitleJSON
            self.weekNumber = weekNumber
            self.weekRoleRaw = weekRoleRaw
            self.phaseRaw = phaseRaw
            self.startedAt = startedAt
            self.finishedAt = finishedAt
            self.isCompleted = isCompleted
            self.notes = notes
        }
    }

    @Model
    public final class SDCompletedSetRecord {
        @Attribute(.unique) public var id: UUID
        public var sessionID: UUID
        public var exerciseID: UUID
        public var equipmentVariantRaw: String
        public var setIndex: Int
        public var isWarmup: Bool
        public var isDropStep: Bool
        public var weightKg: Double
        public var completedReps: Int
        public var leftSideReps: Int?
        public var rightSideReps: Int?
        public var rir: Int
        public var peakHeartRate: Int?
        public var hrr60Drop: Int?
        public var concentricSlowdownPercent: Double?
        public var completedAt: Date

        public init(
            id: UUID,
            sessionID: UUID,
            exerciseID: UUID,
            equipmentVariantRaw: String,
            setIndex: Int,
            isWarmup: Bool,
            isDropStep: Bool,
            weightKg: Double,
            completedReps: Int,
            leftSideReps: Int? = nil,
            rightSideReps: Int? = nil,
            rir: Int,
            peakHeartRate: Int? = nil,
            hrr60Drop: Int? = nil,
            concentricSlowdownPercent: Double? = nil,
            completedAt: Date
        ) {
            self.id = id
            self.sessionID = sessionID
            self.exerciseID = exerciseID
            self.equipmentVariantRaw = equipmentVariantRaw
            self.setIndex = setIndex
            self.isWarmup = isWarmup
            self.isDropStep = isDropStep
            self.weightKg = weightKg
            self.completedReps = completedReps
            self.leftSideReps = leftSideReps
            self.rightSideReps = rightSideReps
            self.rir = rir
            self.peakHeartRate = peakHeartRate
            self.hrr60Drop = hrr60Drop
            self.concentricSlowdownPercent = concentricSlowdownPercent
            self.completedAt = completedAt
        }
    }

    @Model
    public final class SDNightBiometricsRecord {
        @Attribute(.unique) public var dayKey: String
        public var date: Date
        public var nocturnalHRVms: Double?
        public var restingHeartRateBPM: Double?
        public var sleepDurationMinutes: Int?
        public var deepAndREMMinutes: Int?
        public var wristTemperatureCelsius: Double?
        public var respiratoryRateBrPM: Double?

        public init(
            dayKey: String,
            date: Date,
            nocturnalHRVms: Double? = nil,
            restingHeartRateBPM: Double? = nil,
            sleepDurationMinutes: Int? = nil,
            deepAndREMMinutes: Int? = nil,
            wristTemperatureCelsius: Double? = nil,
            respiratoryRateBrPM: Double? = nil
        ) {
            self.dayKey = dayKey
            self.date = date
            self.nocturnalHRVms = nocturnalHRVms
            self.restingHeartRateBPM = restingHeartRateBPM
            self.sleepDurationMinutes = sleepDurationMinutes
            self.deepAndREMMinutes = deepAndREMMinutes
            self.wristTemperatureCelsius = wristTemperatureCelsius
            self.respiratoryRateBrPM = respiratoryRateBrPM
        }
    }

    @Model
    public final class SDMorningCheckInRecord {
        @Attribute(.unique) public var dayKey: String
        public var recordedAt: Date
        public var energyRating: Int
        public var sorenessRating: Int
        public var stressRating: Int

        public init(
            dayKey: String,
            recordedAt: Date,
            energyRating: Int,
            sorenessRating: Int,
            stressRating: Int
        ) {
            self.dayKey = dayKey
            self.recordedAt = recordedAt
            self.energyRating = energyRating
            self.sorenessRating = sorenessRating
            self.stressRating = stressRating
        }
    }

    @Model
    public final class SDSlotVariantPreference {
        @Attribute(.unique) public var slotID: UUID
        public var equipmentVariantRaw: String
        public var updatedAt: Date

        public init(
            slotID: UUID,
            equipmentVariantRaw: String,
            updatedAt: Date = .now
        ) {
            self.slotID = slotID
            self.equipmentVariantRaw = equipmentVariantRaw
            self.updatedAt = updatedAt
        }
    }
}

/// План контролируемых миграций SwiftData между версиями схемы.
public enum FitOnyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [FitOnySchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

public typealias SDUserPreferences = FitOnySchemaV1.SDUserPreferences
public typealias SDExerciseRecord = FitOnySchemaV1.SDExerciseRecord
public typealias SDProgramRecord = FitOnySchemaV1.SDProgramRecord
public typealias SDExerciseLoadStateRecord = FitOnySchemaV1.SDExerciseLoadStateRecord
public typealias SDWorkoutSessionRecord = FitOnySchemaV1.SDWorkoutSessionRecord
public typealias SDCompletedSetRecord = FitOnySchemaV1.SDCompletedSetRecord
public typealias SDNightBiometricsRecord = FitOnySchemaV1.SDNightBiometricsRecord
public typealias SDMorningCheckInRecord = FitOnySchemaV1.SDMorningCheckInRecord
public typealias SDSlotVariantPreference = FitOnySchemaV1.SDSlotVariantPreference
