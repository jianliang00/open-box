//
//  OpenBoxApp.swift
//  OpenBox
//
//  Created by jianliang on 2026/1/24.
//

import SwiftUI

@main
struct OpenBoxApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
