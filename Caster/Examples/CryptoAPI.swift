//
//  CryptoAPI.swift
//  Caster
//
//  Created by Andy Stewart on 9/17/24.
//

import SwiftUI

struct CryptoAPI: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    CryptoAPI()
}

// --------------------------------------------------------------
// CRYPTO EXAMPLE
// --------------------------------------------------------------

// COIN MODEL

struct Coin: Codable, Identifiable {
    let id, symbol, name: String
    let image: String
    let currentPrice: Double
    let marketCapRank: Int
    let priceChange24H, priceChangePercentage24H: Double
    
    var imageUrl: URL? {
        return URL(string: image)
    }

    enum CodingKeys: String, CodingKey {
        case id, symbol, name, image
        case currentPrice = "current_price"
        case marketCapRank = "market_cap_rank"
        case priceChange24H = "price_change_24h"
        case priceChangePercentage24H = "price_change_percentage_24h"
    }
}

extension Coin {
    static var sample = Coin(
        id: "Bitcoin", symbol: "BTC",
        name: "Bitcoin",
        image: "",
        currentPrice: 16700,
        marketCapRank: 1,
        priceChange24H: 200,
        priceChangePercentage24H: 2.0
    )
}

// COIN VIEW MODEL

class ContentViewModel: ObservableObject {
    @Published var coins = [Coin]()
    @Published var error: Error?
    
    private let pageLimit = 20
    private var page = 1
    
    let BASE_URL = "https://api.coingecko.com/api/v3/coins/"
    
    var urlString: String {
        return  "\(BASE_URL)markets?vs_currency=usd&order=market_cap_desc&per_page=50&page=\(page)&price_change_percentage=24h"
    }
    
    init() {
        loadData()
    }
}

extension ContentViewModel {
    @MainActor
    func fetchCoinsAsync() async throws {
        do {
            guard let url = URL(string: urlString) else { throw CoinError.invalidURL }
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw CoinError.serverError }
            guard let coins = try? JSONDecoder().decode([Coin].self, from: data) else { throw CoinError.invalidData }
            self.coins.append(contentsOf: coins)
            page += 1
        } catch {
            self.error = error
        }
    }
        
    func loadData() {
        Task(priority: .medium) {
            try await fetchCoinsAsync()
        }
    }
    
    func refreshData() {
        page = 1
        coins.removeAll()
        loadData()
    }
}

// COIN VIEW

struct CoinView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.coins) { coin in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coin.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.leading, 4)
                        
                        Text(coin.symbol.uppercased())
                            .font(.caption)
                            .padding(.leading, 6)
                    }
                    .onAppear {
                        if (coin.id == viewModel.coins.last?.id) {
                            viewModel.loadData()
                        }
                    }
                }
            }
            .refreshable {
                viewModel.refreshData()
            }
            .onReceive(viewModel.$error, perform: { error in
                if error != nil {
                    showAlert.toggle()
                }
            })
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Error"), message: Text(viewModel.error?.localizedDescription ?? ""))
            })
            .navigationTitle("Live Prices")
        }
    }
}

// COIN ERROR ENUMERATION

enum CoinError: Error, LocalizedError {
    case invalidURL
    case serverError
    case invalidData
    case unkown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return ""
        case .serverError:
            return "There was an error with the server. Please try again later"
        case .invalidData:
            return "The coin data is invalid. Please try again later"
        case .unkown(let error):
            return error.localizedDescription
        }
    }
}
