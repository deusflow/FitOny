import Foundation

public enum ReadinessEngine {
    private struct DistributionStats {
        let median: Double
        let scale: Double
    }

    /// Рассчитывает индекс готовности 0–100 по 28-дневному скользящему бейзлайну и утреннему чек-ину.
    /// Строго совещательный режим: никогда не меняет рабочие веса без явного выбора атлета.
    public static func evaluate(
        today: NightBiometrics,
        historyLast28Days: [NightBiometrics],
        checkIn: MorningCheckIn? = nil,
        targetSleepMinutes: Int = 450
    ) -> ReadinessSnapshot {
        let priorHistory = historyLast28Days
            .filter { $0.date < today.date }
            .sorted { $0.date < $1.date }
            .suffix(28)

        let hrvValues = priorHistory.compactMap(\.nocturnalHRVms).filter { $0 > 0 }.map { log($0) }
        let rhrValues = priorHistory.compactMap(\.restingHeartRateBPM).filter { $0 > 0 }
        let tempValues = priorHistory.compactMap(\.wristTemperatureCelsius)
        let respValues = priorHistory.compactMap(\.respiratoryRateBrPM).filter { $0 > 0 }

        let baselineDays = max(hrvValues.count, rhrValues.count)
        let isCalibrating = baselineDays < 5

        let hrvStats = stats(for: hrvValues, minScale: 0.12)
        let rhrStats = stats(for: rhrValues, minScale: 2.5)
        let tempStats = stats(for: tempValues, minScale: 0.25)
        let respStats = stats(for: respValues, minScale: 0.8)

        // 1. Проверка острого ночного скачка (признак начала ОРВИ / инфекции)
        let tempDelta = (today.wristTemperatureCelsius != nil && tempStats != nil)
            ? (today.wristTemperatureCelsius! - tempStats!.median)
            : nil
        let rhrDelta = (today.restingHeartRateBPM != nil && rhrStats != nil)
            ? (today.restingHeartRateBPM! - rhrStats!.median)
            : nil
        let respDelta = (today.respiratoryRateBrPM != nil && respStats != nil)
            ? (today.respiratoryRateBrPM! - respStats!.median)
            : nil

        let suspectedIllness: Bool = {
            if let t = tempDelta, t >= 0.5 {
                let rhrElevated = (rhrDelta ?? 0.0) >= 5.0
                let respElevated = (respDelta ?? 0.0) >= 1.8
                return rhrElevated || respElevated || t >= 0.8
            }
            return false
        }()

        // 2. Взвешенный расчёт доступных компонентов (динамическое перераспределение весов при неполных датчиках)
        var weightedScoreSum = 0.0
        var totalWeight = 0.0

        if let hrv = today.nocturnalHRVms, hrv > 0 {
            let subScore: Double
            if let hStats = hrvStats, !isCalibrating {
                let z = (log(hrv) - hStats.median) / hStats.scale
                subScore = clampScore(72.0 + z * 16.0)
            } else {
                subScore = 72.0
            }
            weightedScoreSum += subScore * 0.25
            totalWeight += 0.25
        }

        if let rhr = today.restingHeartRateBPM, rhr > 0 {
            let subScore: Double
            if let rStats = rhrStats, !isCalibrating {
                let z = (rStats.median - rhr) / rStats.scale // ниже пульс покоя -> выше готовность
                subScore = clampScore(72.0 + z * 18.0)
            } else {
                subScore = 72.0
            }
            weightedScoreSum += subScore * 0.20
            totalWeight += 0.20
        }

        if let sleepMins = today.sleepDurationMinutes, sleepMins > 0 {
            let ratio = Double(sleepMins) / Double(max(300, targetSleepMinutes))
            var sleepScore = clampScore(78.0 + (ratio - 1.0) * 85.0)
            if let stages = today.deepAndREMMinutes, sleepMins > 0 {
                let qualityRatio = Double(stages) / Double(sleepMins)
                if qualityRatio >= 0.35 {
                    sleepScore = min(100.0, sleepScore + 4.0)
                } else if qualityRatio < 0.20 {
                    sleepScore = max(0.0, sleepScore - 6.0)
                }
            }
            weightedScoreSum += sleepScore * 0.25
            totalWeight += 0.25
        }

        if let checkIn {
            // energy: 1..5 (выше лучше), soreness: 1..5 (ниже лучше), stress: 1..5 (ниже лучше)
            let energyNorm = Double(checkIn.energyRating - 1) / 4.0
            let sorenessNorm = Double(5 - checkIn.sorenessRating) / 4.0
            let stressNorm = Double(5 - checkIn.stressRating) / 4.0
            let subjective = (energyNorm * 0.45 + sorenessNorm * 0.30 + stressNorm * 0.25) * 100.0
            weightedScoreSum += subjective * 0.20
            totalWeight += 0.20
        }

        if tempDelta != nil || respDelta != nil {
            var penalty = 0.0
            if let t = tempDelta, t > 0.25 {
                penalty += (t - 0.25) * 45.0
            }
            if let resp = respDelta, resp > 1.0 {
                penalty += (resp - 1.0) * 18.0
            }
            let stabilityScore = clampScore(90.0 - penalty)
            weightedScoreSum += stabilityScore * 0.10
            totalWeight += 0.10
        }

        let hasNightSensors = today.nocturnalHRVms != nil || today.restingHeartRateBPM != nil || today.sleepDurationMinutes != nil
        var finalScore = totalWeight > 0 ? Int((weightedScoreSum / totalWeight).rounded()) : 70

        if suspectedIllness {
            finalScore = min(finalScore, 32)
        }

        // 3. Проверка триггера внеплановой разгрузки (3 из последних 4 дней: низкий HRV и высокий RHR одновременно)
        let recentFour = Array((priorHistory + [today]).suffix(4))
        var strainedDays = 0
        if !isCalibrating, let hStats = hrvStats, let rStats = rhrStats, recentFour.count >= 3 {
            for day in recentFour {
                if let hrv = day.nocturnalHRVms, hrv > 0, let rhr = day.restingHeartRateBPM, rhr > 0 {
                    let hrvZ = (log(hrv) - hStats.median) / hStats.scale
                    let rhrZ = (rhr - rStats.median) / rStats.scale
                    if hrvZ <= -1.0 && rhrZ >= 1.0 {
                        strainedDays += 1
                    }
                }
            }
        }
        let suggestUnplannedDeload = strainedDays >= 3

        let note = buildAdvisoryNote(
            score: finalScore,
            hasNightSensors: hasNightSensors,
            isCalibrating: isCalibrating,
            baselineDays: baselineDays,
            suspectedIllness: suspectedIllness,
            suggestUnplannedDeload: suggestUnplannedDeload
        )

        return ReadinessSnapshot(
            date: today.date,
            score: finalScore,
            hasCompleteNightSensors: hasNightSensors && today.nocturnalHRVms != nil && today.restingHeartRateBPM != nil,
            isCalibratingBaseline: isCalibrating,
            isSuspectedIllness: suspectedIllness,
            shouldSuggestUnplannedDeload: suggestUnplannedDeload,
            advisoryNote: note
        )
    }

