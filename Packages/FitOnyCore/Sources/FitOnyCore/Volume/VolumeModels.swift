import Foundation

public enum VolumeZone: String, Codable, Sendable, Equatable {
    case belowMEV       // Ниже минимального эффективного объёма
    case productiveMEV  // Между MEV и нижней границей MAV (втягивающая / поддерживающий рост)
    case optimalMAV     // Целевой коридор максимальной адаптации (MAVLow ... MAVHigh)
    case approachingMRV // Выше MAVHigh, вплотную к потолку восстановления MRV
    case aboveMRV       // Перебор выше MRV — риск недовосстановления

    public var localizedName: LocalizedCopy {
        switch self {
        case .belowMEV:
            LocalizedCopy(da: "Under MEV", ru: "Ниже MEV")
        case .productiveMEV:
            LocalizedCopy(da: "MEV (Basisvækst)", ru: "Зона MEV (базовый стимул)")
        case .optimalMAV:
            LocalizedCopy(da: "Optimal MAV", ru: "Оптимум MAV")
        case .approachingMRV:
            LocalizedCopy(da: "Tæt på MRV", ru: "Близко к потолку MRV")
        case .aboveMRV:
            LocalizedCopy(da: "Over MRV (Risiko)", ru: "Перебор выше MRV")
        }
    }
}

public struct MuscleVolumeSummary: Codable, Sendable, Equatable {
    public var muscle: MuscleGroup
    public var directSets: Double
    public var indirectSets: Double
    public var effectiveWeeklySets: Double
    public var landmarks: VolumeLandmarks
    public var zone: VolumeZone

    public init(
        muscle: MuscleGroup,
        directSets: Double = 0,
        indirectSets: Double = 0,
        effectiveWeeklySets: Double,
        landmarks: VolumeLandmarks
    ) {
        self.muscle = muscle
        self.directSets = directSets
        self.indirectSets = indirectSets
        self.effectiveWeeklySets = effectiveWeeklySets
        self.landmarks = landmarks

        if effectiveWeeklySets < landmarks.mev {
            self.zone = .belowMEV
        } else if effectiveWeeklySets < landmarks.mavLow {
            self.zone = .productiveMEV
        } else if effectiveWeeklySets <= landmarks.mavHigh {
            self.zone = .optimalMAV
        } else if effectiveWeeklySets <= landmarks.mrv {
            self.zone = .approachingMRV
        } else {
            self.zone = .aboveMRV
        }
    }
}

public struct PushPullBalance: Codable, Sendable, Equatable {
    public var pushVolumeSets: Double
    public var pullVolumeSets: Double
    public var ratio: Double
    public var isPushOverloaded: Bool
    public var advisoryMessage: LocalizedCopy?

    public init(
        pushVolumeSets: Double,
        pullVolumeSets: Double,
        maxHealthyPushToPullRatio: Double = 1.25
    ) {
        self.pushVolumeSets = pushVolumeSets
        self.pullVolumeSets = pullVolumeSets

        if pullVolumeSets <= 0.001 {
            self.ratio = pushVolumeSets > 0 ? 9.99 : 1.0
        } else {
            self.ratio = ((pushVolumeSets / pullVolumeSets) * 100.0).rounded() / 100.0
        }

        self.isPushOverloaded = pushVolumeSets >= 4.0 && self.ratio > maxHealthyPushToPullRatio

        if self.isPushOverloaded {
            self.advisoryMessage = LocalizedCopy(
                da: "Skub/træk-forhold er \(self.ratio): overvægt af pres øger belastningen på forsiden af skulderen. Tilføj mere ryg/bageste skulder.",
                ru: "Баланс жимов к тягам \(self.ratio): перекос в жимы нагружает плечевые суставы. Добавь объём на верх спины и заднюю дельту."
            )
        } else {
            self.advisoryMessage = nil
        }
    }
}

public struct WeeklyVolumeReport: Codable, Sendable, Equatable {
    public var summariesByMuscle: [MuscleGroup: MuscleVolumeSummary]
    public var orderedSummaries: [MuscleVolumeSummary]
    public var pushPullBalance: PushPullBalance

    public init(
        summariesByMuscle: [MuscleGroup: MuscleVolumeSummary],
        orderedSummaries: [MuscleVolumeSummary],
        pushPullBalance: PushPullBalance
    ) {
        self.summariesByMuscle = summariesByMuscle
        self.orderedSummaries = orderedSummaries
        self.pushPullBalance = pushPullBalance
    }
}
