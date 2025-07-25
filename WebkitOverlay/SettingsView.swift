import SwiftUI

class SettingsWindowManager: ObservableObject {
    var dismissWindow: (() -> Void)?
    
    func dismiss() {
        dismissWindow?()
    }
}

struct SettingsView: View {
    // MARK: - Constants
    private enum DefaultSettings {
        static let url = "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1"
        static let refreshInterval: Double = 300 // 5分
        static let safariSpoofing = true
        static let opacity: Double = 0.8
    }
    
    private enum WindowSize {
        static let width: CGFloat = 450
        static let height: CGFloat = 520
    }
    
    // MARK: - State
    @EnvironmentObject private var windowManager: SettingsWindowManager
    @State private var defaultURL: String = DefaultSettings.url
    @State private var autoRefreshInterval: Double = DefaultSettings.refreshInterval
    @State private var enableSafariSpoofing: Bool = DefaultSettings.safariSpoofing
    @State private var opacity: Double = DefaultSettings.opacity
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let refreshIntervals: [Double] = [60, 300, 600, 1800, 3600] // 1分, 5分, 10分, 30分, 1時間
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                urlSettingSection
                refreshSettingSection
                safariSettingSection
                opacitySettingSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            buttonSection
        }
        .frame(width: WindowSize.width, height: WindowSize.height)
        .onAppear {
            loadSettings()
        }
        .alert("設定", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var urlSettingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("デフォルトURL", systemImage: "globe")
            
            VStack(alignment: .leading, spacing: 6) {
                TextField("URLを入力してください", text: $defaultURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Webビューで表示するデフォルトのURLを設定します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var refreshSettingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("自動更新間隔", systemImage: "arrow.clockwise")
            
            VStack(alignment: .leading, spacing: 6) {
                Picker("更新間隔", selection: $autoRefreshInterval) {
                    Text("1分").tag(60.0)
                    Text("5分").tag(300.0)
                    Text("10分").tag(600.0)
                    Text("30分").tag(1800.0)
                    Text("1時間").tag(3600.0)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Webページが自動的に更新される間隔を設定します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var safariSettingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Safari偽装", systemImage: "safari")
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Toggle("Safari偽装を有効にする", isOn: $enableSafariSpoofing)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    Spacer()
                }
                
                Text("WebサイトにSafariブラウザとして認識させます。一部のサイトで必要な場合があります")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var opacitySettingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("透過度", systemImage: "circle.lefthalf.filled")
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("不透明")
                        .font(.caption)
                    
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.1)
                    
                    Text("透明")
                        .font(.caption)
                }
                
                Text("透過度: \(Int(opacity * 100))% - オーバーレイウィンドウの透過度を調整します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var buttonSection: some View {
        HStack(spacing: 12) {
            Button("デフォルトに戻す") {
                resetToDefaults()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
            
            Button("キャンセル") {
                windowManager.dismiss()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("保存") {
                saveSettings()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding(12)
    }
    
    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
        }
    }
    
    private func loadSettings() {
        let userDefaults = UserDefaults.standard
        
        defaultURL = userDefaults.string(forKey: "defaultURL") ?? DefaultSettings.url
        autoRefreshInterval = userDefaults.double(forKey: "autoRefreshInterval")
        if autoRefreshInterval == 0 {
            autoRefreshInterval = DefaultSettings.refreshInterval
        }
        enableSafariSpoofing = userDefaults.bool(forKey: "enableSafariSpoofing")
        if userDefaults.object(forKey: "enableSafariSpoofing") == nil {
            enableSafariSpoofing = DefaultSettings.safariSpoofing
        }
        opacity = userDefaults.double(forKey: "opacity")
        if opacity == 0 {
            opacity = DefaultSettings.opacity
        }
    }
    
    private func saveSettings() {
        let userDefaults = UserDefaults.standard
        
        // URL検証
        if !isValidURL(defaultURL) {
            alertMessage = "有効なURLを入力してください"
            showingAlert = true
            return
        }
        
        userDefaults.set(defaultURL, forKey: "defaultURL")
        userDefaults.set(autoRefreshInterval, forKey: "autoRefreshInterval")
        userDefaults.set(enableSafariSpoofing, forKey: "enableSafariSpoofing")
        userDefaults.set(opacity, forKey: "opacity")
        
        // 設定変更の通知を送信
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
        
        // 設定ウィンドウを閉じる
        windowManager.dismiss()
    }
    
    private func resetToDefaults() {
        defaultURL = DefaultSettings.url
        autoRefreshInterval = DefaultSettings.refreshInterval
        enableSafariSpoofing = DefaultSettings.safariSpoofing
        opacity = DefaultSettings.opacity
    }
    
    private func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
}

#Preview {
    SettingsView()
}
