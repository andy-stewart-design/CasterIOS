//
//  ContentView.swift
//  Caster
//
//  Created by Andy Stewart on 9/4/24.
//

import SwiftUI
import Combine
import Foundation
import CommonCrypto

struct ContentView: View {
    @StateObject private var viewModel = PodcastViewModel()
    
    var body: some View {
        SearchBar(text: $viewModel.searchText, onCancel: viewModel.clearPodcasts)
        
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
            viewModel.loadDataAsync()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let onCancel: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor (Color.gray)
            
            TextField("Search by name or symbol...", text: $text)
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .padding(16)
                        .offset(x:12)
                        .opacity(text.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            UIApplication.shared.endEditing()
                            onCancel()
                            text = ""
                        }
                    , alignment: .trailing
                )
        }
        .font (.headline)
        .padding()
        .padding(8)
        .background (
            RoundedRectangle (cornerRadius: 8)
                .fill(Color(.systemGray6))
                .padding()
        )
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

struct ItunesResult: Codable, Identifiable {
    let author: String
    let title: String
    let primaryGenreName: String
    let feedUrl: String
    let artworkUrl600, artworkUrl100, artworkUrl60, artworkUrl30: String?
    let id: Int
    
    enum CodingKeys: String, CodingKey {
        case primaryGenreName, feedUrl, artworkUrl600, artworkUrl100, artworkUrl60, artworkUrl30
        case id = "collectionId"
        case title = "collectionName"
        case author = "artistName"
    }
}

struct ItunesResponse: Codable {
    let resultCount: Int
    let results: [ItunesResult]
}

struct PodcastIndexResult: Codable, Identifiable {
    let id, dead, episodeCount: Int
    let title, description: String
    let categories: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id = "itunesId"
        case title, description, episodeCount, categories, dead
    }
}

struct PodcastIndexResponse: Codable {
    let status: String
    let feed: PodcastIndexResult
}

class PodcastViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var podcasts = [Podcast]()
    @Published var error: Error?
    
    func fetchItunesData() async throws {
        let urlString = "https://itunes.apple.com/search?term=pod&media=podcast&limit=5"
        guard let url = URL(string: urlString) else { throw(CoinError.invalidURL) }
        let (data, res) = try await URLSession.shared.data(from: url)
//        print(String(data: data, encoding: .utf8) ?? "")
        guard (res as? HTTPURLResponse)?.statusCode == 200 else { throw CoinError.serverError }
        let podcastData = try JSONDecoder().decode(ItunesResponse.self, from: data)
//        print(podcastData.results[0].feedUrl)
        print(podcastData.results[0].feedUrl)
        await fetchRSSItems(url: podcastData.results[0].feedUrl)
    }
    
    func fetchRSSItems(url: String) async {
        do {
            let channel = try await RSSParser.parseFeed(url: url)
            print("Title: \(channel.title)")
            print("Author: \(channel.author)")
            print("Description: \(channel.description)")
            print("Link: \(channel.link)")
//            for item in channel.items {
//                print("Title: \(item.title)")
//                print("Description: \(item.description)")
//                print("Published Date: \(item.pubDate)")
//                print("Link: \(item.link)")
//                print("ID: \(item.id)")
//                print("---")
//            }
        } catch {
            print("Error fetching RSS feed: \(error)")
            if let urlError = error as? URLError {
                print("URLError code: \(urlError.code.rawValue)")
            }
        }
    }
    
    func fetchPodcastIndexData() async throws {
        let apiKey = "FPRJDUTSW8WSDW8JQCKK"
        let apiSecret = "GkkSLJPFUte6Kdr5aq2R8EKZ7UXrUjF5u^MjrWwW"
        let apiHeaderTime = String(Int(Date().timeIntervalSince1970))
        let hash = (apiKey + apiSecret + apiHeaderTime).sha1()
        
//        let urlString = "https://api.podcastindex.org/api/1.0/search/bytitle?q=waveform&fulltext&similar"
        let urlString = "https://api.podcastindex.org/api/1.0/podcasts/byitunesid?id=1474429475&max=5&pretty"
        guard let url = URL(string: urlString) else { throw(CoinError.invalidURL) }
        
        var request = URLRequest(url: url, timeoutInterval: Double.infinity)
        
        request.addValue("CasterApp/0.0.1", forHTTPHeaderField: "User-Agent")
        request.addValue(apiKey, forHTTPHeaderField: "X-Auth-Key")
        request.addValue(apiHeaderTime, forHTTPHeaderField: "X-Auth-Date")
        request.addValue(hash, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        let (data, res) = try await URLSession.shared.data(for: request)
        print(String(data: data, encoding: .utf8) ?? "")
        guard (res as? HTTPURLResponse)?.statusCode == 200 else { throw CoinError.serverError }
        let podcastData = try JSONDecoder().decode(PodcastIndexResponse.self, from: data)
//        print(podcastData)
    }
    
    func loadDataAsync() {
        Task {
            do {
                try await fetchItunesData()
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func clearPodcasts() {
        print("Clearing podcasts")
        podcasts = []
    }
}


extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
