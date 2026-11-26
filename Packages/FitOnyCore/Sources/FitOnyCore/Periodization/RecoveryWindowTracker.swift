import Foundation

public struct MuscleRecoveryStatus: Codable, Sendable, Equatable {
    public var muscle: MuscleGroup
    public var isRecoveringFromDirectWork: Bool
    public var hoursSinceLastDirectWork: Double?
    public var remainingCooldownHours: Double
    public var readyAt: Date?

    public init(
        muscle: MuscleGroup,
        isRecoveringFromDirectWork: Bool,
        hoursSinceLastDirectWork: Double?,
        remainingCooldownHours: Double,
        readyAt: Date?
    ) {
        self.muscle = muscle
        self.isRecoveringFromDirectWork = isRecoveringFromDirectWork
        self.hoursSinceLastDirectWork = hoursSinceLastDirectWork
        self.remainingCooldownHours = remainingCooldownHours
        self.readyAt = readyAt
    }
}

public enum SlotAdaptationKind: String, Codable, Sendable, Equatable {
    case keepAsPlanned
    case includeOptionalBonus
    case skipOptionalOrGated
    case swapExercise
    case suggestHeavyAlternative
}

public struct SlotAdaptationAdvice: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var slotID: UUID
    public var originalExerciseID: UUID
    public var recommendedExerciseID: UUID
    public var recommendedScheme: SetScheme
    public var recommendedWarmup: WarmupPrescription
    public var recommendedRestSeconds: Int
    public var recommendedRIR: Int
    public var kind: SlotAdaptationKind
    public var message: LocalizedCopy?

    public init(
        id: UUID = UUID(),
        slotID: UUID,
        originalExerciseID: UUID,
        recommendedExerciseID: UUID,
        recommendedScheme: SetScheme,
        recommendedWarmup: WarmupPrescription,
        recommendedRestSeconds: Int,
        recommendedRIR: Int,
        kind: SlotAdaptationKind,
        message: LocalizedCopy? = nil
    ) {
        self.id = id
        self.slotID = slotID
        self.originalExerciseID = originalExerciseID
        self.recommendedExerciseID = recommendedExerciseID
        self.recommendedScheme = recommendedScheme
        self.recommendedWarmup = recommendedWarmup
        self.recommendedRestSeconds = recommendedRestSeconds
        self.recommendedRIR = recommendedRIR
        self.kind = kind
        self.message = message
    }
}

public struct ModuleReadinessEvaluation: Codable, Sendable, Equatable {
    public var moduleID: UUID
    public var moduleCode: String
    public var conflictingPrimaryMuscles: [MuscleGroup]
    public var isReadyForPrimaryWork: Bool
    public var suggestedAlternativeModuleCode: String?
    public var slotAdvices: [SlotAdaptationAdvice]
    public var bannerMessage: LocalizedCopy?

    public init(
        moduleID: UUID,
        moduleCode: String,
        conflictingPrimaryMuscles: [MuscleGroup],
        isReadyForPrimaryWork: Bool,
        suggestedAlternativeModuleCode: String?,
        slotAdvices: [SlotAdaptationAdvice],
        bannerMessage: LocalizedCopy?
    ) {
        self.moduleID = moduleID
        self.moduleCode = moduleCode
        self.conflictingPrimaryMuscles = conflictingPrimaryMuscles
        self.isReadyForPrimaryWork = isReadyForPrimaryWork
        self.suggestedAlternativeModuleCode = suggestedAlternativeModuleCode
        self.slotAdvices = slotAdvices
        self.bannerMessage = bannerMessage
    }
}

public enum RecoveryWindowTracker {
    /// Минимальный порог стимула за 24-часовое окно, запускающий жёсткое правило 48 ч (36 ч в Enhanced).
    /// Косвенная нагрузка 0.5–1.0 сета учитывается в объёме, но не блокирует соседние дни сплита.
    public static let directStimulusThresholdSets: Double = 1.5

