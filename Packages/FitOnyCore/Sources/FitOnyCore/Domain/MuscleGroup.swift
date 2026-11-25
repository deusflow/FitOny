import Foundation

public enum MovementVector: String, Codable, Sendable, CaseIterable {
    case upperPush
    case upperPull
    case lowerBody
    case trunk
}

/// 14 целевых мышечных групп и пучков для дробного учёта недельного объёма.
public enum MuscleGroup: String, Codable, Sendable, CaseIterable, Hashable {
    case chest
    case lats
    case upperBack
    case frontDelt
    case sideDelt
    case rearDelt
    case biceps
    case triceps
    case quads
    case hamstrings
    case glutes
    case calves
    case spinalErectors
    case abs

    public var displayNameRu: String {
        switch self {
        case .chest: "Грудь"
        case .lats: "Широчайшие"
        case .upperBack: "Верх спины и трапеции"
        case .frontDelt: "Передняя дельта"
        case .sideDelt: "Средняя дельта"
        case .rearDelt: "Задняя дельта"
        case .biceps: "Бицепс"
        case .triceps: "Трицепс"
        case .quads: "Квадрицепс"
        case .hamstrings: "Бицепс бедра"
        case .glutes: "Ягодичные"
        case .calves: "Икроножные"
        case .spinalErectors: "Разгибатели спины"
        case .abs: "Пресс"
        }
    }

    public var vector: MovementVector {
        switch self {
        case .chest, .frontDelt, .sideDelt, .triceps:
            return .upperPush
        case .lats, .upperBack, .rearDelt, .biceps:
            return .upperPull
        case .quads, .hamstrings, .glutes, .calves:
            return .lowerBody
        case .spinalErectors, .abs:
            return .trunk
        }
    }

    public func defaultLandmarks(for profile: PhysiologicalProfile) -> VolumeLandmarks {
        let base: VolumeLandmarks = switch self {
        case .chest: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 20)
        case .lats: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 20)
        case .upperBack: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 22)
        case .frontDelt: VolumeLandmarks(mev: 0, mavLow: 4, mavHigh: 8, mrv: 14)
        case .sideDelt: VolumeLandmarks(mev: 8, mavLow: 12, mavHigh: 20, mrv: 26)
        case .rearDelt: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 22)
        case .biceps: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 22)
        case .triceps: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 14, mrv: 18)
        case .quads: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 15, mrv: 20)
        case .hamstrings: VolumeLandmarks(mev: 4, mavLow: 8, mavHigh: 14, mrv: 18)
        case .glutes: VolumeLandmarks(mev: 4, mavLow: 8, mavHigh: 14, mrv: 18)
        case .calves: VolumeLandmarks(mev: 6, mavLow: 10, mavHigh: 16, mrv: 22)
        case .spinalErectors: VolumeLandmarks(mev: 2, mavLow: 4, mavHigh: 8, mrv: 12)
        case .abs: VolumeLandmarks(mev: 4, mavLow: 8, mavHigh: 14, mrv: 20)
        }

        switch profile {
        case .natural:
            return base
        case .enhanced:
            return VolumeLandmarks(
                mev: base.mev,
                mavLow: (base.mavLow * 1.15).rounded(.toNearestOrAwayFromZero),
                mavHigh: (base.mavHigh * 1.25).rounded(.toNearestOrAwayFromZero),
                mrv: (base.mrv * 1.25).rounded(.toNearestOrAwayFromZero)
            )
        }
    }
}

public struct VolumeLandmarks: Codable, Sendable, Equatable {
    public var mev: Double
    public var mavLow: Double
    public var mavHigh: Double
    public var mrv: Double

    public init(mev: Double, mavLow: Double, mavHigh: Double, mrv: Double) {
        self.mev = mev
        self.mavLow = mavLow
        self.mavHigh = mavHigh
        self.mrv = mrv
    }
}