    private static func buildAdvisoryNote(
        score: Int,
        hasNightSensors: Bool,
        isCalibrating: Bool,
        baselineDays: Int,
        suspectedIllness: Bool,
        suggestUnplannedDeload: Bool
    ) -> LocalizedCopy? {
        if suspectedIllness {
            return LocalizedCopy(
                da: "Tydelig stigning i håndledstemperatur, puls og vejrtrækning — muligt tegn på sygdom. Anbefaling: fuld hvile i stedet for træning.",
                ru: "Резкий скачок температуры запястья, пульса покоя и дыхания — похоже на начало простуды. Лучше полностью отдохнуть и не нагружать сердце."
            )
        }

        if suggestUnplannedDeload {
            return LocalizedCopy(
                da: "HRV er faldet og hvilepuls er forhøjet flere dage i træk. Overvej at starte en planlagt Deload-uge tidligt (vægte ændres ikke automatisk).",
                ru: "Пульс покоя повышен, а HRV снижен несколько дней подряд. Можно досрочно включить неделю Deload (веса не снижаются автоматически)."
            )
        }

        if !hasNightSensors {
            return LocalizedCopy(
                da: "Ingen nattedata fra uret — scoren bygger kun på morgentjekket.",
                ru: "Ночных данных с часов нет — оценка построена только по утреннему чек-ину."
            )
        }

        if isCalibrating {
            return LocalizedCopy(
                da: "Kalibrerer personlig basislinje (dag \(baselineDays + 1) af 5). Vægte følger programmet normalt.",
                ru: "Калибровка личной нормы (день \(baselineDays + 1) из 5). Веса идут строго по программе."
            )
        }

        if score >= 85 {
            return LocalizedCopy(
                da: "Topform i dag — godt tidspunkt til at jagte toppen af rep-området.",
                ru: "Отличное восстановление — можно уверенно давить в верх диапазона повторений."
            )
        }

        if score < 40 {
            return LocalizedCopy(
                da: "Lav restitutionsscore i dag. Programmet ændres ikke automatisk, men du kan vælge en lettere session, hvis kroppen føles tung.",
                ru: "Низкий балл восстановления. План не меняется сам, но при желании ты можешь выбрать облегчённый режим."
            )
        }

        if score < 55 {
            return LocalizedCopy(
                da: "Let fald i søvn/restitution. Kør efter planen, eller vælg selv en lille justering ved behov.",
                ru: "Небольшой спад по сну/восстановлению. Иди по плану цикла или при желании выбери лёгкую поправку вручную."
            )
        }

        return nil
    }

    private static func stats(for values: [Double], minScale: Double) -> DistributionStats? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let med = median(ofSorted: sorted)
        let absDevs = sorted.map { abs($0 - med) }.sorted()
        let mad = median(ofSorted: absDevs)
        let robustSD = max(minScale, mad * 1.4826)
        return DistributionStats(median: med, scale: robustSD)
    }

    private static func median(ofSorted sorted: [Double]) -> Double {
        let count = sorted.count
        if count % 2 == 1 {
            return sorted[count / 2]
        }
        return (sorted[count / 2 - 1] + sorted[count / 2]) / 2.0
    }

    private static func clampScore(_ value: Double) -> Double {
        min(100.0, max(0.0, value))
    }
}
