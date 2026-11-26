import Foundation

/// Единый реестр всех встроенных и пользовательских (кастомных) программ и упражнений.
/// Избавляет движки периодизации и объёма от прямой привязки к одному захардкоженному шаблону.
public struct ProgramCatalog: Codable, Sendable, Equatable {
    public private(set) var exercisesByID: [UUID: ExerciseDefinition]
    public private(set) var programs: [ProgramTemplate]

    public static let builtIn = ProgramCatalog(
        exercises: PumpetPonyCatalog.exercises,
        programs: [PumpetPonyCatalog.programTemplate]
    )

    public init(exercises: [ExerciseDefinition], programs: [ProgramTemplate]) {
        self.exercisesByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        self.programs = programs
    }

    public mutating func upsertExercise(_ exercise: ExerciseDefinition) {
        exercisesByID[exercise.id] = exercise
    }

    public mutating func upsertProgram(_ program: ProgramTemplate) {
        if let idx = programs.firstIndex(where: { $0.id == program.id }) {
            programs[idx] = program
        } else {
            programs.append(program)
        }
    }

    public mutating func removeCustomProgram(id: UUID) {
        programs.removeAll { $0.id == id && $0.isCustom }
    }

    public func program(id: UUID) -> ProgramTemplate? {
        programs.first { $0.id == id }
    }
}
