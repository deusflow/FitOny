import Foundation

public enum VolumeZone: String, Codable, Sendable, Equatable {
    case belowMEV
    case optimalMAV
    case approachingMRV
    case aboveMRV
}

public struct MuscleVolumeSummary: Codable, Sendable, Equatable {
    public var muscle: MuscleGroup
    public var effectiveWeeklySets: Double
    public var landmarks: VolumeLandmarks
    public var zone: VolumeZone

    public init(muscle: MuscleGroup, effectiveWeeklySets: Double, landmarks: VolumeLandmarks) {
        self.muscle = muscle
        self.effectiveWeeklySets = effectiveWeeklySets
        self.landmarks = landmarks
        if effectiveWeeklySets < landmarks.mev {
            self.zone = .belowMEV
        } else if effectiveWeeklySets <= landmarks.mavHigh {
            self.zone = .optimalMAV
        } else if effectiveWeeklySets <= landmarks.mrv {
            self.zone = .approachingMRV
        } else {
            self.zone = .aboveMRV
        }
    }
}
