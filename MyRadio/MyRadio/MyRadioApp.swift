//
//  MyRadioApp.swift
//  MyRadio
//
//  Created by vasil on 6.03.26.
//

import SwiftUI

@main
struct MyRadioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
