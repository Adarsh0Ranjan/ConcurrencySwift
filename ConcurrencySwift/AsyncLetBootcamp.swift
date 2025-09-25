//
//  AsyncLetBootcamp.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 25/09/25.
//


import SwiftUI

struct AsyncLetBootcamp: View {
    
    @State private var images: [UIImage] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let url = URL(string: "https://picsum.photos/300")!
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                    }
                }
            }
            .navigationTitle("Async Let 🥳")
            .onAppear {
                /*
                Task {
                    do {
                        // This is a sequential approach to fetching data.
                        // Each 'await' pauses the task, meaning the next network request
                        // will not start until the previous one has fully completed.
                        // This is significantly slower than running the requests in parallel.
                        let image1 = try await fetchImage()
                        self.images.append(image1)

                        let image2 = try await fetchImage()
                        self.images.append(image2)

                        let image3 = try await fetchImage()
                        self.images.append(image3)

                        let image4 = try await fetchImage()
                        self.images.append(image4)

                    } catch {
                        // Handle any errors that might be thrown by fetchImage()
                    }
                }*/
            }

            .onAppear {
                // By creating multiple, separate Task blocks, these operations will run concurrently.
                // The system will start all of these tasks at roughly the same time,
                // allowing the network requests to happen in parallel.
                /*
                Task {
                    do {
                        let image1 = try await fetchImage()
                        self.images.append(image1)
                    } catch {
                        // Handle error for the first image fetch
                    }
                }

                Task {
                    do {
                        let image2 = try await fetchImage()
                        self.images.append(image2)
                    } catch {
                        // Handle error for the second image fetch
                    }
                }

                Task {
                    do {
                        // Note: While this Task runs in parallel with the others,
                        // the operations *inside* it are still sequential.
                        // The fetch for image4 will only start after image3 is finished.
                        let image3 = try await fetchImage()
                        self.images.append(image3)

                        let image4 = try await fetchImage()
                        self.images.append(image4)
                    } catch {
                        // Handle error for the third and fourth image fetches
                    }
                }
                 */
            }

            .onAppear {
                Task {
                    do {
                        // 'async let' starts each of these function calls in parallel.
                        // The code does not wait for them to finish here; it just kicks them off.
                        async let fetchImage1 = fetchImage()
                        async let fetchImage2 = fetchImage()
                        async let fetchImage3 = fetchImage()
                        async let fetchImage4 = fetchImage()

                        // The 'await' keyword here pauses the task until all the 'async let'
                        // bindings above have completed. The results are returned as a tuple.
                        // 'try' is used for each because any of the individual tasks could throw an error.
                        // - Using 'try?': If you are okay with some tasks failing, you can use 'try?'
                        // A key feature of `async let` is that each binding can call a different function, some what like dispatch group
                        // with a completely different return type. They do not all need to be the same.
                        let (image1, image2, image3, image4) = await (try fetchImage1, try fetchImage2, try fetchImage3, try fetchImage4)

                        self.images.append(contentsOf: [image1, image2, image3, image4])

                    } catch {
                        // Handle any error thrown by the awaited tasks.
                    }
                }
            }
        }
    }
    
    // This function fetches a single image and can throw an error.
    func fetchImage() async throws -> UIImage {
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError(.badURL)
            }
        } catch {
            // Re-throw the error to be handled by the caller.
            throw error
        }
    }
}

struct AsyncLetBootcamp_Previews: PreviewProvider {
    static var previews: some View {
        AsyncLetBootcamp()
    }
}


/*


 Swift Concurrency async let Summary: Q&A
 Level 1: Foundational Performance

 Question: The code comments illustrate three ways to fetch four images: sequential await calls, multiple separate Tasks, and async let. Compare these three patterns in terms of performance and explain which is the most efficient.

 Answer:

 Sequential await is the least performant. It executes each network request one after another, so the total time is the sum of all four downloads.

 Multiple Tasks and async let are both highly performant because they execute the network requests concurrently (in parallel). They start all downloads at roughly the same time, so the total time is only as long as the single slowest download. async let is generally the preferred modern syntax for this specific scenario.

 Level 2: Syntax and Result Aggregation

 Question: Why is async let considered a more structured and convenient approach for running a fixed number of concurrent operations compared to creating multiple separate Tasks?

 Answer:
 While both achieve concurrency, async let is more structured because it ties the concurrent operations together into a single, easy-to-read block. It simplifies result aggregation by providing a single suspension point (await) where all the results are delivered together in a well-defined tuple or array.

 With multiple separate Tasks, each operation runs in its own isolated context. Combining their results requires more complex state management (like appending to an array from different threads, which can be unsafe without proper synchronization) and makes the code harder to follow. async let keeps the code flow looking linear and simple.

 Question: Explain the error handling and cancellation behavior of async let. If you start four image downloads and one fails, how does the outcome differ when using try versus try?

 Answer:
 This behavior is a core principle of Structured Concurrency, but the outcome depends entirely on how you handle potential errors.
 The Default Behavior with try (All or Nothing)

 When you use try to await the results, the system enforces a strict "all or nothing" policy.

 Error Propagation: If any single download fails and throws an error, the await expression that is waiting for all the results will immediately stop and re-throw that specific error. You will not receive a partial result with the images that succeeded; the assignment will fail, and execution will jump to your catch block.

 Automatic Cancellation: As soon as that error is thrown, the system automatically cancels any of the other async let tasks in that group that have not yet finished. This is a powerful optimization that prevents other tasks from continuing to run and waste network and battery resources. It ensures the entire group of related tasks is torn down cleanly when one part of it fails.

 Handling Partial Success with try? (Best Effort)

 You can avoid the "all or nothing" behavior by using try?. This changes the logic from "fail completely" to "succeed with what you can."

 Error Transformation: try? transforms a throwing expression into an optional-returning one. If a download fails, it does not throw an error. Instead, its result simply becomes nil.

 Successful Await: Because no error is thrown, the await expression succeeds. The assignment happens, and your catch block is not triggered for that failure. You receive a tuple where each element is an optional (e.g., (UIImage?, UIImage?, ...)), and the failed tasks are represented by nil. You are then responsible for filtering out these nil values.

 Impact on Cancellation: This is a critical difference. Since no error is thrown, the scope does not exit prematurely. Therefore, the other running tasks are NOT automatically cancelled. They are allowed to run to completion. This is the trade-off: you get the successful results, but you don't get the optimization of cancelling the remaining work.
 */
