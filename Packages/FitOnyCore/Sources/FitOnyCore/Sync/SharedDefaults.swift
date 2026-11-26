import Foundation

/// Общий мост настроек между основным приложением и его виджетами (App Group с безопасным откатом на standard).
public enum SharedDefaults {
    public static let appGroupSuiteName = "group.com.deusflow.fitony"

    public enum Keys {
        public static let phonePrimaryLanguage = "fitony.primaryLanguage"
        public static let showSecondaryRussianHint = "fitony.showSecondaryRussianHint"
        public static let watchPrimaryLanguage = "fitony.watch.primaryLanguage"
        public static let cachedReadinessScore = "fitony.cachedReadinessScore"
        public static let cachedNextModuleTitle = "fitony.cachedNextModuleTitle"
    }

    public static var store: UserDefaults {
        UserDefaults(suiteName: appGroupSuiteName) ?? .standard
    }
}
