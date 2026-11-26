import Foundation

public struct IntraSessionAdjustment: Codable, Sendable, Equatable {
    public var adjustedRemainingWeightKg: Double
    public var wasReduced: Bool
    public var reason: LocalizedCopy?

    public init(adjustedRemainingWeightKg: Double, wasReduced: Bool, reason: LocalizedCopy? = nil) {
        self.adjustedRemainingWeightKg = adjustedRemainingWeightKg
        self.wasReduced = wasReduced
        self.reason = reason
    }
}

public enum AutoregulationEngine {
    /// Внутрисессионная авторегуляция:
    /// При недоборе повторов (Shortfall) или преждевременном отказе (RIR 0 при плане >= 1)
    /// снижает вес на оставшиеся сеты текущей сессии на 5–10%, НЕ затрагивая baselineWorkingWeightKg.
    public static func evaluateAfterSet(
        completedSet: CompletedSetRecord,
        plannedRange: RepRange,
        targetRIR: Int,
        equipment: EquipmentProfile
    ) -> IntraSessionAdjustment {
        let shortfall = plannedRange.min - completedSet.completedReps

        if shortfall >= 3 {
            let reduced = roundDown(completedSet.weightKg * 0.90, equipment: equipment)
            return IntraSessionAdjustment(
                adjustedRemainingWeightKg: reduced,
                wasReduced: reduced < completedSet.weightKg,
                reason: LocalizedCopy(
                    da: "Stort rep-fald (−\(shortfall) reps) → vægt sænkes ~10% på resten af sættene.",
                    ru: "Недобор \(shortfall) повт. → снижаем вес на оставшиеся подходы на ~10%."
                )
            )
        }

        if shortfall >= 1 {
            let reduced = roundDown(completedSet.weightKg * 0.925, equipment: equipment)
            return IntraSessionAdjustment(
                adjustedRemainingWeightKg: reduced,
                wasReduced: reduced < completedSet.weightKg,
                reason: LocalizedCopy(
                    da: "Mangler \(shortfall) rep(s) → vægt justeres −5–7,5% for at holde hypertrofi-zonen.",
                    ru: "Недобор \(shortfall) повт. → снижаем вес на 5–7.5% для удержания целевого диапазона."
                )
            )
        }

        if completedSet.rir == 0 && targetRIR >= 1 {
            let reduced = roundDown(completedSet.weightKg * 0.95, equipment: equipment)
            return IntraSessionAdjustment(
                adjustedRemainingWeightKg: reduced,
                wasReduced: reduced < completedSet.weightKg,
                reason: LocalizedCopy(
                    da: "Tidlig udmattelse (RIR 0 før plan) → −5% på næste sæt for at skåne CNS.",
                    ru: "Ранний отказ (RIR 0 вместо RIR \(targetRIR)) → −5% на следующие подходы."
                )
            )
        }

        return IntraSessionAdjustment(
            adjustedRemainingWeightKg: completedSet.weightKg,
            wasReduced: false,
            reason: nil
        )
    }

    private static func roundDown(_ rawKg: Double, equipment: EquipmentProfile) -> Double {
        switch equipment {
        case let .barbell(barWeightKg, stepKg):
            guard rawKg > barWeightKg else { return barWeightKg }
            let floored = barWeightKg + floor((rawKg - barWeightKg) / stepKg) * stepKg
            return max(barWeightKg, floored)
        case let .dumbbellRack(available):
            let sorted = available.sorted()
            return sorted.last(where: { $0 <= rawKg + 0.001 }) ?? sorted.first ?? rawKg
        case let .cableStack(stepKg, microPinKg):
            let step = microPinKg ?? stepKg
            return max(0.0, floor(rawKg / step) * step)
        case let .plateLoadedMachine(stepKg), let .machine(stepKg), let .bodyweight(stepKg):
            return max(0.0, floor(rawKg / stepKg) * stepKg)
        }
    }
}
