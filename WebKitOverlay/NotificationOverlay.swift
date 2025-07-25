import SwiftUI

struct NotificationOverlay: View {
    @State private var isVisible: Bool = false
    @State private var message: String = ""
    @State private var notificationType: NotificationType = .info
    
    enum NotificationType {
        case info
        case success
        case warning
        
        var backgroundColor: Color {
            switch self {
            case .info:
                return Color.blue.opacity(0.8)
            case .success:
                return Color.green.opacity(0.8)
            case .warning:
                return Color.orange.opacity(0.8)
            }
        }
        
        var iconName: String {
            switch self {
            case .info:
                return "info.circle.fill"
            case .success:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if isVisible {
                HStack(spacing: 8) {
                    Image(systemName: notificationType.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(notificationType.backgroundColor)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBottomNotification)) { notification in
            if let userInfo = notification.userInfo,
               let msg = userInfo["message"] as? String {
                let type = userInfo["type"] as? String ?? "info"
                showNotification(message: msg, type: NotificationType.from(string: type))
            }
        }
    }
    
    private func showNotification(message: String, type: NotificationType) {
        self.message = message
        self.notificationType = type
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = false
            }
        }
    }
}

extension NotificationOverlay.NotificationType {
    static func from(string: String) -> NotificationOverlay.NotificationType {
        switch string.lowercased() {
        case "success":
            return .success
        case "warning":
            return .warning
        default:
            return .info
        }
    }
}

extension Notification.Name {
    static let showBottomNotification = Notification.Name("showBottomNotification")
}

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func showNotification(message: String, type: String = "info") {
        let userInfo: [String: Any] = [
            "message": message,
            "type": type
        ]
        
        NotificationCenter.default.post(
            name: .showBottomNotification,
            object: nil,
            userInfo: userInfo
        )
    }
    
    func showInfo(_ message: String) {
        showNotification(message: message, type: "info")
    }
    
    func showSuccess(_ message: String) {
        showNotification(message: message, type: "success")
    }
    
    func showWarning(_ message: String) {
        showNotification(message: message, type: "warning")
    }
}
