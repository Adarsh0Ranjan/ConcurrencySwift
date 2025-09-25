//
//  TaskBootcampViewModel.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 24/09/25.
//


import SwiftUI

class TaskBootcampViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    @Published var image2: UIImage? = nil

    func fetchImage() async {
        do {
            guard let url = URL(string: "https://picsum.photos/200") else { return }

            // --- Point 1: Check before starting expensive work ---
            // This is a point of "cooperative cancellation".
            // If the task was cancelled before the network request even started,
            // this line will throw a CancellationError and the function will exit immediately.
            try Task.checkCancellation()

            // 'await' pauses this function while the network request runs on a background thread.
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            
            // WARNING: Potential data race. After the 'await', this code could resume on a background thread.
            // Updating a @Published property from a background thread is not safe and will cause purple warnings in Xcode.
            // The class should be marked with @MainActor to fix this.
            self.image = UIImage(data: data)
        } catch {
            print(error.localizedDescription)
        }
    }

    func fetchImage2() async {
        do {
            guard let url = URL(string: "https://picsum.photos/200") else { return }

            // 'await' pauses this function while the network request runs on a background thread.
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)

            // WARNING: Potential data race. After the 'await', this code could resume on a background thread.
            // Updating a @Published property from a background thread is not safe and will cause purple warnings in Xcode.
            // The class should be marked with @MainActor to fix this.
            self.image2 = UIImage(data: data)
        } catch {
            print(error.localizedDescription)
        }
    }

}

struct TaskBootcamp: View {
    @StateObject private var viewModel = TaskBootcampViewModel()
    @State private var fetchImageTask: Task<(), Never>? = nil
    var body: some View {
        VStack(spacing: 40) {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            
            if let image2 = viewModel.image2 {
                Image(uiImage: image2)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        /*
         .onAppear {
         // This creates a single asynchronous Task.
         Task {
         // Inside this single Task, the 'await' keywords create a sequential order.
         
         // 1. The code calls and waits for fetchImage() to complete entirely.
         await viewModel.fetchImage()
         
         // 2. ONLY AFTER fetchImage() is finished, the code calls and waits for fetchImage2().
         // The total time taken will be (time for fetchImage) + (time for fetchImage2).
         await viewModel.fetchImage2()
         }
         }
         */
        
        .onAppear {
            /*
             // This approach creates two separate, independent Tasks.
             // Both Tasks are created and started at almost the exact same time.
             
             // This first Task starts running fetchImage() immediately.
             Task {
             await viewModel.fetchImage()
             }
             
             // This second Task ALSO starts running fetchImage2() immediately,
             // without waiting for the first Task to finish.
             Task {
             await viewModel.fetchImage2()
             }
             
             // The two network requests will run in parallel. There is no guarantee which one
             // will finish first. The total time taken will be roughly the time of the LONGER of the two tasks.
             */
        }
        
        .onAppear(perform: {
            
            /*
             // The ideal, theoretical execution order of priorities from HIGHEST to LOWEST is:
             // 1. .userInitiated  (Tasks the user is actively waiting on, like UI updates)
             // 2. .high
             // 3. .medium         (The default priority if none is specified)
             // 4. .utility
             // 5. .low
             // 6. .background     (Tasks with no time constraints, like database cleaning)
             
             // IMPORTANT: This ideal order is a suggestion to the system, not a strict guarantee.
             // The actual execution order can vary based on system load and timing.
             
             Task(priority: .high) {
             // By adding 'await Task.sleep', we introduce a suspension point.
             // The task pauses here for 2 seconds and RELEASES its thread.
             // This gives other, lower-priority tasks a chance to execute while this one is sleeping.
             //                try? await Task.sleep(nanoseconds: 2_000_000_000)
             
             
             // await Task.yield() is a tool for cooperative multitasking.
             // It voluntarily and immediately suspends the current task for a very brief moment,
             // effectively telling the scheduler: "I'm pausing now, please run other pending tasks."
             
             // How is it different from Task.sleep()?
             // - Task.sleep() pauses for a DEFINED duration (e.g., 2 seconds). The task is unavailable for that whole time.
             //   It's used when you need to wait for a specific period.
             // - Task.yield() pauses for an UNDEFINED, extremely short duration. It's not about waiting; it's about
             //   giving up the execution thread so other tasks can make progress. It's used to prevent a single
             //   long-running task from blocking other important work.
             
             // By yielding here, this high-priority task allows the scheduler to immediately run other pending tasks
             // (like .userInitiated, .medium, etc.) that were created at the same time.
             await Task.yield()
             print("high : \(Thread.current) : \(Task.currentPriority)")
             }
             
             Task(priority: .userInitiated) {
             print("userInitiated : \(Thread.current) : \(Task.currentPriority)")
             }
             
             Task(priority: .low) {
             print("low : \(Thread.current) : \(Task.currentPriority)")
             }
             
             Task(priority: .medium) {
             print("medium : \(Thread.current) : \(Task.currentPriority)")
             }
             
             Task(priority: .background) {
             print("background : \(Thread.current) : \(Task.currentPriority)")
             }
             
             Task(priority: .utility) {
             print("utility : \(Thread.current) : \(Task.currentPriority)")
             }
             */
        })

        .onAppear(perform: {
            // A standard nested Task inherits the priority from its parent.
            /*
             Task(priority: .userInitiated) {
             print("userInitiated : \(Thread.current) : \(Task.currentPriority)")

             Task {
             // This inner task also has .userInitiated priority.
             print("userInitiated2 : \(Thread.current) : \(Task.currentPriority)")
             }
             }
             */

            /*
            Task(priority: .userInitiated) {
                print("userInitiated : \(Thread.current) : \(Task.currentPriority)")

                // Task.detached creates a new, independent task.
                // It does NOT inherit the parent's priority or context.
                // The parent task will not wait for it to finish, and cancellation is not passed down.
                // Use with caution as it breaks the parent-child structure.
                Task.detached {
                    print("detached : \(Thread.current) : \(Task.currentPriority)")
                }
            }
             */
        })

        // --- Manual Task Cancellation (Older Approach) ---
        // This pattern requires you to manage the task's lifecycle yourself.
        .onAppear(perform: {
            // 1. When the view appears, we create a task and store a reference to it.
            fetchImageTask = Task {
                await viewModel.fetchImage()
            }
        })
        .onDisappear(perform: {
            // 2. When the view disappears, we must explicitly cancel the stored task.
            // This prevents work from continuing after the view is gone.
            fetchImageTask?.cancel()
        })


        // --- Automatic Task Cancellation (Modern & Recommended Approach) ---
        // The `.task` view modifier handles the entire lifecycle for you.
        .task {
            // 1. This code runs automatically when the view appears.
            // 2. If the view disappears while this task is running, SwiftUI
            //    AUTOMATICALLY cancels it.
            // This is the preferred method as it's cleaner, safer, and requires less code.
            await viewModel.fetchImage()
        }

    }
}

struct TaskBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        TaskBootcamp()
    }
}


