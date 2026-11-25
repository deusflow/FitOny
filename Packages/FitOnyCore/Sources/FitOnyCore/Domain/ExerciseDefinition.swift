import Foundation

/// Поведение датчика движения запястья для конкретного упражнения.
public enum MotionTrackingProfile: String, Codable, Sendable, Equatable {
    case verticalBarPath      // Жимы лёжа/стоя, присед со штангой
    case arcWristPath         // Сгибания рук, махи, вертикальные и горизонтальные тяги
    case unilateral           // Одноручные движения (зависит от руки с часами)
    case stationaryWrist      // Жим ногами, сгибания/разгибания ног, икры — автоподсчёт отключён

    public var supportsWristSensor: Bool {
        self != .stationaryWrist
    }
}

public struct SetupNote: Codable, Sendable, Equatable {
    public var seatPosition: String?
    public var backrestAngle: String?
    public var useStraps: Bool
    public var cueText: BilingualText

    public init(
        seatPosition: String? = nil,
        backrestAngle: String? = nil,
        useStraps: Bool = false,
        cueText: BilingualText = .custom("")
    ) {
        self.seatPosition = seatPosition
        self.backrestAngle = backrestAngle
        self.useStraps = useStraps
        self.cueText = cueText
    }
}

public struct ExerciseDefinition: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var code: String
    public var name: BilingualText
    public var isCompound: Bool
    public var equipment: EquipmentProfile
    public var alternativeEquipment: EquipmentProfile?
    public var motionProfile: MotionTrackingProfile
    /// Дробный вклад одного рабочего подхода по мышечным группам (например, Chest: 1.0, Triceps: 0.5).
    public var muscleContributions: [MuscleGroup: Double]
    public var defaultRestSeconds: Int
    public var setupNote: SetupNote

    public init(
        id: UUID = UUID(),
        code: String,
        name: BilingualText,
        isCompound: Bool,
        equipment: EquipmentProfile,
        alternativeEquipment: EquipmentProfile? = nil,
        motionProfile: MotionTrackingProfile,
        muscleContributions: [MuscleGroup: Double],
        defaultRestSeconds: Int,
        setupNote: SetupNote = SetupNote()
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.isCompound = isCompound
        self.equipment = equipment
        self.alternativeEquipment = alternativeEquipment
        self.motionProfile = motionProfile
        self.muscleContributions = muscleContributions
        self.defaultRestSeconds = defaultRestSeconds
        self.setupNote = setupNote
    }
}
