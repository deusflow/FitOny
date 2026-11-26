import Foundation

public struct RestHeartRateDecision: Codable, Sendable, Equatable {
    public var hrr60DropBPM: Int?
    public var shouldSuggestExtraRest: Bool
    public var suggestedExtraSeconds: Int
    public var prompt: LocalizedCopy?

    public init(
        hrr60DropBPM: Int?,
        shouldSuggestExtraRest: Bool,
        suggestedExtraSeconds: Int,
        prompt: LocalizedCopy? = nil
    ) {
        self.hrr60DropBPM = hrr60DropBPM
        self.shouldSuggestExtraRest = shouldSuggestExtraRest
        self.suggestedExtraSeconds = suggestedExtraSeconds
        self.prompt = prompt
    }
}

public enum HeartRateRecoveryEngine {
    /// Оценивает восстановление пульса между подходами (HRR) к моменту окончания базового таймера отдыха.
    /// Для тяжёлых многосуставных упражнений при высоком пульсе предлагает добавить +30 секунд отдыха.
    public static func evaluateAtEndOfRest(
        currentHeartRateBPM: Int,
        peakSetHeartRateBPM: Int? = nil,
        heartRateAt60sRestBPM: Int? = nil,
        restingHeartRateBPM: Int = 60,
        estimatedMaxHeartRateBPM: Int = 190,
        isCompoundExercise: Bool
    ) -> RestHeartRateDecision {
        let hrr60: Int?
        if let peak = peakSetHeartRateBPM, let hr60 = heartRateAt60sRestBPM {
            hrr60 = max(0, peak - hr60)
        } else {
            hrr60 = nil
        }

        // Порог готовности к следующему базовому подходу по резерву ЧСС Карвонена (~60% резерва, но не ниже RHR + 52 уд/мин).
        let heartRateReserve = max(80, estimatedMaxHeartRateBPM - restingHeartRateBPM)
        let thresholdBPM = max(restingHeartRateBPM + 52, restingHeartRateBPM + Int((Double(heartRateReserve) * 0.60).rounded()))

        guard isCompoundExercise, currentHeartRateBPM > thresholdBPM else {
            return RestHeartRateDecision(
                hrr60DropBPM: hrr60,
                shouldSuggestExtraRest: false,
                suggestedExtraSeconds: 0,
                prompt: nil
            )
        }

        return RestHeartRateDecision(
            hrr60DropBPM: hrr60,
            shouldSuggestExtraRest: true,
            suggestedExtraSeconds: 30,
            prompt: LocalizedCopy(
                da: "Pulsen er stadig \(currentHeartRateBPM) bpm — tilføj +30 sek. pause før næste tunge sæt?",
                ru: "Пульс ещё \(currentHeartRateBPM) уд/мин — добавить +30 сек отдыха перед тяжёлым подходом?"
            )
        )
    }
}