    /// Оценивает статус восстановления всех 14 мышц на момент `referenceDate`.
    public static func recoveryStatuses(
        recentSets: [CompletedSetRecord],
        referenceDate: Date = .now,
        profile: PhysiologicalProfile = .natural,
        exercisesByID: [UUID: ExerciseDefinition] = ProgramCatalog.builtIn.exercisesByID
    ) -> [MuscleGroup: MuscleRecoveryStatus] {
        let requiredHours = profile.directMuscleRecoveryHours
        let lookbackStart = referenceDate.addingTimeInterval(-requiredHours * 3600.0 * 1.5)

        let filtered = recentSets.filter {
            !$0.isWarmup && $0.rir <= 4 && $0.completedAt >= lookbackStart && $0.completedAt <= referenceDate
        }
        let groupedSessions = groupSetsIntoTrainingSessions(filtered)

        var lastDirectTimestampByMuscle: [MuscleGroup: Date] = [:]

        for sessionSets in groupedSessions {
            var stimulusInSession: [MuscleGroup: Double] = [:]
            var latestInSession: [MuscleGroup: Date] = [:]

            for set in sessionSets {
                guard let exercise = exercisesByID[set.exerciseID] else { continue }
                let factor = set.isDropStep ? 0.5 : 1.0
                for (muscle, coeff) in exercise.muscleContributions where coeff >= 0.99 {
                    stimulusInSession[muscle, default: 0.0] += factor * coeff
                    if let prev = latestInSession[muscle] {
                        latestInSession[muscle] = max(prev, set.completedAt)
                    } else {
                        latestInSession[muscle] = set.completedAt
                    }
                }
            }

            for (muscle, stimulus) in stimulusInSession where stimulus >= directStimulusThresholdSets {
                if let stamp = latestInSession[muscle] {
                    if let existing = lastDirectTimestampByMuscle[muscle] {
                        lastDirectTimestampByMuscle[muscle] = max(existing, stamp)
                    } else {
                        lastDirectTimestampByMuscle[muscle] = stamp
                    }
                }
            }
        }

        var result: [MuscleGroup: MuscleRecoveryStatus] = [:]
        for muscle in MuscleGroup.allCases {
            if let lastDate = lastDirectTimestampByMuscle[muscle] {
                let elapsedHours = referenceDate.timeIntervalSince(lastDate) / 3600.0
                let remaining = max(0.0, requiredHours - elapsedHours)
                let isRecovering = remaining > 0.05
                result[muscle] = MuscleRecoveryStatus(
                    muscle: muscle,
                    isRecoveringFromDirectWork: isRecovering,
                    hoursSinceLastDirectWork: (elapsedHours * 10.0).rounded() / 10.0,
                    remainingCooldownHours: (remaining * 10.0).rounded() / 10.0,
                    readyAt: isRecovering ? lastDate.addingTimeInterval(requiredHours * 3600.0) : nil
                )
            } else {
                result[muscle] = MuscleRecoveryStatus(
                    muscle: muscle,
                    isRecoveringFromDirectWork: false,
                    hoursSinceLastDirectWork: nil,
                    remainingCooldownHours: 0.0,
                    readyAt: nil
                )
            }
        }

        return result
    }

