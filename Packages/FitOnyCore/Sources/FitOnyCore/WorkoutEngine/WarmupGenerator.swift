import Foundation

public enum WarmupGenerator {
    /// Рассчитывает разминочные подходы. Если основная мышца уже была нагружена в текущей сессии и разминка не обязательна — пропускает её.
    public static func generate(
        firstWorkingWeightKg: Double,
        equipment: EquipmentProfile,
        prescription: WarmupPrescription,
        alreadyTrainedPrimaryMuscleInSession: Bool = false
    ) -> [WarmupSetStep] {
        guard !alreadyTrainedPrimaryMuscleInSession else {
            return []
        }

        switch prescription {
        case .none:
            return []

        case let .single(percentage, targetReps):
            let raw = firstWorkingWeightKg * percentage
            let rounded = equipment.roundToAvailable(raw)
            guard rounded > 0 else { return [] }
            return [WarmupSetStep(weightKg: rounded, targetReps: targetReps)]

        case let .pyramid(steps):
            var result: [WarmupSetStep] = []
            for step in steps {
                let raw = firstWorkingWeightKg * step.percentage
                let rounded = equipment.roundToAvailable(raw)
                // Не дублируем идентичный вес разминки подряд и не ставим разминку тяжелее рабочего веса.
                if rounded > 0, rounded < firstWorkingWeightKg, result.last?.weightKg != rounded {
                    result.append(WarmupSetStep(weightKg: rounded, targetReps: step.reps))
                }
            }
            return result
        }
    }
}
