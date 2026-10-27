import Foundation

enum CatLanguage {
    static let locale = Locale(identifier: "uk_UA")
    /// System error descriptions may follow the phone's Russian or English language.
    /// Keep the visible explanation Ukrainian and retain the diagnostic code.
    static func error(_ error: Error) -> String {
        "Системна помилка iOS. Код: \((error as NSError).code). Спробуй ще раз."
    }
}
