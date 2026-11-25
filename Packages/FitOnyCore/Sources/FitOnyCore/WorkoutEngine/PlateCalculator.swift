import Foundation

public enum PlateCalculator {
    public static let standardMetricPlatesKg: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    /// Раскладка блинов на одну сторону грифа для заданного суммарного веса.
    public static func platesPerSide(
        totalWeightKg: Double,
        barWeightKg: Double = 20.0,
        availablePlatesKg: [Double] = standardMetricPlatesKg
    ) -> BarbellPlateLoadout {
        guard totalWeightKg > barWeightKg else {
            return BarbellPlateLoadout(barWeightKg: barWeightKg, platesPerSideKg: [])
        }

        var remainingPerSide = (totalWeightKg - barWeightKg) / 2.0
        var plates: [Double] = []

        for plate in availablePlatesKg.sorted(by: >) {
            while remainingPerSide + 0.001 >= plate {
                plates.append(plate)
                remainingPerSide -= plate
            }
        }

        return BarbellPlateLoadout(barWeightKg: barWeightKg, platesPerSideKg: plates)
    }
}
