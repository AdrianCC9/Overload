import Foundation

extension Calendar {
    static var overload: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.overload.startOfDay(for: self)
    }

    var weekStart: Date {
        let components = Calendar.overload.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Calendar.overload.date(from: components)?.startOfDay ?? startOfDay
    }

    var sundayWeekStart: Date {
        let weekday = Calendar.overload.component(.weekday, from: self)
        return addingDays(-(weekday - 1)).startOfDay
    }

    var monthStart: Date {
        let components = Calendar.overload.dateComponents([.year, .month], from: self)
        return Calendar.overload.date(from: components)?.startOfDay ?? startOfDay
    }

    func addingDays(_ days: Int) -> Date {
        Calendar.overload.date(byAdding: .day, value: days, to: self) ?? self
    }

    func addingMonths(_ months: Int) -> Date {
        Calendar.overload.date(byAdding: .month, value: months, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.overload.isDate(self, inSameDayAs: other)
    }
}

enum DateFormatters {
    static let isoDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let shortDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}
