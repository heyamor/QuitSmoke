import Foundation
import UserNotifications

enum NotificationService {
    static let reminderIdentifier = "daily-check-in"

    static func configure(enabled: Bool, hour: Int, minute: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        guard enabled else { return true }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return false }

            let content = UNMutableNotificationContent()
            content.title = "今天也辛苦了"
            content.body = "花一分钟记录今天的无烟状态。每一次选择都算数。"
            content.sound = .default

            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderIdentifier,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
}

