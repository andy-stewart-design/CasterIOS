//
//  ContentView.swift
//  Caster
//
//  Created by Andy Stewart on 9/4/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PodcastViewModel()
    
    var body: some View {
        List(viewModel.podcasts) { podcast in
            HStack(spacing: 16) {
                PodcastImageView(podcast: podcast)
                VStack(alignment: .leading, spacing: 6) {
                    Text(podcast.collectionName)
                        .font(.headline)
                        .lineLimit(2)
                        .truncationMode(.tail)
                    Text(podcast.primaryGenreName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(PlainListStyle())
        .onAppear {
            viewModel.loadData()
        }
    }
}

#Preview {
    ContentView()
}

struct PodcastImageView: View {
    let podcast: Podcast
    
    var body: some View {
        AsyncImage(url: getBestImageURL()) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Color.gray
            @unknown default:
                Color.gray
            }
        }
        .frame(width: 64, height: 64)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
    }
    
    private func getBestImageURL() -> URL? {
        if let url100 = podcast.artworkUrl100 {
            return URL(string: url100)
        } else if let url60 = podcast.artworkUrl60 {
            return URL(string: url60)
        } else if let url30 = podcast.artworkUrl30 {
            return URL(string: url30)
        }
        return nil
    }
}

// --------------------------------------------------------------
// ITUNES API PODCAST SEARCH
// --------------------------------------------------------------

class PodcastViewModel: ObservableObject {
    @Published var podcasts = [Podcast]()
    @Published var error: Error?
    
    func createURL(query: String, limit: Int = 20, page: Int = 0) -> URL? {
        let baseURL = "https://itunes.apple.com/search"
        
        let queryItems = [
            URLQueryItem(name: "term", value: query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "limit", value: String(max(1, limit))),
            URLQueryItem(name: "offset", value: String(max(0, limit * page)))
        ]
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = queryItems
        
        return components?.url
    }
}

extension PodcastViewModel {
    @MainActor
    func fetchPodcasts() async throws {
        do {
            guard let url = createURL(query: "javascript") else { throw CoinError.invalidURL }
            print(url)
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw CoinError.serverError }
            guard let podcastData = try? JSONDecoder().decode(PodcastResults.self, from: data) else { throw CoinError.invalidData }
            
            self.podcasts.append(contentsOf: podcastData.results)
        } catch {
            print(error)
            self.error = error
        }
    }
        
    func loadData() {
        Task(priority: .medium) {
            try await fetchPodcasts()
        }
    }
}