    /// Проверяет модуль перед стартом тренировки:
    /// 1) не конфликтуют ли его главные мышцы с правилом 48 ч (и если да — какой модуль программы лучше взять взамен);
    /// 2) какие внутримодульные замены/опции срабатывают по условиям слотов (например, замена бицепса на махи в Модуле B).
    public static func evaluateModule(
        _ module: WorkoutModuleBlueprint,
        candidateModules: [WorkoutModuleBlueprint] = ProgramCatalog.builtIn.programs[0].modules,
        recentSets: [CompletedSetRecord],
        weeklySets: [CompletedSetRecord] = [],
        plannedDirectMusclesNext24h: Set<MuscleGroup> = [],
        referenceDate: Date = .now,
        profile: PhysiologicalProfile = .natural,
        exercisesByID: [UUID: ExerciseDefinition] = ProgramCatalog.builtIn.exercisesByID
    ) -> ModuleReadinessEvaluation {
        let statuses = recoveryStatuses(
            recentSets: recentSets,
            referenceDate: referenceDate,
            profile: profile,
            exercisesByID: exercisesByID
        )
        let effectiveWeeklySets = weeklySets.isEmpty ? recentSets : weeklySets
        let directTouchCounts = countDirectWeeklyTouchSessions(
            weeklySets: effectiveWeeklySets,
            exercisesByID: exercisesByID
        )

        let coreModuleMuscles = primaryRequiredMuscles(for: module, exercisesByID: exercisesByID)
        let conflicts = coreModuleMuscles.filter { statuses[$0]?.isRecoveringFromDirectWork == true }

        var suggestedAlternativeCode: String? = nil
        if !conflicts.isEmpty {
            suggestedAlternativeCode = candidateModules.first(where: { candidate in
                guard candidate.id != module.id else { return false }
                let candidateMuscles = primaryRequiredMuscles(for: candidate, exercisesByID: exercisesByID)
                return !candidateMuscles.isEmpty && candidateMuscles.allSatisfy { statuses[$0]?.isRecoveringFromDirectWork == false }
            })?.code
        }

        let slotAdvices = module.slots.map { slot in
            evaluateSlot(
                slot,
                statuses: statuses,
                directTouchCounts: directTouchCounts,
                recentSets: recentSets,
                plannedDirectMusclesNext24h: plannedDirectMusclesNext24h,
                referenceDate: referenceDate,
                profile: profile
            )
        }

        let banner: LocalizedCopy?
        if !conflicts.isEmpty {
            let daNames = conflicts.map { $0.displayName(for: .da) }.joined(separator: ", ")
            let ruNames = conflicts.map { $0.displayName(for: .ru) }.joined(separator: ", ")
            if let alt = suggestedAlternativeCode {
                banner = LocalizedCopy(
                    da: "\(daNames) restituerer stadig (< \(Int(profile.directMuscleRecoveryHours))t). Foreslået ombytning i dag: Modul \(alt).",
                    ru: "\(ruNames) ещё восстанавливается (< \(Int(profile.directMuscleRecoveryHours)) ч). Предлагаем сегодня провести Модуль \(alt)."
                )
            } else {
                banner = LocalizedCopy(
                    da: "\(daNames) restituerer stadig (< \(Int(profile.directMuscleRecoveryHours))t). Overvej en hviledag.",
                    ru: "\(ruNames) ещё восстанавливается (< \(Int(profile.directMuscleRecoveryHours)) ч). Лучше сделать день отдыха."
                )
            }
        } else {
            banner = nil
        }

        return ModuleReadinessEvaluation(
            moduleID: module.id,
            moduleCode: module.code,
            conflictingPrimaryMuscles: conflicts,
            isReadyForPrimaryWork: conflicts.isEmpty,
            suggestedAlternativeModuleCode: suggestedAlternativeCode,
            slotAdvices: slotAdvices,
            bannerMessage: banner
        )
    }

    private static func primaryRequiredMuscles(
        for module: WorkoutModuleBlueprint,
        exercisesByID: [UUID: ExerciseDefinition]
    ) -> [MuscleGroup] {
        var stimulus: [MuscleGroup: Double] = [:]
        for slot in module.slots {
            // Условные/заменяемые слоты (например, бицепс в конце дня спины B) адаптируются внутри модуля и не блокируют сам день спины.
            guard slot.condition == .required || isBiWeeklyChoice(slot.condition) else { continue }
            guard let ex = exercisesByID[slot.exerciseID] else { continue }
            for (muscle, coeff) in ex.muscleContributions where coeff >= 0.99 {
                stimulus[muscle, default: 0.0] += Double(slot.scheme.workingSetCount) * coeff
            }
        }
        return MuscleGroup.allCases.filter { stimulus[$0, default: 0.0] >= 3.0 }
    }

    private static func isBiWeeklyChoice(_ condition: SlotCondition) -> Bool {
        if case .biWeeklyChoice = condition { return true }
        return false
    }

