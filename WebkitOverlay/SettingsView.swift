import SwiftUI

struct SettingsView: View {
    @State private var defaultURL: String = "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1"
    @State private var autoRefreshInterval: Double = 300 // 5分
    @State private var enableSafariSpoofing: Bool = true
    @State private var opacity: Double = 0.8
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let refreshIntervals: [Double] = [60, 300, 600, 1800, 3600] // 1分, 5分, 10分, 30分, 1時間
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            
            ScrollView {
                VStack(spacing: 24) {
                    urlSettingSection
                    refreshSettingSection
                    safariSettingSection
                    opacitySettingSection
                }
                .padding()
            }
            
            buttonSection
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            loadSettings()
        }
        .alert("設定", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("WebKitOverlay 設定")
                .font(.title)
                .fontWeight(.bold)
            
            Text("アプリケーションの動作をカスタマイズできます")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private var urlSettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("デフォルトURL", systemImage: "globe")
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("URLを入力してください", text: $defaultURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Webビューで表示するデフォルトのURLを設定します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var refreshSettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("自動更新間隔", systemImage: "arrow.clockwise")
            
            VStack(alignment: .leading, spacing: 8) {
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
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var safariSettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Safari偽装", systemImage: "safari")
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Safari偽装を有効にする", isOn: $enableSafariSpoofing)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                Text("WebサイトにSafariブラウザとして認識させます。一部のサイトで必要な場合があります")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var opacitySettingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("透過度", systemImage: "circle.lefthalf.filled")
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("不透明")
                        .font(.caption)
                    
                    Slider(value: $opacity, in: 0.1...1.0, step: 0.1)
                    
                    Text("透明")
                        .font(.caption)
                }
                
                Text("透過度: \(Int(opacity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("オーバーレイウィンドウの透過度を調整します")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
    
    private var buttonSection: some View {
        HStack(spacing: 16) {
            Button("デフォルトに戻す") {
                resetToDefaults()
            }
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
            
            Button("キャンセル") {
                // 設定画面を閉じる
                if let window = NSApplication.shared.windows.first(where: { $0.title == "WebKitOverlay 設定" }) {
                    window.close()
                }
            }
            .buttonStyle(BorderedButtonStyle())
            
            Button("保存") {
                saveSettings()
            }
            .buttonStyle(BorderedProminentButtonStyle())
        }
        .padding()
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
        
        defaultURL = userDefaults.string(forKey: "defaultURL") ?? "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1"
        autoRefreshInterval = userDefaults.double(forKey: "autoRefreshInterval")
        if autoRefreshInterval == 0 {
            autoRefreshInterval = 300 // デフォルト5分
        }
        enableSafariSpoofing = userDefaults.bool(forKey: "enableSafariSpoofing")
        if userDefaults.object(forKey: "enableSafariSpoofing") == nil {
            enableSafariSpoofing = true // デフォルト有効
        }
        opacity = userDefaults.double(forKey: "opacity")
        if opacity == 0 {
            opacity = 0.8 // デフォルト80%
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
        
        alertMessage = "設定が保存されました"
        showingAlert = true
        
        // 設定変更の通知を送信
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    private func resetToDefaults() {
        defaultURL = "https://calendar.google.com/calendar/u/0/r/customday?tab=rc1"
        autoRefreshInterval = 300
        enableSafariSpoofing = true
        opacity = 0.8
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