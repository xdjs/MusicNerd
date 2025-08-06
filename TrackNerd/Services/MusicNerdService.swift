import Foundation

protocol MusicNerdServiceProtocol: AnyObject {
    func searchArtist(name: String) async -> Result<MusicNerdArtist>
    func getArtistBio(artistId: Int) async -> Result<String>
    func getFunFact(artistId: Int, type: FunFactType) async -> Result<String>
}

enum FunFactType: String, CaseIterable {
    case lore = "lore"
    case bts = "bts"
    case activity = "activity"  
    case surprise = "surprise"
}

class MusicNerdService: MusicNerdServiceProtocol {
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfiguration.API.timeoutInterval
        config.timeoutIntervalForResource = AppConfiguration.API.timeoutInterval
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Search Artist
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = AppConfiguration.API.searchArtistsEndpoint
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid URL: \(baseURL)\(endpoint)")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = SearchArtistsRequest(query: name)
        
        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
            
            logWithTimestamp("Searching for artist: '\(name)' at \(url)")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("Search response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let searchResponse = try decoder.decode(SearchArtistsResponse.self, from: data)
                
                logWithTimestamp("Found \(searchResponse.results.count) artists")
                
                if searchResponse.results.isEmpty {
                    logWithTimestamp("No artists found for: '\(name)'")
                    return .failure(.musicNerdError(.artistNotFound))
                }
                
                // Simple algorithm: always choose the first result
                let selectedArtist = searchResponse.results[0]
                logWithTimestamp("Selected artist: '\(selectedArtist.name)' (ID: \(selectedArtist.id))")
                
                return .success(selectedArtist)
            } else {
                // Try to parse error response
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("HTTP error: \(httpResponse.statusCode)")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Search request failed: \(error)")
            return .failure(.networkError(.timeout))
        }
    }
    
    // MARK: - Get Artist Bio
    
    func getArtistBio(artistId: Int) async -> Result<String> {
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.artistBioEndpoint)/\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid bio URL: \(baseURL)\(endpoint)")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("Fetching bio for artist ID: \(artistId)")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for bio request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("Bio response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let bioResponse = try decoder.decode(ArtistBioResponse.self, from: data)
                
                if let bio = bioResponse.bio, !bio.isEmpty {
                    logWithTimestamp("Retrieved bio (\(bio.count) characters)")
                    return .success(bio)
                } else {
                    logWithTimestamp("No bio available for artist ID: \(artistId)")
                    return .failure(.musicNerdError(.noBioAvailable))
                }
            } else {
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Bio API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Bio HTTP error: \(httpResponse.statusCode)")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Bio request failed: \(error)")
            return .failure(.networkError(.timeout))
        }
    }
    
    // MARK: - Get Fun Fact
    
    func getFunFact(artistId: Int, type: FunFactType) async -> Result<String> {
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.funFactsEndpoint)/\(type.rawValue)?id=\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid fun facts URL: \(baseURL)\(endpoint)")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("Fetching \(type.rawValue) fun fact for artist ID: \(artistId)")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for fun facts request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("Fun facts response status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let funFactsResponse = try decoder.decode(FunFactsResponse.self, from: data)
                
                if let funFact = funFactsResponse.funFact, !funFact.isEmpty {
                    logWithTimestamp("Retrieved \(type.rawValue) fun fact (\(funFact.count) characters)")
                    return .success(funFact)
                } else {
                    logWithTimestamp("No \(type.rawValue) fun fact available for artist ID: \(artistId)")
                    return .failure(.musicNerdError(.noFunFactAvailable))
                }
            } else {
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Fun facts API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Fun facts HTTP error: \(httpResponse.statusCode)")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Fun facts request failed: \(error)")
            return .failure(.networkError(.timeout))
        }
    }
    
    // MARK: - Logging Helper
    
    private func logWithTimestamp(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] MusicNerdService: \(message)")
    }
}

