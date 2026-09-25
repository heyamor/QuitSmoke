import Foundation

enum AppFormatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    static let dateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()

    static func duration(_ interval: TimeInterval) -> String {
        let totalHours = max(0, Int(interval / 3_600))
        let days = totalHours / 24
        let hours = totalHours % 24
        if days > 0 { return "\(days) 天 \(hours) 小时" }
        let minutes = max(0, Int(interval / 60) % 60)
        return "\(hours) 小时 \(minutes) 分钟"
    }

    static func currency(_ amount: Double) -> String {
        amount.formatted(.currency(code: "CNY").precision(.fractionLength(2)))
    }
}