/*
 Level 1: Foundational Concepts

 Question: How does the structure of your Task initializations affect whether operations run one after another (sequentially) or at the same time (in parallel)? Describe the performance implications of each approach.

 Answer:
 The structure is critical. Placing multiple await calls inside a single Task block creates a sequential workflow. The second operation will not even begin until the first one has fully completed. The total time taken is the sum of all operations.

 Conversely, creating multiple, separate Task blocks results in parallel execution. The system initiates all tasks at roughly the same time, and they run concurrently. This is far more efficient for independent operations, as the total time taken is only as long as the single longest-running task.

 Level 2: Task Scheduling and Cooperation

 Question: Swift's task priorities are suggestions, not guarantees. What does this mean in practice? Furthermore, explain the difference between Task.sleep and Task.yield in the context of cooperative multitasking.

 Answer:
 Stating that priorities are "suggestions" means that while you are providing a strong hint to the system about a task's importance, the operating system's scheduler makes the final decision. It considers many factors, like overall system load, thermal state, and available cores. A high-priority task might still be delayed if the system is heavily constrained.

 Task.sleep and Task.yield both pause a task, but for different reasons. Task.sleep pauses execution for a specific, defined duration; its purpose is to wait. Task.yield, on the other hand, pauses for a very brief, undefined moment. Its purpose is not to wait, but to "yield" its execution time, immediately giving the scheduler an opportunity to run other pending tasks. It's a tool to prevent a single long-running task from blocking other important work.

 Level 3: Structured Concurrency

 Question: Explain the core principles of "Structured Concurrency" by contrasting a standard nested Task with a Task.detached. What key contextual information fails to propagate to a detached task, and what are the risks of using it?

 Answer:
 Structured Concurrency organizes tasks into a parent-child hierarchy, ensuring that a child task's lifetime is contained within its parent's scope.

 A nested task is a child in this hierarchy. It inherits critical context from its parent, including its priority, task-local values, and most importantly, its cancellation status. If the parent task is cancelled, all its children are automatically cancelled.

 A detached task explicitly opts out of this structure. It is created as a new, top-level task with no parent. It does not inherit priority or any other context, and it will not be cancelled when its originating task is. The risks of using it are significant: the parent task will not wait for it to complete, and it can easily lead to resource leaks or unintended background work if not managed with extreme care.

 Level 4: Advanced Application & Cancellation

 Question: Describe the "cooperative cancellation" model in Swift. How do the .task view modifier and the try Task.checkCancellation() method work together to create a robust, lifecycle-aware asynchronous operation in SwiftUI?

 Answer:
 The cancellation model is "cooperative" because a task is never forcefully terminated. Instead, a cancellation request is sent, which sets a flag on the task. The running code within the task must then actively and periodically check for this flag and decide to stop itself.

 The .task modifier and checkCancellation form a complete system for this in SwiftUI.

 The Request: The .task modifier is responsible for the task's lifecycle. When the associated SwiftUI view disappears, it automatically sends the cancellation request to the task it manages.

 The Checkpoint: The try Task.checkCancellation() call is the checkpoint inside your asynchronous function. When this line is executed, it checks the task's cancellation flag. If the flag has been set by the .task modifier, this call throws a CancellationError, which cleanly and immediately stops the function's execution.

 Together, they create a robust pattern where a view's lifecycle automatically and safely controls the execution of its related asynchronous work, preventing wasted resources and unexpected behavior.
 */
