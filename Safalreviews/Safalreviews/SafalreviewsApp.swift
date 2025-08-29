//
//  SafalreviewsApp.swift
//  Safalreviews
//
//  Created by Apple on 29/08/25.
//

import SwiftUI

@main
struct SafalreviewsApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var appState = AppState()
    @StateObject var qaManager = QuickActionsManager.instance
   
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(qaManager)
                .withThemeColors() // Apply accent color globally
        }
    }
}
