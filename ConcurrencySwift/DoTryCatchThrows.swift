//
//  DoTryCatchThrows.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 09/09/25.
//

import SwiftUI

// This class demonstrates three common ways to handle potential failures in Swift.
class DoCatchTryThrowsBootcampDataManager {

    // This flag controls whether the functions succeed or fail.
    // Set to 'false' to test the error paths.
    // Set to 'true' to test the success paths.
    let isActive = false

    // Pattern 1: Returning an optional tuple (C-style / older Swift)
    // This pattern is verbose and less safe because the caller has to manually
    // check for both a value and an error. It's possible to mishandle the state.
    func getTitle() -> (title: String?, error: Error?) {
        if isActive {
            return ("NEW TEXT!", nil)
        } else {
            return (nil, URLError(.badURL))
        }
    }

    // Pattern 2: Using the Result type
    // This is a modern, type-safe approach. The Result enum guarantees that you
    // either get a .success(value) or a .failure(error), never both or neither.
    func getTitle2() -> Result<String, Error> {
        if isActive {
            return .success("NEW TEXT!")
        } else {
            return .failure(URLError(.badURL))
        }
    }

    // Pattern 3: Using 'throws'
    // This is the most idiomatic and common way to handle synchronous errors in Swift.
    // The 'throws' keyword signals that the function can fail. The compiler forces
    // the caller to handle the potential error using a do-catch block or by propagating the error.
    func getTitle3() throws -> String {
        if isActive {
            return "NEW TEXT!"
        } else {
            throw URLError(.badURL)
        }
    }

    // Another example of a throwing function to demonstrate control flow.
    func getTitle4() throws -> String {
        if isActive {
            return "Finally, NEW TEXT!"
        } else {
            throw URLError(.badURL)
        }
    }

}

class DoCatchTryThrowsBootcampViewModel: ObservableObject {

    @Published var text: String = "Starting text."
    let manager = DoCatchTryThrowsBootcampDataManager()

    func fetchTitle() {

        // --- Handling Pattern 1: Optional Tuple ---
        /*
         let returnedValue = self.manager.getTitle()
         if let newTitle = returnedValue.title {
         self.text = newTitle
         } else if let error = returnedValue.error {
         self.text = "Error: \(error.localizedDescription)"
         }
         */

        // --- Handling Pattern 2: Result Type ---
        /*
         let result = self.manager.getTitle2()
         switch result {
         case .success(let newTitle):
         self.text = newTitle
         case .failure(let error):
         self.text = "Error: \(error.localizedDescription)"
         }
         */

        // --- Handling Pattern 3: Do-Catch with 'throws' ---
        // The 'try' keyword is used to call a function that can throw an error.
        // It must be inside a 'do' block.
        do {
            // If getTitle3() succeeds, its return value is assigned to newTitle.
            let newTitle = try self.manager.getTitle3()
            self.text = newTitle

            // This line will only be reached if getTitle3() did NOT throw an error.
            let newTitle2 = try self.manager.getTitle4()
            self.text = newTitle2

            // KEY CONCEPT: Once a function inside a 'do' block throws an error,
            // control immediately jumps to the 'catch' block.
            // No further code inside the 'do' block is executed.
        } catch let error {
            // The 'catch' block executes if any 'try' statement above it fails.
            // The thrown error is automatically passed into this block.
            self.text = "Error: \(error.localizedDescription)"
        }
    }

}

struct DoCatchTryThrowsBootcamp: View {

    @StateObject private var viewModel = DoCatchTryThrowsBootcampViewModel()

    var body: some View {
        Text(viewModel.text)
            .frame(width: 300, height: 300)
            .background(Color.blue)
            .foregroundColor(.white)
            .onTapGesture {
                viewModel.fetchTitle()
            }
    }
}
