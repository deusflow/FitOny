import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("Readiness Engine & Wrist IMU Motion Tests")
struct ReadinessAndMotionTests {
    @Test("28-day baseline readiness rewards recovery and flags illness spike without altering weights")
    func readinessScoringAndIllness() {
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        let history = (1...14).map { dayOffset in
            NightBiometrics(
                date: baseDate.addingTimeInterval(Double(-dayOffset) * 86400),
                nocturnalHRVms: 70.0 + Double(dayOffset % 4) * 3.0,
                restingHeartRateBPM: 52.0 + Double(dayOffset % 3),
                sleepDurationMinutes: 460,
                deepAndREMMinutes: 170,
                wristTemperatureCelsius: 36.4,
                respiratoryRateBrPM: 14.5
            )
        }

        let greatNight = NightBiometrics(
            date: baseDate,
            nocturnalHRVms: 88.0,
            restingHeartRateBPM: 50.0,
            sleepDurationMinutes: 495,
            deepAndREMMinutes: 190,
            wristTemperatureCelsius: 36.4,
            respiratoryRateBrPM: 14.3
        )
        let peakSnapshot = ReadinessEngine.evaluate(
            today: greatNight,
            historyLast28Days: history,
            checkIn: MorningCheckIn(energyRating: 5, sorenessRating: 1, stressRating: 1, recordedAt: baseDate)
        )
        #expect(peakSnapshot.score >= 85)
        #expect(peakSnapshot.zone == .peak)
        #expect(!peakSnapshot.isSuspectedIllness)

        let feverNight = NightBiometrics(
            date: baseDate,
            nocturnalHRVms: 38.0,
            restingHeartRateBPM: 63.0,
            sleepDurationMinutes: 390,
            wristTemperatureCelsius: 37.2,
            respiratoryRateBrPM: 17.5
        )
        let illnessSnapshot = ReadinessEngine.evaluate(
            today: feverNight,
            historyLast28Days: history
        )
        #expect(illnessSnapshot.isSuspectedIllness)
        #expect(illnessSnapshot.score <= 35)
    }

    @Test("Unplanned deload triggers after 3 of 4 strained days")
    func unplannedDeloadTrigger() {
        let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
        var history = (4...20).map { dayOffset in
            NightBiometrics(
                date: baseDate.addingTimeInterval(Double(-dayOffset) * 86400),
                nocturnalHRVms: 75.0,
                restingHeartRateBPM: 52.0,
                sleepDurationMinutes: 460
            )
        }
        // Последние 3 дня: резкая просадка HRV и рост RHR
        for dayOffset in [3, 2, 1] {
            history.append(
                NightBiometrics(
                    date: baseDate.addingTimeInterval(Double(-dayOffset) * 86400),
                    nocturnalHRVms: 48.0,
                    restingHeartRateBPM: 61.0,
                    sleepDurationMinutes: 430
                )
            )
        }

        let todayStrained = NightBiometrics(
            date: baseDate,
            nocturnalHRVms: 46.0,
            restingHeartRateBPM: 62.0,
            sleepDurationMinutes: 420
        )

        let snap = ReadinessEngine.evaluate(today: todayStrained, historyLast28Days: history)
        #expect(snap.shouldSuggestUnplannedDeload)
    }

    @Test("Motion analyzer detects reps and concentric slowdown, and stays disabled on leg machines")
    func wristRepAndSlowdown() {
        let samples = Self.synthesizeCurlSet(repConcentricDurations: [0.8, 0.8, 0.85, 0.9, 1.0, 1.15, 1.4, 1.65])

        let suggestion = RepMotionAnalyzer.analyze(samples: samples, motionProfile: .arcWristPath)
        #expect(suggestion != nil)
        #expect(suggestion?.detectedReps == 8)
        #expect((suggestion?.concentricSlowdownPercent ?? 0) >= 45.0)

        let disabledOnLegPress = RepMotionAnalyzer.analyze(samples: samples, motionProfile: .stationaryWrist)
        #expect(disabledOnLegPress == nil)
    }

    static func synthesizeCurlSet(repConcentricDurations: [TimeInterval]) -> [IMUSample] {
        var result: [IMUSample] = []
        let dt = 0.02
        var t = 0.0

        // 1.4 сек съём/установка перед 1-м повторением
        while t < 1.4 {
            result.append(IMUSample(timestamp: t, verticalUserAccelerationG: t < 0.4 ? 0.3 : 0.0))
            t += dt
        }

        for concDuration in repConcentricDurations {
            // Негативная фаза (2.0 сек): мягкий спуск
            let eccDuration = 2.0
            let eccSteps = Int(eccDuration / dt)
            for step in 0..<eccSteps {
                let phase = Double(step) / Double(eccSteps)
                let accel = -0.14 * sin(phase * .pi)
                result.append(IMUSample(timestamp: t, verticalUserAccelerationG: accel))
                t += dt
            }
            // Пауза внизу 0.5 сек
            for _ in 0..<25 {
                result.append(IMUSample(timestamp: t, verticalUserAccelerationG: 0.0))
                t += dt
            }
            // Концентрическая фаза (подъём): положительный импульс, затем торможение
            let concSteps = Int(concDuration / dt)
            for step in 0..<concSteps {
                let phase = Double(step) / Double(concSteps)
                let accel = 0.32 * sin(phase * .pi)
                result.append(IMUSample(timestamp: t, verticalUserAccelerationG: accel))
                t += dt
            }
            // Пауза наверху 0.6 сек для затухания
            for _ in 0..<30 {
                result.append(IMUSample(timestamp: t, verticalUserAccelerationG: -0.04))
                t += dt
            }
        }

        return result
    }
}
#endif
