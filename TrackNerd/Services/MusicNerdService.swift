import Foundation

protocol MusicNerdServiceProtocol: AnyObject {
    func searchArtist(name: String) async -> Result<MusicNerdArtist>
    func getArtistBio(artistId: String) async -> Result<String>
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String>
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
            
            logWithTimestamp("=== SEARCH ARTIST REQUEST ===")
            logWithTimestamp("URL: \(url)")
            logWithTimestamp("Method: POST")
            logWithTimestamp("Headers: \(request.allHTTPHeaderFields ?? [:])")
            logWithTimestamp("Body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
            
            let (data, response) = try await session.data(for: request)
            
            logWithTimestamp("=== SEARCH ARTIST RESPONSE ===")
            logWithTimestamp("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Response Headers: \(httpResponse.allHeaderFields)")
            
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
                logWithTimestamp("=== SEARCH ARTIST ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                logWithTimestamp("Error response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode error response")")
                
                // Try to parse error response
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Parsed API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse error response, treating as HTTP error")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Search request failed: \(error)")
            return .failure(.networkError(.timeout))
        }
    }
    
    // MARK: - Get Artist Bio
    
    func getArtistBio(artistId: String) async -> Result<String> {
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.artistBioEndpoint)/\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid bio URL: \(baseURL)\(endpoint)")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("=== GET ARTIST BIO REQUEST ===")
            logWithTimestamp("URL: \(url)")
            logWithTimestamp("Method: GET")
            logWithTimestamp("Artist ID: \(artistId)")
            
            let (data, response) = try await session.data(for: request)
            
            logWithTimestamp("=== GET ARTIST BIO RESPONSE ===")
            logWithTimestamp("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for bio request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Response Headers: \(httpResponse.allHeaderFields)")
            
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
                logWithTimestamp("=== GET ARTIST BIO ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                logWithTimestamp("Error response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode error response")")
                
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Parsed Bio API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse bio error response, treating as HTTP error")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Bio request failed: \(error)")
            return .failure(.networkError(.timeout))
        }
    }
    
    // MARK: - Get Fun Fact
    
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String> {
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.funFactsEndpoint)/\(type.rawValue)?id=\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid fun facts URL: \(baseURL)\(endpoint)")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("=== GET FUN FACT REQUEST ===")
            logWithTimestamp("URL: \(url)")
            logWithTimestamp("Method: GET")
            logWithTimestamp("Artist ID: \(artistId)")
            logWithTimestamp("Fun Fact Type: \(type.rawValue)")
            
            let (data, response) = try await session.data(for: request)
            
            logWithTimestamp("=== GET FUN FACT RESPONSE ===")
            logWithTimestamp("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for fun facts request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Response Headers: \(httpResponse.allHeaderFields)")
            
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
                logWithTimestamp("=== GET FUN FACT ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                logWithTimestamp("Error response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode error response")")
                
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Parsed Fun Facts API error: \(errorResponse.error)")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse fun facts error response, treating as HTTP error")
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

