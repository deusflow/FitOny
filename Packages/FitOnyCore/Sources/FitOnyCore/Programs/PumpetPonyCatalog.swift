import Foundation

/// Встроенный двуязычный каталог упражнений и шаблон программы PureGym «Pumpet Pony» / «Накаченная пони».
public enum PumpetPonyCatalog {
    // Детерминированные UUID для стабильных ссылок в базе данных, синхронизации и тестах.
    public enum ExerciseIDs {
        public static let inclineChestPress = UUID(uuidString: "10000000-0000-0000-0000-000000000001")!
        public static let horizontalChestPress = UUID(uuidString: "10000000-0000-0000-0000-000000000002")!
        public static let lowToHighCableFly = UUID(uuidString: "10000000-0000-0000-0000-000000000003")!
        public static let singleArmCableLateralRaise = UUID(uuidString: "10000000-0000-0000-0000-000000000004")!
        public static let bayesianCableCurl = UUID(uuidString: "10000000-0000-0000-0000-000000000005")!

        public static let chestSupportedRow = UUID(uuidString: "10000000-0000-0000-0000-000000000006")!
        public static let neutralLatPulldown = UUID(uuidString: "10000000-0000-0000-0000-000000000007")!
        public static let singleArmCableRow = UUID(uuidString: "10000000-0000-0000-0000-000000000008")!
        public static let reversePecDeck = UUID(uuidString: "10000000-0000-0000-0000-000000000009")!
        public static let incline45DumbbellCurl = UUID(uuidString: "10000000-0000-0000-0000-000000000010")!

        public static let preacherCurl = UUID(uuidString: "10000000-0000-0000-0000-000000000011")!
        public static let hammerCurl = UUID(uuidString: "10000000-0000-0000-0000-000000000012")!
        public static let overheadRopeTriceps = UUID(uuidString: "10000000-0000-0000-0000-000000000013")!
        public static let cableTricepsPushdown = UUID(uuidString: "10000000-0000-0000-0000-000000000014")!
        public static let seatedShoulderPressMachine = UUID(uuidString: "10000000-0000-0000-0000-000000000015")!
        public static let seatedDumbbellLateralRaise = UUID(uuidString: "10000000-0000-0000-0000-000000000016")!

        public static let hipThrust = UUID(uuidString: "10000000-0000-0000-0000-000000000017")!
        public static let seatedLegCurl = UUID(uuidString: "10000000-0000-0000-0000-000000000018")!
        public static let dumbbellRDL = UUID(uuidString: "10000000-0000-0000-0000-000000000019")!
        public static let hackSquatOrLegPress = UUID(uuidString: "10000000-0000-0000-0000-000000000020")!
        public static let seatedLegExtension = UUID(uuidString: "10000000-0000-0000-0000-000000000021")!
        public static let calfRaise = UUID(uuidString: "10000000-0000-0000-0000-000000000022")!
        public static let wideNeutralPulldownOrPullups = UUID(uuidString: "10000000-0000-0000-0000-000000000023")!
        public static let inclineSmithPress30 = UUID(uuidString: "10000000-0000-0000-0000-000000000024")!
    }

    public enum ModuleIDs {
        public static let moduleA = UUID(uuidString: "20000000-0000-0000-0000-000000000001")!
        public static let moduleB = UUID(uuidString: "20000000-0000-0000-0000-000000000002")!
        public static let moduleC = UUID(uuidString: "20000000-0000-0000-0000-000000000003")!
        public static let moduleD = UUID(uuidString: "20000000-0000-0000-0000-000000000004")!
        public static let moduleE = UUID(uuidString: "20000000-0000-0000-0000-000000000005")!
    }

    public static let templateID = UUID(uuidString: "30000000-0000-0000-0000-000000000001")!

