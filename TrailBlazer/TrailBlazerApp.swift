//
//  TrailBlazerApp.swift
//  TrailBlazer
//
//  Created by Neelay Singhvi on 4/2/23.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        let _ = Firestore.firestore()
        let _ = Storage.storage()
        return true
    }
}

@main
struct TrailBlazerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var masterViewModel = MasterViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }.environmentObject(masterViewModel)
        }
    }
}
