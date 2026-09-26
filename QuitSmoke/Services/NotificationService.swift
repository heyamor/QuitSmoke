import Foundation
import UserNotifications

enum NotificationService {
    static let reminderIdentifier = "daily-check-in"

    static func configure(enabled: Bool, hour: Int, minute: Int) async -> Bool {
        await configure(enabled: enabled, times: [ReminderTime(hour: hour, minute: minute)])
    }

    static func configure(enabled: Bool, times: [ReminderTime]) async -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return true }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return false }

            let content = UNMutableNotificationContent()
            content.title = "今天也辛苦了"
            content.body = "花一分钟记录今天的无烟状态。每一次选择都算数。"
            content.sound = .default

            for (index, time) in times.enumerated() {
                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(reminderIdentifier)-\(index)",
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
            return true
        } catch {
            return false
        }
    }
}
