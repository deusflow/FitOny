import Foundation

/// Поддерживаемые языки интерфейса: датский и русский с мгновенным переключением на лету.
public enum AppLanguage: String, Codable, Sendable, CaseIterable, Hashable {
    case da
    case ru

    public var localeIdentifier: String {
        switch self {
        case .da: "da_DK"
        case .ru: "ru_RU"
        }
    }

    public var shortBadge: String {
        switch self {
        case .da: "DA"
        case .ru: "RU"
        }
    }

    public var nativeDisplayName: String {
        switch self {
        case .da: "Dansk"
        case .ru: "Русский"
        }
    }

    public func toggled() -> AppLanguage {
        switch self {
        case .da: .ru
        case .ru: .da
        }
    }
}

/// Обязательная пара перевода (датский + русский), гарантирующая отсутствие пустых строк.
public struct LocalizedCopy: Codable, Sendable, Equatable, Hashable {
    public var da: String
    public var ru: String

    public init(da: String, ru: String) {
        self.da = da
        self.ru = ru
    }

    public func value(for language: AppLanguage) -> String {
        switch language {
        case .da: da
        case .ru: ru
        }
    }
}

/// Текст для сущностей, которые могут быть как встроенными (с обоими переводами), так и введёнными пользователем вручную.
public enum BilingualText: Codable, Sendable, Equatable, Hashable {
    case localized(LocalizedCopy)
    case custom(String)

    public init(da: String, ru: String) {
        self = .localized(LocalizedCopy(da: da, ru: ru))
    }

    public func resolved(for language: AppLanguage) -> String {
        switch self {
        case let .localized(copy):
            return copy.value(for: language)
        case let .custom(text):
            return text
        }
    }

    /// Дополнительная подсказка на русском при активном датском интерфейсе (если текст встроенный).
    public func secondaryRussianHint(for language: AppLanguage) -> String? {
        guard language == .da, case let .localized(copy) = self, copy.da != copy.ru else {
            return nil
        }
        return copy.ru
    }
}

/// Общий словарь интерфейса, используемый одновременно в iPhone, Apple Watch и виджетах.
public enum FitOnyCopy {
    public static let appName = LocalizedCopy(da: "FitOny", ru: "FitOny")

    // Вкладки iPhone
    public static let tabToday = LocalizedCopy(da: "I dag", ru: "Сегодня")
    public static let tabCycles = LocalizedCopy(da: "Cyklusser", ru: "Циклы")
    public static let tabVolume = LocalizedCopy(da: "Volumen", ru: "Объём")
    public static let tabAdvanced = LocalizedCopy(da: "Advanced", ru: "Advanced")
    public static let tabSettings = LocalizedCopy(da: "Indstillinger", ru: "Настройки")

    // Заглушки и ключевые заголовки экранов
    public static let todayModuleTitle = LocalizedCopy(da: "Dagens modul", ru: "Сегодняшний модуль")
    public static let todayModuleSubtitle = LocalizedCopy(
        da: "Parathed, morgentjek og start af træning",
        ru: "Готовность, утренний чек-ин и старт тренировки"
    )
    public static let activeWorkoutTitle = LocalizedCopy(da: "Aktiv træning", ru: "Активная тренировка")
    public static let programsTitle = LocalizedCopy(da: "Programmer og cyklusser", ru: "Программы и циклы")
    public static let programsSubtitle = LocalizedCopy(
        da: "Makrocyklus, 6-ugers mesocyklus og træningsmoduler",
        ru: "Макроцикл, 6-недельный мезоцикл и модули тренировок"
    )
    public static let analyticsTitle = LocalizedCopy(da: "Volumen og styrke", ru: "Объём и прогрессия силы")
    public static let analyticsSubtitle = LocalizedCopy(
        da: "MEV / MAV / MRV for 14 muskelgrupper og e1RM-kurver",
        ru: "Зоны MEV / MAV / MRV по 14 мышцам и кривые e1RM"
    )
    public static let advancedTitle = LocalizedCopy(da: "Lukket afsnit", ru: "Закрытый раздел")
    public static let advancedSubtitle = LocalizedCopy(
        da: "Beskyttet af Face ID og AES-GCM: profil, blodtryk og blodprøver",
        ru: "Защищено Face ID и шифрованием AES-GCM: профиль, АД и биомаркеры"
    )

    // Настройки
    public static let appearanceSection = LocalizedCopy(da: "Udseende", ru: "Оформление")
    public static let themePickerLabel = LocalizedCopy(da: "Farvetema", ru: "Тема оформления")
    public static let languageSection = LocalizedCopy(da: "Sprog", ru: "Язык")
    public static let languagePickerLabel = LocalizedCopy(da: "App-sprog", ru: "Язык приложения")
    public static let bilingualHintToggle = LocalizedCopy(
        da: "Vis russisk hint under danske øvelsesnavne",
        ru: "Показывать русскую подсказку под датским названием упражнения"
    )
    public static let quickSwitchHint = LocalizedCopy(
        da: "Tip: Tryk på DA/RU øverst for at skifte, eller hold nede for hurtigt at kigge på russisk.",
        ru: "Подсказка: нажми DA/RU сверху для переключения или удерживай, чтобы быстро подсмотреть перевод."
    )

    // Apple Watch и виджеты
    public static let watchReady = LocalizedCopy(da: "Klar til træning", ru: "Готов к тренировке")
    public static let watchWorkingSet = LocalizedCopy(da: "Arbejdssæt", ru: "Рабочий подход")
    public static let watchMorningCheckIn = LocalizedCopy(da: "Morgentjek", ru: "Утренний чек-ин")
    public static let widgetReadinessTitle = LocalizedCopy(da: "Parathed", ru: "Готовность")
    public static let widgetReadinessDescription = LocalizedCopy(
        da: "Restitutionsscore på Apple Watch-urskiven.",
        ru: "Индекс восстановления на циферблате Apple Watch."
    )
    public static let widgetLiveActivityTitle = LocalizedCopy(da: "Aktiv træning", ru: "Активная тренировка")
    public static let widgetLiveActivityDescription = LocalizedCopy(
        da: "Pausetimer og næste sæt på låseskærmen.",
        ru: "Таймер отдыха и следующий подход на заблокированном экране."
    )
}
