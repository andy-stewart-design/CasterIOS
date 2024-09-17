//
//  ItunesResult.swift
//  Caster
//
//  Created by Andy Stewart on 9/17/24.
//

import Foundation

struct Podcast: Codable, Identifiable {
    let wrapperType: String
    let artistName: String
    let collectionName: String
    let primaryGenreName: String
    let genres: [String]
    let artworkUrl100, artworkUrl60, artworkUrl30: String?
    
    // Custom ID property
    let id: UUID
    
    // Custom initializer
    init(wrapperType: String, artistName: String, collectionName: String, primaryGenreName: String, genres: [String], artworkUrl100: String?, artworkUrl60: String?, artworkUrl30: String?) {
        self.wrapperType = wrapperType
        self.artistName = artistName
        self.collectionName = collectionName
        self.primaryGenreName = primaryGenreName
        self.genres = genres
        self.artworkUrl100 = artworkUrl100
        self.artworkUrl60 = artworkUrl60
        self.artworkUrl30 = artworkUrl30
        
        // Generate a unique ID
        self.id = UUID()
    }
    
    // Codable initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        wrapperType = try container.decode(String.self, forKey: .wrapperType)
        artistName = try container.decode(String.self, forKey: .artistName)
        collectionName = try container.decode(String.self, forKey: .collectionName)
        primaryGenreName = try container.decode(String.self, forKey: .primaryGenreName)
        genres = try container.decode([String].self, forKey: .genres)
        artworkUrl100 = try container.decodeIfPresent(String.self, forKey: .artworkUrl100)
        artworkUrl60 = try container.decodeIfPresent(String.self, forKey: .artworkUrl60)
        artworkUrl30 = try container.decodeIfPresent(String.self, forKey: .artworkUrl30)
        
        // Generate a unique ID
        id = UUID()
    }
    
    // CodingKeys enum
    enum CodingKeys: String, CodingKey {
        case wrapperType, artistName, collectionName, primaryGenreName, genres, artworkUrl100, artworkUrl60, artworkUrl30
    }
}

struct PodcastResults: Codable {
    let resultCount: Int
    let results: [Podcast]
}
