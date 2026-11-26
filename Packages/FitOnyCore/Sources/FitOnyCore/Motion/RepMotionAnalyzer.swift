import Foundation

public enum RepMotionAnalyzer {
    /// Анализирует поток вертикального ускорения запястья (обычно 50 Гц) внутри одного рабочего подхода.
    /// - На тренажёрах с неподвижными руками (`.stationaryWrist`: жим ногами, сгибания/разгибания ног, икры)
    ///   сразу возвращает `nil`, чтобы не сбивать пользователя ложными нулями.
    /// - Вместо шумного интегрирования в м/с измеряет длительность концентрической фазы каждого повтора
    ///   и падение скорости в конце подхода (рост времени подъёма в % от лучших начальных повторов).
    public static func analyze(
        samples: [IMUSample],
        motionProfile: MotionTrackingProfile,
        ignoreInitialSeconds: TimeInterval = 1.2
    ) -> SensorRepSuggestion? {
        guard motionProfile.supportsWristSensor else { return nil }
        guard let firstTime = samples.first?.timestamp, samples.count >= 25 else { return nil }

        let activeSamples = samples.filter { $0.timestamp - firstTime >= ignoreInitialSeconds }
        guard activeSamples.count >= 20 else { return nil }

        // 1. Низкочастотное сглаживание (EMA) + интегратор с утечкой для выделения фаз без накопления дрейфа
        var smoothedAccel = 0.0
        var velocityProxy = 0.0
        var previousTime = activeSamples[0].timestamp

        var velocityTimeline: [(t: TimeInterval, v: Double)] = []
        velocityTimeline.reserveCapacity(activeSamples.count)

        for sample in activeSamples {
            let dt = max(0.005, min(0.1, sample.timestamp - previousTime))
            previousTime = sample.timestamp

            smoothedAccel = smoothedAccel * 0.72 + sample.verticalUserAccelerationG * 0.28
            let leak = exp(-dt / 0.45)
            velocityProxy = velocityProxy * leak + smoothedAccel * dt
            velocityTimeline.append((sample.timestamp, velocityProxy))
        }

        // 2. Пороги гистерезиса для выделения концентрических (подъёмных) импульсов
        let startThreshold = 0.022
        let endThreshold = 0.010
        let minConcentricDuration: TimeInterval = 0.28
        let maxConcentricDuration: TimeInterval = 4.2
        let minPeakAmplitude = 0.032
        let minRepGap: TimeInterval = 0.65

        var concentricDurations: [TimeInterval] = []
        var inConcentric = false
        var pulseStartTime: TimeInterval = 0
        var pulsePeak = 0.0
        var lastRepEndTime: TimeInterval = -.infinity

        for point in velocityTimeline {
            if !inConcentric {
                if point.v >= startThreshold && (point.t - lastRepEndTime) >= minRepGap {
                    inConcentric = true
                    pulseStartTime = point.t
                    pulsePeak = point.v
                }
            } else {
                pulsePeak = max(pulsePeak, point.v)
                if point.v <= endThreshold {
                    let duration = point.t - pulseStartTime
                    if duration >= minConcentricDuration &&
                        duration <= maxConcentricDuration &&
                        pulsePeak >= minPeakAmplitude {
                        concentricDurations.append(duration)
                        lastRepEndTime = point.t
                    }
                    inConcentric = false
                    pulsePeak = 0.0
                }
            }
        }

        // Если атлет нажал «Подход выполнен» сразу в верхней точке последнего повтора до полного затухания импульса
        if inConcentric, let lastTimestamp = velocityTimeline.last?.t {
            let duration = lastTimestamp - pulseStartTime
            if duration >= minConcentricDuration &&
                duration <= maxConcentricDuration &&
                pulsePeak >= minPeakAmplitude {
                concentricDurations.append(duration)
            }
        }

        guard !concentricDurations.isEmpty else { return nil }

        let slowdownPercent: Double
        if concentricDurations.count >= 3 {
            let baselineDuration = min(concentricDurations[0], concentricDurations[1])
            let finalDuration = concentricDurations.last!
            let rawPct = ((finalDuration - baselineDuration) / max(0.2, baselineDuration)) * 100.0
            slowdownPercent = (max(0.0, rawPct) * 10.0).rounded() / 10.0
        } else {
            slowdownPercent = 0.0
        }

        return SensorRepSuggestion(
            detectedReps: concentricDurations.count,
            concentricSlowdownPercent: slowdownPercent
        )
    }
}
