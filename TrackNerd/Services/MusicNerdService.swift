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
    private let cache: EnrichmentCache
    private let reachabilityService: NetworkReachabilityService
    
    // Retry configuration
    private let maxRetryAttempts: Int = 3
    private let baseRetryDelay: TimeInterval = 1.0 // seconds
    private let maxRetryDelay: TimeInterval = 10.0 // seconds
    
    init(reachabilityService: NetworkReachabilityService = NetworkReachabilityService.shared) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfiguration.API.timeoutInterval
        config.timeoutIntervalForResource = AppConfiguration.API.timeoutInterval
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.cache = EnrichmentCache.shared
        self.reachabilityService = reachabilityService
    }
    
    // MARK: - Search Artist
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        // Check network connectivity first
        await checkNetworkConnectivity()
        
        guard reachabilityService.isConnected else {
            logWithTimestamp("No network connection available for artist search: \(name)")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute search with retry logic
        return await withRetry(operation: "Artist search for '\(name)'") {
            try await performArtistSearch(name: name)
        }
    }
    
    /// Performs the actual artist search API call
    private func performArtistSearch(name: String) async throws -> Result<MusicNerdArtist> {
        
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
                
                logWithTimestamp("Found \(searchResponse.results.count) artists (before filtering)")
                
                // Filter out artists with null IDs
                let validArtists = searchResponse.results.filter { $0.artistId != nil }
                logWithTimestamp("Found \(validArtists.count) valid artists (with non-null IDs)")
                
                if validArtists.isEmpty {
                    logWithTimestamp("No valid artists found for: '\(name)'")
                    return .failure(.musicNerdError(.artistNotFound))
                }
                
                // Simple algorithm: always choose the first valid result
                let selectedArtist = validArtists[0]
                logWithTimestamp("Selected artist: '\(selectedArtist.name)' (ID: \(selectedArtist.artistId ?? "nil"))")
                
                return .success(selectedArtist)
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
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
        guard !artistId.isEmpty else {
            logWithTimestamp("Invalid artistId: empty string")
            return .failure(.musicNerdError(.artistNotFound))
        }
        
        // Check cache first
        let cacheKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
        if let cachedBio = await MainActor.run { cache.retrieve(for: cacheKey) } {
            return .success(cachedBio)
        }
        
        // Check network connectivity before making API call
        await checkNetworkConnectivity()
        
        guard reachabilityService.isConnected else {
            logWithTimestamp("No network connection available for artist bio: \(artistId)")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute bio request with retry logic
        return await withRetry(operation: "Artist bio for ID '\(artistId)'") {
            try await performArtistBioRequest(artistId: artistId)
        }
    }
    
    /// Performs the actual artist bio API call
    private func performArtistBioRequest(artistId: String) async throws -> Result<String> {
        
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
                    
                    // Store in cache with user-configured expiration
                    let cacheKey = EnrichmentCacheKey(artistId: artistId, type: .bio)
                    await MainActor.run {
                        cache.store(bio, for: cacheKey, expirationInterval: AppSettings.shared.cacheExpirationInterval)
                    }
                    
                    return .success(bio)
                } else {
                    logWithTimestamp("No bio available for artist ID: \(artistId)")
                    return .failure(.musicNerdError(.noBioAvailable))
                }
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== BIO RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
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
        guard !artistId.isEmpty else {
            logWithTimestamp("Invalid artistId: empty string")
            return .failure(.musicNerdError(.artistNotFound))
        }
        
        // Check cache first
        let cacheKey = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
        if let cachedFunFact = await MainActor.run { cache.retrieve(for: cacheKey) } {
            return .success(cachedFunFact)
        }
        
        // Check network connectivity before making API call
        await checkNetworkConnectivity()
        
        guard reachabilityService.isConnected else {
            logWithTimestamp("No network connection available for fun fact: \(artistId) (\(type.rawValue))")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute fun fact request with retry logic
        return await withRetry(operation: "Fun fact (\(type.rawValue)) for ID '\(artistId)'") {
            try await performFunFactRequest(artistId: artistId, type: type)
        }
    }
    
    /// Performs the actual fun fact API call
    private func performFunFactRequest(artistId: String, type: FunFactType) async throws -> Result<String> {
        
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
                
                // Check both funFact and text fields (API returns "text")
                let funFactText = funFactsResponse.funFact ?? funFactsResponse.text
                
                if let funFact = funFactText, !funFact.isEmpty {
                    logWithTimestamp("Retrieved \(type.rawValue) fun fact (\(funFact.count) characters)")
                    
                    // Store in cache with user-configured expiration
                    let cacheKey = EnrichmentCacheKey(artistId: artistId, type: .funFact(type))
                    await MainActor.run {
                        cache.store(funFact, for: cacheKey, expirationInterval: AppSettings.shared.cacheExpirationInterval)
                    }
                    
                    return .success(funFact)
                } else {
                    logWithTimestamp("No \(type.rawValue) fun fact available for artist ID: \(artistId)")
                    return .failure(.musicNerdError(.noFunFactAvailable))
                }
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== FUN FACT RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
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
    
    // MARK: - Network Connectivity Helper
    
    private func checkNetworkConnectivity() async {
        // Ensure network monitoring is started
        reachabilityService.startMonitoring()
        // Give a brief moment for initial status update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    /// Waits for network connectivity to be restored with timeout
    private func waitForNetworkRecovery(timeout: TimeInterval = 5.0) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if reachabilityService.isConnected {
                logWithTimestamp("Network connectivity restored")
                return true
            }
            
            // Wait 0.5 seconds before checking again
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        logWithTimestamp("Network recovery timeout after \(timeout)s")
        return false
    }
    
    // MARK: - Retry Logic
    
    /// Executes an async operation with exponential backoff retry logic
    private func withRetry<T>(
        operation: String,
        maxAttempts: Int? = nil,
        retryableErrors: [AppError]? = nil,
        execute: () async throws -> Result<T>
    ) async -> Result<T> {
        let attempts = maxAttempts ?? maxRetryAttempts
        let defaultRetryableErrors: [AppError] = [
            .networkError(.timeout),
            .networkError(.noConnection),
            .networkError(.serverError(500)),
            .networkError(.serverError(502)),
            .networkError(.serverError(503)),
            .networkError(.serverError(504)),
            .networkError(.rateLimited)
        ]
        let errorsToRetry = retryableErrors ?? defaultRetryableErrors
        
        for attempt in 1...attempts {
            do {
                let result = try await execute()
                
                switch result {
                case .success:
                    if attempt > 1 {
                        logWithTimestamp("\(operation) succeeded on attempt \(attempt)")
                    }
                    return result
                case .failure(let error):
                    // Check if error is retryable
                    let shouldRetry = errorsToRetry.contains { retryableError in
                        switch (error, retryableError) {
                        case (.networkError(let networkError1), .networkError(let networkError2)):
                            return networkError1 == networkError2
                        default:
                            return false
                        }
                    }
                    
                    if shouldRetry && attempt < attempts {
                        let delay = calculateRetryDelay(attempt: attempt)
                        logWithTimestamp("\(operation) failed on attempt \(attempt), retrying in \(String(format: "%.1f", delay))s: \(error)")
                        
                        // For network connection errors, wait for network recovery
                        if case .networkError(.noConnection) = error {
                            logWithTimestamp("Waiting for network recovery before retry...")
                            let networkRecovered = await waitForNetworkRecovery(timeout: delay)
                            if !networkRecovered {
                                logWithTimestamp("Network not recovered, proceeding with normal retry delay")
                                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            }
                        } else {
                            // Wait before retrying for other errors
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        }
                        continue
                    } else {
                        if attempt > 1 {
                            logWithTimestamp("\(operation) failed after \(attempt) attempts: \(error)")
                        }
                        return result
                    }
                }
            } catch {
                if attempt < attempts {
                    let delay = calculateRetryDelay(attempt: attempt)
                    logWithTimestamp("\(operation) threw error on attempt \(attempt), retrying in \(String(format: "%.1f", delay))s: \(error)")
                    
                    // Wait before retrying
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    logWithTimestamp("\(operation) threw error after \(attempt) attempts: \(error)")
                    return .failure(.networkError(.timeout))
                }
            }
        }
        
        return .failure(.networkError(.timeout))
    }
    
    /// Calculates exponential backoff delay with jitter
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let exponentialDelay = baseRetryDelay * pow(2.0, Double(attempt - 1))
        let cappedDelay = min(exponentialDelay, maxRetryDelay)
        
        // Add jitter to prevent thundering herd (±25% randomization)
        let jitter = cappedDelay * 0.25 * (Double.random(in: 0...1) * 2 - 1)
        let finalDelay = max(0.1, cappedDelay + jitter)
        
        return finalDelay
    }
    
    // MARK: - Logging Helper
    
    private func logWithTimestamp(_ message: String) {
        if AppSettings.shared.suppressMusicNerdLogs { return }
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] MusicNerdService: \(message)")
    }
}