    public static let exercises: [ExerciseDefinition] = [
        ExerciseDefinition(
            id: ExerciseIDs.inclineChestPress,
            code: "PG_INCLINE_PRESS",
            name: BilingualText(
                da: "Skrå brystpres 30° (maskine / håndvægte)",
                ru: "Жим на верх груди 30° (рычажный / гантели)"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .verticalBarPath,
            muscleContributions: [.chest: 1.0, .frontDelt: 0.5, .triceps: 0.5],
            defaultRestSeconds: 180,
            setupNote: SetupNote(
                backrestAngle: "30°",
                cueText: BilingualText(
                    da: "Albuerne let fremme (ca. 30° fra kroppen) for at beskytte skulderblad og skulder.",
                    ru: "Локти чуть вперёд на 30° от корпуса для защиты лопатки и плеча."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.horizontalChestPress,
            code: "PG_FLAT_PRESS",
            name: BilingualText(
                da: "Horisontal brystpres (siddende maskine / håndvægte)",
                ru: "Жим горизонтальный (тренажёр сидя / гантели лёжа)"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .verticalBarPath,
            muscleContributions: [.chest: 1.0, .frontDelt: 0.5, .triceps: 0.5],
            defaultRestSeconds: 135
        ),
        ExerciseDefinition(
            id: ExerciseIDs.lowToHighCableFly,
            code: "PG_LOW_HIGH_FLY",
            name: BilingualText(
                da: "Kabel-flyes nedefra og op (øvre bryst)",
                ru: "Сведение в кроссовере снизу вверх (верх груди)"
            ),
            isCompound: false,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .arcWristPath,
            muscleContributions: [.chest: 1.0, .frontDelt: 0.25],
            defaultRestSeconds: 90
        ),
        ExerciseDefinition(
            id: ExerciseIDs.singleArmCableLateralRaise,
            code: "PG_CABLE_LAT_RAISE",
            name: BilingualText(
                da: "En-arms sideløft i kabel (håndledshøjde)",
                ru: "Отведение руки в сторону в кроссовере (блок на уровне кисти)"
            ),
            isCompound: false,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .unilateral,
            muscleContributions: [.sideDelt: 1.0],
            defaultRestSeconds: 65
        ),
        ExerciseDefinition(
            id: ExerciseIDs.bayesianCableCurl,
            code: "PG_BAYESIAN_CURL",
            name: BilingualText(
                da: "Bayesian kabel-curl bag kroppen (biceps-peak)",
                ru: "Сгибание на бицепс из-за спины в кроссовере (пик)"
            ),
            isCompound: false,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .unilateral,
            muscleContributions: [.biceps: 1.0],
            defaultRestSeconds: 90
        ),
        ExerciseDefinition(
            id: ExerciseIDs.chestSupportedRow,
            code: "PG_CHEST_SUPP_ROW",
            name: BilingualText(
                da: "Roning med bryststøtte (maskine / T-bar)",
                ru: "Тяга с упором грудью (рычажный тренажёр / Т-гриф)"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .arcWristPath,
            muscleContributions: [.upperBack: 1.0, .lats: 0.5, .rearDelt: 0.5, .biceps: 0.5],
            defaultRestSeconds: 165,
            setupNote: SetupNote(
                useStraps: true,
                cueText: BilingualText(
                    da: "Brug håndledsremme og træk med albuerne, så biceps ikke overtager.",
                    ru: "Надень кистевые лямки и тяни локтями, чтобы бицепс не забирал нагрузку."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.neutralLatPulldown,
            code: "PG_NEUTRAL_PULLDOWN",
            name: BilingualText(
                da: "Pulldown mellem neutralt greb",
                ru: "Тяга верхнего блока средним нейтральным хватом"
            ),
            isCompound: true,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .arcWristPath,
            muscleContributions: [.lats: 1.0, .upperBack: 0.25, .biceps: 0.5],
            defaultRestSeconds: 120,
            setupNote: SetupNote(
                useStraps: true,
                cueText: BilingualText(
                    da: "Håndflader mod hinanden, remme på, sænk skuldrene ned.",
                    ru: "Ладони друг к другу, с лямками, тяни локтями к тазу."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.singleArmCableRow,
            code: "PG_1ARM_CABLE_ROW",
            name: BilingualText(
                da: "En-arms lav kabelroning mod hoften (el. pullover)",
                ru: "Тяга нижнего блока одной рукой к поясу (или пуловер)"
            ),
            isCompound: true,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .unilateral,
            muscleContributions: [.lats: 1.0, .rearDelt: 0.25, .biceps: 0.5],
            defaultRestSeconds: 105,
            setupNote: SetupNote(useStraps: true)
        ),
        ExerciseDefinition(
            id: ExerciseIDs.reversePecDeck,
            code: "PG_REVERSE_PEC_DECK",
            name: BilingualText(
                da: "Omvendt pec deck (bageste skulder)",
                ru: "Обратная бабочка (задняя дельта)"
            ),
            isCompound: false,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .arcWristPath,
            muscleContributions: [.rearDelt: 1.0, .upperBack: 0.5],
            defaultRestSeconds: 75
        ),
        ExerciseDefinition(
            id: ExerciseIDs.incline45DumbbellCurl,
            code: "PG_INCLINE_DB_CURL",
            name: BilingualText(
                da: "Skrå bænk-curl 45° med håndvægte (peak)",
                ru: "Сгибание с гантелями на наклонной скамье 45° (пик)"
            ),
            isCompound: false,
            equipment: .dumbbellRack(),
            motionProfile: .arcWristPath,
            muscleContributions: [.biceps: 1.0],
            defaultRestSeconds: 90,
            setupNote: SetupNote(backrestAngle: "45°")
        ),
        ExerciseDefinition(
            id: ExerciseIDs.preacherCurl,
            code: "PG_PREACHER_CURL",
            name: BilingualText(
                da: "Preacher curl (EZ-stang / én håndvægt)",
                ru: "Сгибание на скамье Скотта (EZ-гриф / гантель)"
            ),
            isCompound: false,
            equipment: .barbell(barWeightKg: 10.0, stepKg: 2.5),
            motionProfile: .arcWristPath,
            muscleContributions: [.biceps: 1.0],
            defaultRestSeconds: 120
        ),
        ExerciseDefinition(
            id: ExerciseIDs.hammerCurl,
            code: "PG_HAMMER_CURL",
            name: BilingualText(
                da: "Hammer curls (håndvægte / reb i kabel)",
                ru: "«Молотки» с гантелями или канатом в кроссовере"
            ),
            isCompound: false,
            equipment: .dumbbellRack(),
            motionProfile: .arcWristPath,
            muscleContributions: [.biceps: 1.0],
            defaultRestSeconds: 90
        ),
        ExerciseDefinition(
            id: ExerciseIDs.overheadRopeTriceps,
            code: "PG_OH_ROPE_TRICEPS",
            name: BilingualText(
                da: "Triceps extension over hovedet med reb",
                ru: "Разгибание из-за головы с канатом в кроссовере"
            ),
            isCompound: false,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .arcWristPath,
            muscleContributions: [.triceps: 1.0],
            defaultRestSeconds: 105
        ),
        ExerciseDefinition(
            id: ExerciseIDs.cableTricepsPushdown,
            code: "PG_TRICEPS_PUSHDOWN",
            name: BilingualText(
                da: "Triceps pushdown i kabel (V-greb / reb)",
                ru: "Разгибание рук вниз в кроссовере (V-рукоять / канат)"
            ),
            isCompound: false,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .arcWristPath,
            muscleContributions: [.triceps: 1.0],
            defaultRestSeconds: 90
        ),
        ExerciseDefinition(
            id: ExerciseIDs.seatedShoulderPressMachine,
            code: "PG_SHOULDER_PRESS",
            name: BilingualText(
                da: "Siddende skulderpres i maskine",
                ru: "Жим на плечи в тренажёре сидя"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .verticalBarPath,
            muscleContributions: [.frontDelt: 1.0, .sideDelt: 0.5, .triceps: 0.5],
            defaultRestSeconds: 120,
            setupNote: SetupNote(
                cueText: BilingualText(
                    da: "Sænk kontrolleret til ørehøjde.",
                    ru: "Опускай под контролем до уровня ушей."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.seatedDumbbellLateralRaise,
            code: "PG_SEATED_DB_LAT",
            name: BilingualText(
                da: "Siddende sideløft med håndvægte",
                ru: "Махи гантелями в стороны сидя"
            ),
            isCompound: false,
            equipment: .dumbbellRack(),
            motionProfile: .arcWristPath,
            muscleContributions: [.sideDelt: 1.0],
            defaultRestSeconds: 65
        ),
        ExerciseDefinition(
            id: ExerciseIDs.hipThrust,
            code: "PG_HIP_THRUST",
            name: BilingualText(
                da: "Hip Thrust (maskine / Smith)",
                ru: "Ягодичный мост (тренажёр Hip Thrust / Смит)"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .stationaryWrist,
            muscleContributions: [.glutes: 1.0, .hamstrings: 0.25],
            defaultRestSeconds: 150,
            setupNote: SetupNote(
                cueText: BilingualText(
                    da: "Hold 1 sekunds pause i toppen med fuld spænding i ballerne.",
                    ru: "Пауза 1 секунду в верхней точке с пиковым сокращением ягодиц."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.seatedLegCurl,
            code: "PG_SEATED_LEG_CURL",
            name: BilingualText(
                da: "Siddende lårcurl (baglår)",
                ru: "Сгибание ног сидя в тренажёре (бицепс бедра)"
            ),
            isCompound: false,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .stationaryWrist,
            muscleContributions: [.hamstrings: 1.0],
            defaultRestSeconds: 120
        ),
        ExerciseDefinition(
            id: ExerciseIDs.dumbbellRDL,
            code: "PG_DB_RDL",
            name: BilingualText(
                da: "Rumænsk dødløft (RDL) med håndvægte",
                ru: "Румынская тяга с гантелями"
            ),
            isCompound: true,
            equipment: .dumbbellRack(),
            motionProfile: .verticalBarPath,
            muscleContributions: [.hamstrings: 1.0, .glutes: 0.75, .spinalErectors: 0.5],
            defaultRestSeconds: 150,
            setupNote: SetupNote(useStraps: true)
        ),
        ExerciseDefinition(
            id: ExerciseIDs.hackSquatOrLegPress,
            code: "PG_HACK_OR_LEG_PRESS",
            name: BilingualText(
                da: "Hack squat eller benpres (tung vedligeholdelse)",
                ru: "Гакк-присед или жим ногами (тяжёлое удержание)"
            ),
            isCompound: true,
            equipment: .machine(stepKg: 5.0),
            motionProfile: .stationaryWrist,
            muscleContributions: [.quads: 1.0, .glutes: 0.5],
            defaultRestSeconds: 165
        ),
        ExerciseDefinition(
            id: ExerciseIDs.seatedLegExtension,
            code: "PG_LEG_EXTENSION",
            name: BilingualText(
                da: "Siddende leg extension (tung, RIR 1)",
                ru: "Разгибание ног сидя (тяжело, RIR 1)"
            ),
            isCompound: false,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .stationaryWrist,
            muscleContributions: [.quads: 1.0],
            defaultRestSeconds: 90
        ),
        ExerciseDefinition(
            id: ExerciseIDs.calfRaise,
            code: "PG_CALF_RAISE",
            name: BilingualText(
                da: "Lægpres stående eller i maskine",
                ru: "Подъёмы на носки стоя или в тренажёре (икры)"
            ),
            isCompound: false,
            equipment: .machine(stepKg: 2.5),
            motionProfile: .stationaryWrist,
            muscleContributions: [.calves: 1.0],
            defaultRestSeconds: 65,
            setupNote: SetupNote(
                cueText: BilingualText(
                    da: "Hold 2 sekunders stræk i bunden uden at bounce.",
                    ru: "Пауза 2 секунды в нижней точке растяжения без отбива."
                )
            )
        ),
        ExerciseDefinition(
            id: ExerciseIDs.wideNeutralPulldownOrPullups,
            code: "PG_BACK_WIDTH_TOUCH2",
            name: BilingualText(
                da: "Pull-ups eller bred/mellem pulldown (med remme)",
                ru: "Подтягивания или тяга верхнего блока (с лямками)"
            ),
            isCompound: true,
            equipment: .cableStack(stepKg: 2.5, microPinKg: 1.25),
            motionProfile: .arcWristPath,
            muscleContributions: [.lats: 1.0, .upperBack: 0.25, .biceps: 0.5],
            defaultRestSeconds: 120,
            setupNote: SetupNote(useStraps: true)
        ),
        ExerciseDefinition(
            id: ExerciseIDs.inclineSmithPress30,
            code: "PG_INCLINE_SMITH_30",
            name: BilingualText(
                da: "Skrå bænkpres i Smith-stativ 30°",
                ru: "Жим в Смите под углом 30° (верх груди)"
            ),
            isCompound: true,
            equipment: .barbell(barWeightKg: 15.0, stepKg: 2.5),
            motionProfile: .verticalBarPath,
            muscleContributions: [.chest: 1.0, .frontDelt: 0.5, .triceps: 0.5],
            defaultRestSeconds: 150,
            setupNote: SetupNote(backrestAngle: "30°")
        )
    ]

    public static let exerciseByID: [UUID: ExerciseDefinition] = {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }()

    /// Готовый шаблон программы PureGym «Pumpet Pony / Накаченная пони».
    public static let programTemplate = ProgramTemplate(
        id: templateID,
        slug: "pumpet-pony-puregym",
        name: BilingualText(da: "Pumpet Pony", ru: "Накаченная пони"),
        recommendedDaysPerWeek: 5,
        defaultMesocycleWeeks: 6,
        modules: [
            moduleA,
            moduleB,
            moduleC,
            moduleD,
            moduleE
        ]
    )

    public static let moduleA = WorkoutModuleBlueprint(
        id: ModuleIDs.moduleA,
        code: "A",
        title: BilingualText(
            da: "Bryst (øvre fokus) + Midterste skulder",
            ru: "Грудь (акцент верх) + Средняя дельта"
        ),
        slots: [
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.inclineChestPress,
                scheme: .reversePyramid(steps: [
                    RepRange(min: 6, max: 6),
                    RepRange(min: 6, max: 6),
                    RepRange(min: 8, max: 8),
                    RepRange(min: 8, max: 8),
                    RepRange(min: 10, max: 10)
                ]),
                warmup: .standardDoubleWarmup,
                targetRIR: 1,
                minRestSeconds: 180
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.horizontalChestPress,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
                warmup: .none,
                targetRIR: 1,
                minRestSeconds: 120,
                maxRestSeconds: 150
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.lowToHighCableFly,
                scheme: .straightSets(count: 4, reps: RepRange(min: 10, max: 12)),
                warmup: .none,
                targetRIR: 0,
                minRestSeconds: 90
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.singleArmCableLateralRaise,
                scheme: .straightSets(count: 4, reps: RepRange(min: 12, max: 15)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 60,
                maxRestSeconds: 75
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.bayesianCableCurl,
                scheme: .straightSets(count: 3, reps: RepRange(min: 10, max: 12)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 90,
                condition: .optionalIfMuscleRested(
                    muscle: .biceps,
                    minHours: 48,
                    reason: LocalizedCopy(
                        da: "Valgfrit tillæg, hvis arme ikke blev trænet i går og ikke er planlagt i morgen.",
                        ru: "Опциональная добавка, если руки не качались вчера и не планируются завтра."
                    )
                )
            )
        ]
    )

    public static let moduleB = WorkoutModuleBlueprint(
        id: ModuleIDs.moduleB,
        code: "B",
        title: BilingualText(
            da: "Ryg (hoveddag) + Bageste skulder + Biceps-peak",
            ru: "Спина (основной день) + Задняя дельта + Пик бицепса"
        ),
        slots: [
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.chestSupportedRow,
                scheme: .reversePyramid(steps: [
                    RepRange(min: 6, max: 6),
                    RepRange(min: 6, max: 6),
                    RepRange(min: 8, max: 8),
                    RepRange(min: 8, max: 8),
                    RepRange(min: 10, max: 10)
                ]),
                warmup: .standardDoubleWarmup,
                targetRIR: 1,
                minRestSeconds: 150,
                maxRestSeconds: 180
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.neutralLatPulldown,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
                warmup: .none,
                targetRIR: 1,
                minRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.singleArmCableRow,
                scheme: .straightSets(count: 4, reps: RepRange(min: 10, max: 12)),
                warmup: .none,
                targetRIR: 1,
                minRestSeconds: 90,
                maxRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.reversePecDeck,
                scheme: .straightSets(count: 3, reps: RepRange(min: 12, max: 15)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 75
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.incline45DumbbellCurl,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 12)),
                warmup: .single10(),
                targetRIR: 0,
                minRestSeconds: 90,
                condition: .swapIfMuscleFatigued(
                    muscle: .biceps,
                    withinHours: 48,
                    swapExerciseID: ExerciseIDs.seatedDumbbellLateralRaise,
                    swapScheme: .straightSets(count: 4, reps: RepRange(min: 12, max: 15)),
                    swapRestSeconds: 65,
                    swapRIR: 0,
                    reason: LocalizedCopy(
                        da: "Arme trænet inden for 48 timer — skift biceps ud med siddende sideløft for midterste skulder.",
                        ru: "Руки нагружались в последние 48 ч — замените бицепс на махи гантелями сидя на среднюю дельту."
                    )
                )
            )
        ]
    )

    public static let moduleC = WorkoutModuleBlueprint(
        id: ModuleIDs.moduleC,
        code: "C",
        title: BilingualText(
            da: "Arme (hovedprioritet) + Skuldre",
            ru: "Руки (главный приоритет) + Плечи"
        ),
        slots: [
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.preacherCurl,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
                warmup: .standardDoubleWarmup,
                targetRIR: 0,
                minRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.bayesianCableCurl,
                scheme: .straightSets(count: 3, reps: RepRange(min: 10, max: 12)),
                warmup: .none,
                targetRIR: 0,
                minRestSeconds: 90
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.hammerCurl,
                scheme: .straightSets(count: 3, reps: RepRange(min: 8, max: 12)),
                warmup: .none,
                targetRIR: 0,
                minRestSeconds: 90
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.overheadRopeTriceps,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 12)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 90,
                maxRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.cableTricepsPushdown,
                scheme: .straightSets(count: 2, reps: RepRange(min: 8, max: 10)),
                warmup: .none,
                targetRIR: 0,
                minRestSeconds: 90
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.seatedShoulderPressMachine,
                scheme: .straightSets(count: 3, reps: RepRange(min: 8, max: 10)),
                warmup: .single12(),
                targetRIR: 1,
                minRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.seatedDumbbellLateralRaise,
                scheme: .straightSets(count: 4, reps: RepRange(min: 12, max: 15)),
                warmup: .none,
                targetRIR: 0,
                minRestSeconds: 60,
                maxRestSeconds: 75
            )
        ]
    )

    public static let moduleD = WorkoutModuleBlueprint(
        id: ModuleIDs.moduleD,
        code: "D",
        title: BilingualText(
            da: "Underkrop (baller + baglår) + Rygbredde + Skuldre",
            ru: "Низ тела (ягодицы + бицепс бедра) + Ширина спины + Плечи"
        ),
        slots: [
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.hipThrust,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
                warmup: .standardDoubleWarmup,
                targetRIR: 1,
                minRestSeconds: 150,
                tempo: TempoPrescription(eccentricSeconds: 2.5, bottomPauseSeconds: 0.5, topPauseSeconds: 1.0)
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.seatedLegCurl,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 12)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 120
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.dumbbellRDL,
                scheme: .straightSets(count: 3, reps: RepRange(min: 8, max: 10)),
                warmup: .none,
                targetRIR: 1,
                minRestSeconds: 150
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.seatedLegExtension,
                scheme: .straightSets(count: 3, reps: RepRange(min: 10, max: 12)),
                warmup: .none,
                targetRIR: 1,
                minRestSeconds: 90,
                condition: .biWeeklyChoice(
                    suggestedIntervalDays: 10,
                    alternativeExerciseID: ExerciseIDs.hackSquatOrLegPress,
                    alternativeScheme: .straightSets(count: 2, reps: RepRange(min: 6, max: 8)),
                    alternativeWarmup: .standardDoubleWarmup,
                    alternativeRestSeconds: 165,
                    alternativeRIR: 1,
                    reason: LocalizedCopy(
                        da: "Hver 1–2 uge anbefales tung Hack Squat / Benpres (2×6–8, RIR 1) i stedet for leg extension.",
                        ru: "Раз в 1–2 недели рекомендуется тяжёлый Гакк-присед / жим ногами (2×6–8, RIR 1) вместо разгибаний."
                    )
                )
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.calfRaise,
                scheme: .straightSets(count: 3, reps: RepRange(min: 12, max: 15)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 60,
                maxRestSeconds: 75,
                tempo: TempoPrescription(eccentricSeconds: 2.5, bottomPauseSeconds: 2.0, topPauseSeconds: 0.5)
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.wideNeutralPulldownOrPullups,
                scheme: .straightSets(count: 3, reps: RepRange(min: 8, max: 10)),
                warmup: .single12(),
                targetRIR: 1,
                minRestSeconds: 120,
                condition: .optionalIfMuscleRested(
                    muscle: .lats,
                    minHours: 48,
                    reason: LocalizedCopy(
                        da: "2. rygtouch i ugen — udføres kun hvis der er gået mindst 48 timer siden Modul B.",
                        ru: "2-е касание спины за неделю — выполнять только если после Модуля B прошло минимум 48 часов."
                    )
                )
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.singleArmCableLateralRaise,
                scheme: .straightSets(count: 4, reps: RepRange(min: 12, max: 15)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 60,
                maxRestSeconds: 75
            )
        ]
    )

    public static let moduleE = WorkoutModuleBlueprint(
        id: ModuleIDs.moduleE,
        code: "E",
        title: BilingualText(
            da: "Overkrop finisher (Valgfri 5. dag • 45–50 min)",
            ru: "Добивка верха (Опциональный 5-й день • 45–50 мин)"
        ),
        slots: [
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.inclineSmithPress30,
                scheme: .straightSets(count: 4, reps: RepRange(min: 8, max: 10)),
                warmup: .standardDoubleWarmup,
                targetRIR: 1,
                minRestSeconds: 150
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.wideNeutralPulldownOrPullups,
                scheme: .straightSets(count: 3, reps: RepRange(min: 8, max: 10)),
                warmup: .single12(),
                targetRIR: 1,
                minRestSeconds: 120,
                condition: .catchUpIfMuscleUnderVolume(
                    muscle: .lats,
                    reason: LocalizedCopy(
                        da: "Udføres hvis du sprang 2. rygtouch over i Modul D.",
                        ru: "Выполнять, если пропустил 2-е касание спины в Модуле D."
                    )
                )
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.bayesianCableCurl,
                scheme: .straightSets(count: 4, reps: RepRange(min: 10, max: 12)),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 90
            ),
            ModuleExerciseSlot(
                exerciseID: ExerciseIDs.seatedDumbbellLateralRaise,
                scheme: .superset(
                    pairedExerciseID: ExerciseIDs.reversePecDeck,
                    count: 3,
                    reps: RepRange(min: 12, max: 15)
                ),
                warmup: .single12(),
                targetRIR: 0,
                minRestSeconds: 60,
                slotNote: BilingualText(
                    da: "Skiftevis: Siddende sideløft + Omvendt pec deck.",
                    ru: "Чередованием: Махи гантелями сидя + Обратная бабочка."
                )
            )
        ]
    )
}
