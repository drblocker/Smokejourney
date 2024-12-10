import UserNotifications
import os.log

class EnvironmentNotificationManager {
    static let shared = EnvironmentNotificationManager()
    private let logger = Logger(subsystem: "com.smokejourney", category: "EnvironmentNotifications")
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    enum NotificationType {
        case temperatureHigh(Double)
        case temperatureLow(Double)
        case humidityHigh(Double)
        case humidityLow(Double)
        
        var identifier: String {
            switch self {
            case .temperatureHigh: return "environment.temperature.high"
            case .temperatureLow: return "environment.temperature.low"
            case .humidityHigh: return "environment.humidity.high"
            case .humidityLow: return "environment.humidity.low"
            }
        }
        
        var title: String {
            switch self {
            case .temperatureHigh: return "High Temperature Alert"
            case .temperatureLow: return "Low Temperature Alert"
            case .humidityHigh: return "High Humidity Alert"
            case .humidityLow: return "Low Humidity Alert"
            }
        }
        
        var body: String {
            switch self {
            case .temperatureHigh(let temp):
                return String(format: "Temperature is too high: %.1f°F", temp)
            case .temperatureLow(let temp):
                return String(format: "Temperature is too low: %.1f°F", temp)
            case .humidityHigh(let humidity):
                return String(format: "Humidity is too high: %.1f%%", humidity)
            case .humidityLow(let humidity):
                return String(format: "Humidity is too low: %.1f%%", humidity)
            }
        }
    }
    
    private init() {
        setupNotificationCategories()
    }
    
    func requestAuthorization() async throws {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            logger.debug("Notification authorization \(granted ? "granted" : "denied")")
        } catch {
            logger.error("Failed to request notification authorization: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func setupNotificationCategories() {
        // Temperature Actions
        let viewTemperature = UNNotificationAction(
            identifier: "VIEW_TEMPERATURE",
            title: "View Details",
            options: .foreground
        )
        
        let dismissTemperature = UNNotificationAction(
            identifier: "DISMISS_TEMPERATURE",
            title: "Dismiss",
            options: .destructive
        )
        
        let temperatureCategory = UNNotificationCategory(
            identifier: "TEMPERATURE_ALERT",
            actions: [viewTemperature, dismissTemperature],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Humidity Actions
        let viewHumidity = UNNotificationAction(
            identifier: "VIEW_HUMIDITY",
            title: "View Details",
            options: .foreground
        )
        
        let dismissHumidity = UNNotificationAction(
            identifier: "DISMISS_HUMIDITY",
            title: "Dismiss",
            options: .destructive
        )
        
        let humidityCategory = UNNotificationCategory(
            identifier: "HUMIDITY_ALERT",
            actions: [viewHumidity, dismissHumidity],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register categories
        notificationCenter.setNotificationCategories([
            temperatureCategory,
            humidityCategory
        ])
    }
    
    func scheduleNotification(type: NotificationType, for humidor: Humidor) async {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default
        
        // Add category based on type
        switch type {
        case .temperatureHigh, .temperatureLow:
            content.categoryIdentifier = "TEMPERATURE_ALERT"
        case .humidityHigh, .humidityLow:
            content.categoryIdentifier = "HUMIDITY_ALERT"
        }
        
        // Add humidor info to user info
        content.userInfo = [
            "humidorId": String(describing: humidor.persistentModelID),
            "notificationType": type.identifier
        ]
        
        // Create request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
            logger.debug("Scheduled notification: \(type.identifier)")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }
    
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.debug("Removed all pending notifications")
    }
    
    func removePendingNotifications(for humidor: Humidor) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiers = requests.filter { request in
                guard let humidorId = request.content.userInfo["humidorId"] as? String else {
                    return false
                }
                return humidorId == String(describing: humidor.persistentModelID)
            }.map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
            self.logger.debug("Removed \(identifiers.count) notifications for humidor")
        }
    }
} 