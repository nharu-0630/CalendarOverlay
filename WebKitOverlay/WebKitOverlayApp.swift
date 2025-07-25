import SwiftUI

@main
struct WebKitOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 設定画面はAppDelegateで手動管理するため、空のシーンにする
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 0, height: 0)
    }
}