    private static func evaluateSlot(
        _ slot: ModuleExerciseSlot,
        statuses: [MuscleGroup: MuscleRecoveryStatus],
        directTouchCounts: [MuscleGroup: Int],
        recentSets: [CompletedSetRecord],
        plannedDirectMusclesNext24h: Set<MuscleGroup>,
        referenceDate: Date,
        profile: PhysiologicalProfile
    ) -> SlotAdaptationAdvice {
        let effectiveWindow = min(profile.directMuscleRecoveryHours, 48.0)

        switch slot.condition {
        case .required:
            return keepDefault(slot)

        case let .optionalBonusIfMuscleRested(muscle, minHours, reason):
            let threshold = profile == .enhanced ? min(minHours, 36.0) : minHours
            let elapsed = statuses[muscle]?.hoursSinceLastDirectWork ?? .infinity
            let isRested = elapsed >= threshold && !plannedDirectMusclesNext24h.contains(muscle)
            if isRested {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: slot.exerciseID,
                    recommendedScheme: slot.scheme,
                    recommendedWarmup: slot.warmup,
                    recommendedRestSeconds: slot.minRestSeconds,
                    recommendedRIR: slot.targetRIR,
                    kind: .includeOptionalBonus,
                    message: reason
                )
            } else {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: slot.exerciseID,
                    recommendedScheme: slot.scheme,
                    recommendedWarmup: slot.warmup,
                    recommendedRestSeconds: slot.minRestSeconds,
                    recommendedRIR: slot.targetRIR,
                    kind: .skipOptionalOrGated,
                    message: LocalizedCopy(
                        da: "Spring valgfri øvelse over: \(muscle.displayName(for: .da)) blev trænet for nylig eller er planlagt i morgen.",
                        ru: "Пропусти опциональное упражнение: \(muscle.displayName(for: .ru)) недавно нагружался или стоит в плане на завтра."
                    )
                )
            }

