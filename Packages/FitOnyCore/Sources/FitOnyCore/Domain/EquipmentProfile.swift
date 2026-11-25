import Foundation

/// Реальный профиль шага весов оборудования зала, исключающий несуществующие номиналы.
public enum EquipmentProfile: Codable, Sendable, Equatable, Hashable {
    case barbell(barWeightKg: Double = 20.0, stepKg: Double = 2.5)
    case dumbbellRack(availableWeightsKg: [Double] = Self.standardCommercialGymDumbbells)
    case cableStack(stepKg: Double = 2.5, microPinKg: Double? = 1.25)
    case machine(stepKg: Double = 2.5)
    case bodyweight(addedWeightStepKg: Double = 2.5)

    /// Стандартный коммерческий ряд гантелей (1–10 кг с шагом 1 кг, далее шаг 2 кг до 50 кг).
    public static let standardCommercialGymDumbbells: [Double] = {
        let light = stride(from: 1.0, through: 10.0, by: 1.0).map { $0 }
        let heavy = stride(from: 12.0, through: 50.0, by: 2.0).map { $0 }
        return light + heavy
    }()

    public func roundToAvailable(_ rawWeightKg: Double) -> Double {
        let clamped = max(0.0, rawWeightKg)
        switch self {
        case let .barbell(barWeightKg, stepKg):
            guard clamped > barWeightKg else { return barWeightKg }
            let load = clamped - barWeightKg
            return barWeightKg + (load / stepKg).rounded() * stepKg

        case let .dumbbellRack(available):
            guard let nearest = available.min(by: { abs($0 - clamped) < abs($1 - clamped) }) else {
                return clamped
            }
            return nearest

        case let .cableStack(stepKg, microPinKg):
            let effectiveStep = microPinKg ?? stepKg
            return (clamped / effectiveStep).rounded() * effectiveStep

        case let .machine(stepKg), let .bodyweight(stepKg):
            return (clamped / stepKg).rounded() * stepKg
        }
    }

    public func nextStepUp(from currentWeightKg: Double) -> Double {
        switch self {
        case let .barbell(barWeightKg, stepKg):
            return max(barWeightKg, currentWeightKg) + stepKg
        case let .dumbbellRack(available):
            let sorted = available.sorted()
            if let next = sorted.first(where: { $0 > currentWeightKg + 0.001 }) {
                return next
            }
            return currentWeightKg + 2.0
        case let .cableStack(stepKg, microPinKg):
            return currentWeightKg + (microPinKg ?? stepKg)
        case let .machine(stepKg), let .bodyweight(stepKg):
            return currentWeightKg + stepKg
        }
    }
}
