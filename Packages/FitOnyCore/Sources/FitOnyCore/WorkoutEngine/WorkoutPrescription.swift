import Foundation

public struct WarmupSetStep: Codable, Sendable, Equatable {
    public var weightKg: Double
    public var targetReps: Int

    public init(weightKg: Double, targetReps: Int) {
        self.weightKg = weightKg
        self.targetReps = targetReps
    }
}

public struct BarbellPlateLoadout: Codable, Sendable, Equatable {
    public var barWeightKg: Double
    public var platesPerSideKg: [Double]

    public init(barWeightKg: Double, platesPerSideKg: [Double]) {
        self.barWeightKg = barWeightKg
        self.platesPerSideKg = platesPerSideKg
    }
}
