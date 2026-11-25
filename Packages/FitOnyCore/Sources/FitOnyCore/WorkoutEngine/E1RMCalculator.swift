import Foundation

public enum E1RMCalculator {
    /// Расчётный максимум 1ПМ с поправкой на фактический RIR (эффективные повторения = reps + rir).
    /// Для >15 эффективных повторений возвращает nil, чтобы памповые сеты не искажали силовые рекорды.
    public static func estimate(weightKg: Double, reps: Int, rir: Int) -> Double? {
        guard weightKg > 0, reps >= 1 else { return nil }
        let effectiveReps = reps + max(0, rir)
        guard effectiveReps <= 15 else { return nil }

        if effectiveReps == 1 {
            return weightKg
        }

        let r = Double(effectiveReps)
        let epley = weightKg * (1.0 + r / 30.0)

        if effectiveReps <= 10 {
            let brzycki = weightKg * (36.0 / (37.0 - r))
            return ((epley + brzycki) / 2.0 * 10.0).rounded() / 10.0
        }

        return (epley * 10.0).rounded() / 10.0
    }
}