        case let .gatedByMuscleRecovery(muscle, minHours, reason):
            let threshold = profile == .enhanced ? min(minHours, 36.0) : minHours
            let elapsed = statuses[muscle]?.hoursSinceLastDirectWork ?? .infinity
            if elapsed >= threshold {
                return keepDefault(slot)
            } else {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: slot.exerciseID,
                    recommendedScheme: slot.scheme,
                    recommendedWarmup: slot.warmup,
                    recommendedRestSeconds: slot.minRestSeconds,
                    recommendedRIR: slot.targetRIR,
                    kind: .skipOptionalOrGated,
                    message: reason
                )
            }

        case let .swapIfMuscleFatigued(muscle, withinHours, swapExerciseID, swapScheme, swapRestSeconds, swapRIR, reason):
            let threshold = min(withinHours, effectiveWindow)
            let elapsed = statuses[muscle]?.hoursSinceLastDirectWork ?? .infinity
            if elapsed < threshold {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: swapExerciseID,
                    recommendedScheme: swapScheme,
                    recommendedWarmup: .none,
                    recommendedRestSeconds: swapRestSeconds,
                    recommendedRIR: swapRIR,
                    kind: .swapExercise,
                    message: reason
                )
            }
            return keepDefault(slot)

        case let .biWeeklyChoice(intervalDays, altExID, altScheme, altWarmup, altRest, altRIR, reason):
            let lastAltDate = recentSets
                .filter { !$0.isWarmup && $0.exerciseID == altExID }
                .map(\.completedAt)
                .max()
            let daysSinceAlt = lastAltDate.map { referenceDate.timeIntervalSince($0) / 86400.0 } ?? .infinity

            if daysSinceAlt >= Double(intervalDays) {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: altExID,
                    recommendedScheme: altScheme,
                    recommendedWarmup: altWarmup,
                    recommendedRestSeconds: altRest,
                    recommendedRIR: altRIR,
                    kind: .suggestHeavyAlternative,
                    message: reason
                )
            }
            return keepDefault(slot)

        case let .catchUpIfDirectTouchesBelow(muscle, requiredWeeklyTouches, reason):
            let touchesDone = directTouchCounts[muscle, default: 0]
            if touchesDone < requiredWeeklyTouches {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: slot.exerciseID,
                    recommendedScheme: slot.scheme,
                    recommendedWarmup: slot.warmup,
                    recommendedRestSeconds: slot.minRestSeconds,
                    recommendedRIR: slot.targetRIR,
                    kind: .includeOptionalBonus,
                    message: reason
                )
            } else {
                return SlotAdaptationAdvice(
                    slotID: slot.id,
                    originalExerciseID: slot.exerciseID,
                    recommendedExerciseID: slot.exerciseID,
                    recommendedScheme: slot.scheme,
                    recommendedWarmup: slot.warmup,
                    recommendedRestSeconds: slot.minRestSeconds,
                    recommendedRIR: slot.targetRIR,
                    kind: .skipOptionalOrGated,
                    message: LocalizedCopy(
                        da: "Ugens \(requiredWeeklyTouches) berøringer for \(muscle.displayName(for: .da)) er allerede opfyldt — kan springes over.",
                        ru: "Целевые \(requiredWeeklyTouches) касания мышцы «\(muscle.displayName(for: .ru))» за неделю уже закрыты — слот можно пропустить."
                    )
                )
            }
        }
    }

    /// Группирует подходы в реальные тренировочные сессии (по `sessionID` и 4-часовому окну),
    /// чтобы тренировка через полночь (например, 23:35 -> 00:20) никогда не разрывалась на два разных дня.
    internal static func groupSetsIntoTrainingSessions(_ sets: [CompletedSetRecord]) -> [[CompletedSetRecord]] {
        guard !sets.isEmpty else { return [] }
        let defaultPlaceholder = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        var explicitBySession: [UUID: [CompletedSetRecord]] = [:]
        var ungrouped: [CompletedSetRecord] = []

        for set in sets {
            if set.sessionID != defaultPlaceholder {
                explicitBySession[set.sessionID, default: []].append(set)
            } else {
                ungrouped.append(set)
            }
        }

        var sessions: [[CompletedSetRecord]] = Array(explicitBySession.values)

        let sortedUngrouped = ungrouped.sorted { $0.completedAt < $1.completedAt }
        var currentCluster: [CompletedSetRecord] = []
        for set in sortedUngrouped {
            if let last = currentCluster.last, set.completedAt.timeIntervalSince(last.completedAt) <= 4.0 * 3600.0 {
                currentCluster.append(set)
            } else {
                if !currentCluster.isEmpty { sessions.append(currentCluster) }
                currentCluster = [set]
            }
        }
        if !currentCluster.isEmpty {
            sessions.append(currentCluster)
        }

        return sessions
    }

    private static func countDirectWeeklyTouchSessions(
        weeklySets: [CompletedSetRecord],
        exercisesByID: [UUID: ExerciseDefinition]
    ) -> [MuscleGroup: Int] {
        let validSets = weeklySets.filter { !$0.isWarmup && $0.rir <= 4 && $0.completedReps > 0 }
        let sessions = groupSetsIntoTrainingSessions(validSets)
        var touchCounts: [MuscleGroup: Int] = [:]

        for sessionSets in sessions {
            var stimulusInSession: [MuscleGroup: Double] = [:]
            for set in sessionSets {
                guard let ex = exercisesByID[set.exerciseID] else { continue }
                let factor = set.isDropStep ? 0.5 : 1.0
                for (muscle, coeff) in ex.muscleContributions where coeff >= 0.99 {
                    stimulusInSession[muscle, default: 0.0] += factor * coeff
                }
            }
            for (muscle, stimulus) in stimulusInSession where stimulus >= directStimulusThresholdSets {
                touchCounts[muscle, default: 0] += 1
            }
        }

        return touchCounts
    }

    private static func keepDefault(_ slot: ModuleExerciseSlot) -> SlotAdaptationAdvice {
        SlotAdaptationAdvice(
            slotID: slot.id,
            originalExerciseID: slot.exerciseID,
            recommendedExerciseID: slot.exerciseID,
            recommendedScheme: slot.scheme,
            recommendedWarmup: slot.warmup,
            recommendedRestSeconds: slot.minRestSeconds,
            recommendedRIR: slot.targetRIR,
            kind: .keepAsPlanned,
            message: nil
        )
    }
}
