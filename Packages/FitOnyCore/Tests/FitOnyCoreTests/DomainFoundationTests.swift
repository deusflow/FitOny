import Foundation
#if canImport(Testing)
import Testing
@testable import FitOnyCore

@Suite("Domain Foundation Tests")
struct DomainFoundationTests {
    @Test("14 muscle groups, bilingual DA/RU names, and recovery windows")
    func muscleCatalogAndProfiles() {
        #expect(MuscleGroup.allCases.count == 14)
        #expect(MuscleGroup.chest.displayName(for: .da) == "Bryst")
        #expect(MuscleGroup.chest.displayName(for: .ru) == "Грудь")
        #expect(AppLanguage.da.toggled() == .ru)
        #expect(PhysiologicalProfile.natural.directMuscleRecoveryHours == 48.0)
        #expect(PhysiologicalProfile.enhanced.directMuscleRecoveryHours == 36.0)
    }

    @Test("Commercial dumbbell rack avoids non-existent odd weights above 10 kg")
    func dumbbellRounding() {
        let rack = EquipmentProfile.dumbbellRack()
        #expect(rack.roundToAvailable(23.1) == 24.0)
        #expect(rack.nextStepUp(from: 20.0) == 22.0)
    }
}
#endif
