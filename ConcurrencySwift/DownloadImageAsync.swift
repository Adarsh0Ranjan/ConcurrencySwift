//
//  DownloadImageAsync.swift
//  ConcurrencySwift
//
//  Created by Adarsh Ranjan on 23/09/25.
//

import SwiftUI

import SwiftUI
import Combine

// MARK: IMAGE LOADER

class DownloadImageAsyncImageLoader {

    let url = URL(string: "https://picsum.photos/200")!

    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        return image
    }

    // @escaping is still needed as the completion handler is called after the network request finishes.
    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {

        // The dataTask's closure still executes on a background thread.
        // We now capture [weak self] to safely call an instance method (handleResponse) from within the closure.
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in

            // We call our synchronous helper function from this background thread.
            // The 'self?' is necessary because 'self' was captured weakly and could be nil.
            let image = self?.handleResponse(data: data, response: response)

            // The result is passed back via the completion handler, still on the background thread.
            completionHandler(image, error)
        }
        .resume()
    }

    func downloadWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
        // The .map operator transforms the output from the dataTaskPublisher (data, response)
        // into a UIImage?, running on a background thread by default.
            .map(handleResponse)
        // If any error occurs in the pipeline, it's caught and passed down.
            .mapError({ $0 })
        // EraseToAnyPublisher hides the complex underlying publisher type.
            .eraseToAnyPublisher()
    }

    // This function uses the modern async/await syntax.
    // 'async' marks it as an asynchronous function. 'throws' means it can propagate errors.
    func downloadWithAsync() async throws -> UIImage? {
        do {
            // 'await' pauses the function here until the network data is returned, without blocking the thread.
            // This URLSession method is built to work with async/await and returns data or throws an error.
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            return handleResponse(data: data, response: response)
        } catch {
            // If 'await' throws an error, it's caught here and re-thrown to the caller.
            throw error
        }
    }
}

// MARK: VIEWMODEL

class DownloadImageAsyncViewModel: ObservableObject {

    @Published var image: UIImage? = nil
    let loader = DownloadImageAsyncImageLoader()
    var cancellables = Set<AnyCancellable>()

    func fetchImage() async {
        /* OLD WAY - Using Escaping Closures
         loader.downloadWithEscaping { [weak self] image, error in
         // We must manually dispatch to the main thread to update the UI.
         DispatchQueue.main.async {
         self?.image = image
         }
         }
         */

        /*
        // NEW WAY - Using Combine
        loader.downloadWithCombine()
        // .sink subscribes to the publisher and provides closures to handle received values and completions.
            .sink { _ in

            } receiveValue: { [weak self] image in
                // The receiveValue closure is called on a background thread from URLSession's publisher.
                // We must explicitly dispatch to the main thread for any UI updates.
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        // .store attaches the subscriber to the ViewModel's lifecycle, ensuring it's cancelled automatically.
            .store(in: &cancellables)
         */

        let image = try? await loader.downloadWithAsync()
        await MainActor.run {
            self.image = image
        }
    }
}

struct DownloadImageAsync: View {

    @StateObject private var viewModel = DownloadImageAsyncViewModel()

    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
        }
        .onAppear {
//            viewModel.fetchImage()

            // for async await
            Task {
                await viewModel.fetchImage()
            }
        }
    }
}

struct DownloadImageAsync_Previews: PreviewProvider {
    static var previews: some View {
        DownloadImageAsync()
    }
}
