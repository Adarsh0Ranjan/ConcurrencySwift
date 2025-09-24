//
//  AsyncAwaitBootcampViewModel.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 24/09/25.
//


import SwiftUI

// MARK: VIEWMODEL

class AsyncAwaitBootcampViewModel: ObservableObject {

    @Published var dataArray: [String] = []
    
    func addTitle1() {
        // This schedules a task to run on the main thread after a 2-second delay.
        // Since it's already on the main thread, it can safely update the @Published property.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dataArray.append("Title1 : \(Thread.current)")
        }
    }
    
    func addTitle2() {
        // This schedules a task to run on a background (global) thread after a 2-second delay.
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            let title = "Title2 : \(Thread.current)"
            
            // To update the UI (@Published property), we must explicitly dispatch back to the main thread.
            // Modifying UI from a background thread would cause a crash.
            DispatchQueue.main.async {
                self.dataArray.append(title)

                let title3 = "Title3 : \(Thread.current)"
                self.dataArray.append(title3)
            }
        }
    }

    func addAuthor1() async {
        // This part of the function runs on the initial thread it was called from.
        // If called from a @MainActor (like a ViewModel), this will be the main thread.
        let author1 = "Author1 : \(Thread.current)"
        self.dataArray.append(author1)

        // 'await' pauses the function. After the 2-second sleep, execution will likely
        // resume on a generic background thread from Swift's cooperative thread pool.
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // This line will execute on the background thread that the function resumed on.
        let author2 = "Author2 : \(Thread.current)"

        // 'await' pauses again to switch execution to the main thread.
        // The code inside this closure is guaranteed to run on the Main Actor.
        await MainActor.run(body: {
            self.dataArray.append(author2)

            // Since we are still inside the MainActor.run block, this code also runs on the main thread.
            let author3 = "Author3 : \(Thread.current)"
            self.dataArray.append(author3)
        })

        // This 'await' pauses addAuthor1 and transfers control to the addSomething function.
        await addSomething()
    }

    func addSomething() async {
        // This function starts on whatever thread it was called from. In this case, it's the thread
        // that addAuthor1 was on when it called this function (likely a background thread).

        // 'await' pauses this function. After the sleep, it will likely resume on a background thread.
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // This line executes on the background thread that the function resumed on.
        let something1 = "Something1 : \(Thread.current)"

        // 'await' pauses to switch execution to the main thread for the UI update.
        await MainActor.run(body: {
            self.dataArray.append(something1)

            // IMPORTANT: After the MainActor.run block finishes, the execution context is no longer on the main thread.
            // The function will resume on a background thread.
            let something2 = "Something2 : \(Thread.current)"
            self.dataArray.append(something2) // This is a potential data race! It's updating a @Published property from a background thread.
        })
    }
}

// MARK: VIEW

struct AsyncAwaitBootcamp: View {
    
    @StateObject private var viewModel = AsyncAwaitBootcampViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.dataArray, id: \.self) { data in
                Text(data)
            }
        }
        .onAppear {
            Task {
                await viewModel.addAuthor1()

                let finalText = "Final text \(Thread.current)"
                viewModel.dataArray.append(finalText)
            }
//            viewModel.addTitle1()
//            viewModel.addTitle2()
        }
    }
}
