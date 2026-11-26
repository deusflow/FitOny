import Foundation

public enum EquipmentVariant: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
    case primary
    case alternative
}

public struct ExerciseEquipmentKey: Codable, Sendable, Equatable, Hashable {
    public var exerciseID: UUID
    public var variant: EquipmentVariant

    public init(exerciseID: UUID, variant: EquipmentVariant = .primary) {
        self.exerciseID = exerciseID
        self.variant = variant
    }
}

/// Реальный профиль шага весов оборудования зала (плиты стека vs живой вес / блины / гантели).
public enum EquipmentProfile: Codable, Sendable, Equatable, Hashable {
    case barbell(barWeightKg: Double = 20.0, stepKg: Double = 2.5)
    case dumbbellRack(availableWeightsKg: [Double] = Self.standardCommercialGymDumbbells)
    case plateLoadedMachine(stepKg: Double = 2.5)
    case cableStack(stepKg: Double = 2.5, microPinKg: Double? = 1.25)
    case machine(stepKg: Double = 2.5)
    case bodyweight(addedWeightStepKg: Double = 2.5)

    /// Стандартный коммерческий ряд гантелей (1–10 кг с шагом 1 кг, далее шаг 2 кг до 50 кг на одну руку).
    public static let standardCommercialGymDumbbells: [Double] = {
        let light = stride(from: 1.0, through: 10.0, by: 1.0).map { $0 }
        let heavy = stride(from: 12.0, through: 50.0, by: 2.0).map { $0 }
        return light + heavy
    }()

    /// Подсказка способа ввода веса, чтобы не путать вес одной гантели, общий вес штанги/блинов и плитки стека.
    public var loadEntryHint: LocalizedCopy {
        switch self {
        case .dumbbellRack:
            LocalizedCopy(da: "pr. håndvægt", ru: "за 1 гантель")
        case .barbell:
            LocalizedCopy(da: "inkl. stang (begge hænder)", ru: "общий вес с грифом")
        case .plateLoadedMachine:
            LocalizedCopy(da: "samlet skivevægt", ru: "общий вес блинов")
        case .cableStack:
            LocalizedCopy(da: "kabelstabel", ru: "плитки кроссовера")
        case .machine:
            LocalizedCopy(da: "maskinstabel", ru: "плитки тренажёра")
        case .bodyweight:
            LocalizedCopy(da: "ekstra vægt", ru: "доп. вес")
        }
    }

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

        case let .plateLoadedMachine(stepKg), let .machine(stepKg), let .bodyweight(stepKg):
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
        case let .plateLoadedMachine(stepKg), let .machine(stepKg), let .bodyweight(stepKg):
            return currentWeightKg + stepKg
        }
    }
}
