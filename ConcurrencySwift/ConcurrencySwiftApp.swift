//
//  ConcurrencySwiftApp.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 09/09/25.
//

import SwiftUI

@main
struct ConcurrencySwiftApp: App {
    var body: some Scene {
        WindowGroup {
            DownloadImageAsync()
        }
    }
}
