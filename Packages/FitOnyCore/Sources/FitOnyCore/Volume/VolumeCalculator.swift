import Foundation

public enum VolumeCalculator {
    /// Рассчитывает дробный недельный объём по всем 14 мышечным группам и баланс тяг/жимов плечевого пояса.
    /// - Разминочные сеты (`isWarmup`) и слишком лёгкие подходы (`rir > 4`) отбрасываются.
    /// - Ступени дроп-сета (`isDropStep`) учитываются с понижающим множителем `0.5`, чтобы не раздувать мнимый объём.
    public static func calculateWeeklyReport(
        completedSets: [CompletedSetRecord],
        exercisesByID: [UUID: ExerciseDefinition] = ProgramCatalog.builtIn.exercisesByID,
        profile: PhysiologicalProfile = .natural,
        landmarkOverrides: [MuscleGroup: VolumeLandmarks] = [:]
    ) -> WeeklyVolumeReport {
        var directByMuscle: [MuscleGroup: Double] = [:]
        var indirectByMuscle: [MuscleGroup: Double] = [:]

        for set in completedSets {
            guard !set.isWarmup, set.rir <= 4, set.completedReps > 0 else {
                continue
            }
            guard let exercise = exercisesByID[set.exerciseID] else {
                continue
            }

            let setWeighting = set.isDropStep ? 0.5 : 1.0

            for (muscle, contribution) in exercise.muscleContributions where contribution > 0 {
                let effective = setWeighting * contribution
                if contribution >= 0.99 {
                    directByMuscle[muscle, default: 0.0] += effective
                } else {
                    indirectByMuscle[muscle, default: 0.0] += effective
                }
            }
        }

        var ordered: [MuscleVolumeSummary] = []
        var byMuscle: [MuscleGroup: MuscleVolumeSummary] = [:]

        for muscle in MuscleGroup.allCases {
            let direct = roundQuarter(directByMuscle[muscle, default: 0.0])
            let indirect = roundQuarter(indirectByMuscle[muscle, default: 0.0])
            let total = roundQuarter(direct + indirect)
            let landmarks = landmarkOverrides[muscle] ?? muscle.defaultLandmarks(for: profile)

            let summary = MuscleVolumeSummary(
                muscle: muscle,
                directSets: direct,
                indirectSets: indirect,
                effectiveWeeklySets: total,
                landmarks: landmarks
            )
            ordered.append(summary)
            byMuscle[muscle] = summary
        }

        // Для здоровья плечевого сустава сопоставляем жимовую цепь (грудь + передняя дельта + трицепс)
        // с тяговой цепью (широчайшие + верх спины + задняя дельта + бицепс), не смешивая с отведениями средней дельты.
        let pushMuscles: [MuscleGroup] = [.chest, .frontDelt, .triceps]
        let pullMuscles: [MuscleGroup] = [.lats, .upperBack, .rearDelt, .biceps]

        let pushTotal = roundQuarter(pushMuscles.reduce(0.0) { $0 + (byMuscle[$1]?.effectiveWeeklySets ?? 0.0) })
        let pullTotal = roundQuarter(pullMuscles.reduce(0.0) { $0 + (byMuscle[$1]?.effectiveWeeklySets ?? 0.0) })

        return WeeklyVolumeReport(
            summariesByMuscle: byMuscle,
            orderedSummaries: ordered,
            pushPullBalance: PushPullBalance(pushVolumeSets: pushTotal, pullVolumeSets: pullTotal)
        )
    }

    private static func roundQuarter(_ value: Double) -> Double {
        (value * 100.0).rounded() / 100.0
    }
}
