import Foundation

// MARK: - DateCalculator

struct DateCalculator {

    // MARK: - Private

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    private static let iso8601Parser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fractionalISO8601Parser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Public API

    /// Calculate the number of days based on the count type.
    /// - Parameters:
    ///   - baseDate: Date string in "YYYY-MM-DD" format.
    ///   - countType: The counting mode.
    /// - Returns: The computed day count (always >= 0 for countdown/elapsed; >= 1 for daycount).
    static func calculateDays(baseDate: String, countType: CountType) -> Int {
        guard let base = baseDateFromString(baseDate) else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let startOfBase = calendar.startOfDay(for: base)

        guard let daysBetween = calendar.dateComponents(
            [.day],
            from: startOfBase,
            to: today
        ).day else {
            return 0
        }

        switch countType {
        case .countdown:
            // baseDate - today: days remaining until the target date
            // Returns max(0, ...) so past dates show 0
            return max(0, -daysBetween)

        case .elapsed:
            // today - baseDate: days that have passed since the base date
            return max(0, daysBetween)

        case .daycount:
            // Same as elapsed but counting starts at 1 (day 1 = the base date itself)
            return max(1, daysBetween + 1)
        }
    }

    /// Parse a "YYYY-MM-DD" string into a `Date`.
    /// - Parameter string: The date string to parse.
    /// - Returns: The parsed `Date`, or `nil` if the string is invalid.
    static func baseDateFromString(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    /// Format a `Date` into a "YYYY-MM-DD" string.
    /// - Parameter date: The date to format.
    /// - Returns: The formatted string.
    static func stringFromDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Returns today's date as a "YYYY-MM-DD" string.
    static func todayString() -> String {
        stringFromDate(Date())
    }

    /// Converts an ISO8601 timestamp into a local "YYYY-MM-DD" date string.
    static func localDateString(fromISO8601 string: String) -> String? {
        guard let date = dateFromISO8601String(string) else {
            return nil
        }

        return stringFromDate(date)
    }

    private static func dateFromISO8601String(_ string: String) -> Date? {
        iso8601Parser.date(from: string) ?? fractionalISO8601Parser.date(from: string)
    }
}
