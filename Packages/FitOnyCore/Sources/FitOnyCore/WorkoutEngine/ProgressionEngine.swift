import Foundation

public struct ProgressionDecision: Codable, Sendable, Equatable {
    public var nextBaselineWeightKg: Double
    public var nextSessionTargetWeightKg: Double
    public var didProgressWeight: Bool
    public var explanation: LocalizedCopy

    public init(
        nextBaselineWeightKg: Double,
        nextSessionTargetWeightKg: Double,
        didProgressWeight: Bool,
        explanation: LocalizedCopy
    ) {
        self.nextBaselineWeightKg = nextBaselineWeightKg
        self.nextSessionTargetWeightKg = nextSessionTargetWeightKg
        self.didProgressWeight = didProgressWeight
        self.explanation = explanation
    }
}

public enum ProgressionEngine {
    /// Межсессионная прогрессия (Double Progression).
    /// Базовый вес повышается только если все рабочие подходы прошлой полноценной сессии чисто закрыли верхнюю границу повторов в целевом RIR.
    public static func evaluateNextSession(
        currentLoad: ExerciseLoadState,
        completedWorkingSets: [CompletedSetRecord],
        scheme: SetScheme,
        targetRIR: Int,
        equipment: EquipmentProfile,
        phase: MacrocyclePhase = .hypertrophy,
        isDeloadWeek: Bool = false,
        previousQualifyingStreak: Int = 0
    ) -> ProgressionDecision {
        let baseline = currentLoad.baselineWorkingWeightKg

        if isDeloadWeek {
            return ProgressionDecision(
                nextBaselineWeightKg: baseline,
                nextSessionTargetWeightKg: baseline,
                didProgressWeight: false,
                explanation: LocalizedCopy(
                    da: "Deload-uge: arbejdsbelastning bevares på 100%, sæt halveres (RIR 3–4).",
                    ru: "Неделя разгрузки: рабочий вес 100%, число подходов сокращено вдвое (RIR 3–4)."
                )
            )
        }

        let workingSets = completedWorkingSets
            .filter { !$0.isWarmup && !$0.isDropStep }
            .sorted { $0.setIndex < $1.setIndex }
        let requiredCount = scheme.workingSetCount

        guard workingSets.count >= requiredCount, requiredCount > 0 else {
            return ProgressionDecision(
                nextBaselineWeightKg: baseline,
                nextSessionTargetWeightKg: baseline,
                didProgressWeight: false,
                explanation: LocalizedCopy(
                    da: "Ikke alle arbejdssæt blev fuldført — vægten fastholdes.",
                    ru: "Выполнены не все рабочие подходы — базовый вес сохраняется."
                )
            )
        }

        let allHitTopRepsAndRIR = workingSets.prefix(requiredCount).enumerated().allSatisfy { index, set in
            let range = scheme.repRange(forWorkingSetIndex: index)
            let expectedSetWeight = targetWeightForSet(
                sessionTopWeightKg: baseline,
                scheme: scheme,
                workingSetIndex: index,
                equipment: equipment
            )
            return set.weightKg >= expectedSetWeight - 0.001 &&
                set.completedReps >= range.max &&
                set.rir >= targetRIR
        }

        if allHitTopRepsAndRIR,
           let neededStreak = PeriodizationEngine.policy(for: phase).requiredQualifyingSessionsToProgress {
            let currentStreak = previousQualifyingStreak + 1
            if currentStreak < neededStreak {
                return ProgressionDecision(
                    nextBaselineWeightKg: baseline,
                    nextSessionTargetWeightKg: baseline,
                    didProgressWeight: false,
                    explanation: LocalizedCopy(
                        da: "Cut-fase: bekræft toppen af rep-området én træning mere (\(currentStreak)/\(neededStreak)), før vægten øges.",
                        ru: "Фаза сушки: закрепи верх повторений ещё на одной тренировке (\(currentStreak)/\(neededStreak)) перед повышением веса."
                    )
                )
            }

            let incremented = equipment.nextStepUp(from: baseline)
            return ProgressionDecision(
                nextBaselineWeightKg: incremented,
                nextSessionTargetWeightKg: incremented,
                didProgressWeight: true,
                explanation: LocalizedCopy(
                    da: "Alle arbejdssæt lukket rent i toppen af rep-området → +\(formatKg(incremented - baseline)) kg.",
                    ru: "Все подходы чисто закрыты по верху повторений → +\(formatKg(incremented - baseline)) кг."
                )
            )
        }

        return ProgressionDecision(
            nextBaselineWeightKg: baseline,
            nextSessionTargetWeightKg: baseline,
            didProgressWeight: false,
            explanation: LocalizedCopy(
                da: "Behold vægten (\(formatKg(baseline)) kg) og arbejd mod toppen af rep-området.",
                ru: "Оставляем вес (\(formatKg(baseline)) кг) и добираем повторения к верхней границе."
            )
        )
    }

    /// Целевой вес для конкретной ступени обратной пирамиды (или прямого сета).
    public static func targetWeightForSet(
        sessionTopWeightKg: Double,
        scheme: SetScheme,
        workingSetIndex: Int,
        equipment: EquipmentProfile
    ) -> Double {
        switch scheme {
        case .straightSets, .superset, .dropSet:
            return equipment.roundToAvailable(sessionTopWeightKg)
        case .reversePyramid:
            // Ступени: 1-2 сет = 100%, 3-4 сет = ~90%, 5+ сет = ~82.5%
            let factor: Double = switch workingSetIndex {
            case 0, 1: 1.0
            case 2, 3: 0.90
            default: 0.825
            }
            return equipment.roundToAvailable(sessionTopWeightKg * factor)
        }
    }

    private static func formatKg(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(format: "%.2g", value)
    }
}
