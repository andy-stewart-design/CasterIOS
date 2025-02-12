//
//  RSSParser.swift
//  Caster
//
//  Created by Andy Stewart on 10/16/24.
//

import Foundation
import XMLCoder

struct RSS: Codable {
    let channel: Channel
}

struct Channel: Codable {
    let title: String
    let author: String
    let description: String
    let link: String
    let items: [Item]
    let pubDate: String
    
    enum CodingKeys: String, CodingKey {
        case title, description, link, pubDate
        case items = "item"
        case author = "itunes:author"
    }
}

struct Item: Codable, Identifiable {
    let title: String
    let description: String
    let pubDate: String
    let link: String
    
    var id: String { link } // Use link as a unique identifier
}

class RSSParser {
    static func parseFeed(url: String) async throws -> Channel {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let (data, res) = try await URLSession.shared.data(from: url)
        guard (res as? HTTPURLResponse)?.statusCode == 200 else { throw CoinError.serverError }
        
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = false
        
        let rss = try decoder.decode(RSS.self, from: data)
        return rss.channel
    }
}
