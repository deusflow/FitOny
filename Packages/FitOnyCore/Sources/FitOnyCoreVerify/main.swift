import Foundation
import FitOnyCore

@main
struct FitOnyCoreVerify {
    static func main() {
        let muscles = MuscleGroup.allCases
        precondition(muscles.count == 14, "Ожидалось 14 мышечных групп")

        precondition(MuscleGroup.chest.displayName(for: .da) == "Bryst")
        precondition(MuscleGroup.chest.displayName(for: .ru) == "Грудь")
        precondition(AppLanguage.da.toggled() == .ru && AppLanguage.ru.toggled() == .da)

        let exerciseName = BilingualText(da: "Skrå bænkpres", ru: "Жим на наклонной")
        precondition(exerciseName.resolved(for: .da) == "Skrå bænkpres")
        precondition(exerciseName.resolved(for: .ru) == "Жим на наклонной")
        precondition(exerciseName.secondaryRussianHint(for: .da) == "Жим на наклонной")
        precondition(exerciseName.secondaryRussianHint(for: .ru) == nil)

        let dumbbell = EquipmentProfile.dumbbellRack()
        let roundedDumbbell = dumbbell.roundToAvailable(23.2)
        let nextDumbbell = dumbbell.nextStepUp(from: 22.0)
        precondition(roundedDumbbell == 24.0, "Округление гантельного ряда 23.2 кг -> 24 кг")
        precondition(nextDumbbell == 24.0, "Следующий шаг после гантели 22 кг -> 24 кг")

        let barbell = EquipmentProfile.barbell(barWeightKg: 20.0, stepKg: 2.5)
        precondition(barbell.roundToAvailable(86.4) == 87.5, "Округление штанги кратно 2.5 кг")

        let chestNatural = MuscleGroup.chest.defaultLandmarks(for: .natural)
        let chestEnhanced = MuscleGroup.chest.defaultLandmarks(for: .enhanced)
        precondition(chestEnhanced.mrv > chestNatural.mrv, "Профиль Enhanced должен иметь более высокий потолок MRV")
        precondition(PhysiologicalProfile.natural.directMuscleRecoveryHours == 48.0)
        precondition(PhysiologicalProfile.enhanced.directMuscleRecoveryHours == 36.0)

        let loadState = ExerciseLoadState(exerciseID: UUID(), baselineWorkingWeightKg: 100.0, sessionTargetWeightKg: 90.0)
        precondition(loadState.baselineWorkingWeightKg == 100.0 && loadState.sessionTargetWeightKg == 90.0)

        print("FitOnyCoreVerify OK: 14 мышечных групп (DA/RU), мгновенное переключение языка, округление весов и контракты синхронизации проверены.")
    }
}
