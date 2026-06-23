import UserNotifications

enum NotificationManager {

    // Stable identifier per prayer — used to cancel and replace on reschedule
    private static func identifier(for prayer: PrayerTime) -> String {
        "salahmotion.prayer.\(prayer.rawValue)"
    }

    // MARK: - Permission

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            if granted { schedulePrayerNotifications() }
        }
    }

    // MARK: - Schedule

    // Cancels all existing prayer notifications then schedules one repeating
    // daily notification per prayer at its exact hardcoded time.
    static func schedulePrayerNotifications() {
        let center = UNUserNotificationCenter.current()
        let identifiers = PrayerTime.allCases.map { identifier(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for prayer in PrayerTime.allCases {
            let content = UNMutableNotificationContent()
            content.title = "\(prayer.displayName) · \(prayer.arabic)"
            content.body  = "It is time for prayer."
            content.sound = .default

            // Fire at the prayer's scheduled hour and minute, every day
            let components = Calendar.current.dateComponents(
                [.hour, .minute],
                from: prayer.scheduledDate
            )
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: identifier(for: prayer),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    // MARK: - Status check

    // Re-schedules only if permission is already granted — safe to call on every app open.
    static func refreshIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                schedulePrayerNotifications()
            }
        }
    }
}
