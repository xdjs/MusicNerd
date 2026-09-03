import Foundation

protocol MusicNerdServiceProtocol: AnyObject {
    func searchArtist(name: String) async -> Result<MusicNerdArtist>
    func searchArtists(name: String) async -> Result<[MusicNerdArtist]>
    func getArtistBio(artistId: String) async -> Result<String>
    func fetchArtistBio(artistId: String) async -> Result<String>
    func getFunFact(artistId: String, type: FunFactType) async -> Result<String>
    func fetchFunFact(
        artistId: String,
        type: FunFactType
    ) async -> Result<String>
}

extension MusicNerdServiceProtocol {
    func searchArtists(name: String) async -> Result<[MusicNerdArtist]> {
        switch await searchArtist(name: name) {
        case .success(let artist):
            return .success([artist])
        case .failure(let error):
            return .failure(error)
        }
    }

    func fetchArtistBio(artistId: String) async -> Result<String> {
        await getArtistBio(artistId: artistId)
    }

    func fetchFunFact(
        artistId: String,
        type: FunFactType
    ) async -> Result<String> {
        await getFunFact(artistId: artistId, type: type)
    }
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
        self.reachabilityService = reachabilityService
    }
    
    // MARK: - Search Artist
    
    func searchArtist(name: String) async -> Result<MusicNerdArtist> {
        switch await searchArtists(name: name) {
        case .success(let artists):
            guard let artist = artists.first else {
                return .failure(.musicNerdError(.artistNotFound))
            }
            return .success(artist)
        case .failure(let error):
            return .failure(error)
        }
    }

    func searchArtists(name: String) async -> Result<[MusicNerdArtist]> {
        let query = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            logWithTimestamp("Rejected empty artist search query")
            return .failure(.musicNerdError(.artistNotFound))
        }

        // Check network connectivity first
        await checkNetworkConnectivity()

        guard !Task.isCancelled else {
            return .failure(.networkError(.timeout))
        }
        
        guard await isNetworkConnected() else {
            logWithTimestamp("No network connection available for artist search")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute search with retry logic
        return await withRetry(operation: "Artist search") {
            try await performArtistSearch(name: query)
        }
    }
    
    /// Performs the actual artist search API call
    private func performArtistSearch(name: String) async throws -> Result<[MusicNerdArtist]> {
        
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
            
            logWithTimestamp("Sending artist search request")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Artist search response size: \(data.count) bytes")
            
            if httpResponse.statusCode == 200 {
                let searchResponse = try decoder.decode(SearchArtistsResponse.self, from: data)
                
                logWithTimestamp("Found \(searchResponse.results.count) artists (before filtering)")
                
                // Filter out artists with null IDs
                let validArtists = searchResponse.results.filter { $0.artistId != nil }
                logWithTimestamp("Found \(validArtists.count) valid artists (with non-null IDs)")
                
                if validArtists.isEmpty {
                    logWithTimestamp("No valid artists found")
                    return .failure(.musicNerdError(.artistNotFound))
                }

                return .success(validArtists)
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
            } else {
                logWithTimestamp("=== SEARCH ARTIST ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                // Try to parse error response
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Artist search API returned a structured error")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse error response, treating as HTTP error")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Artist search request failed")
            return .failure(Self.requestFailure(for: error))
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
        if let cachedBio = await MainActor.run(body: {
            EnrichmentCache.shared.retrieve(for: cacheKey)
        }) {
            guard !Task.isCancelled else {
                return .failure(.networkError(.timeout))
            }
            return .success(cachedBio)
        }

        let result = await fetchArtistBio(artistId: artistId)
        guard !Task.isCancelled else {
            return .failure(.networkError(.timeout))
        }

        if case .success(let biography) = result {
            await MainActor.run {
                EnrichmentCache.shared.store(
                    biography,
                    for: cacheKey,
                    expirationInterval: AppSettings.shared.cacheExpirationInterval
                )
            }
        }

        return result
    }

    /// Fetches a biography without reading or writing the persistent enrichment cache.
    /// Current-playback knowledge uses this path so it leaves no new on-disk listening trace.
    func fetchArtistBio(artistId: String) async -> Result<String> {
        guard !artistId.isEmpty else {
            logWithTimestamp("Invalid artistId: empty string")
            return .failure(.musicNerdError(.artistNotFound))
        }

        // Check network connectivity before making API call
        await checkNetworkConnectivity()

        guard !Task.isCancelled else {
            return .failure(.networkError(.timeout))
        }
        
        guard await isNetworkConnected() else {
            logWithTimestamp("No network connection available for artist bio")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute bio request with retry logic
        return await withRetry(operation: "Artist bio") {
            try await performArtistBioRequest(artistId: artistId)
        }
    }
    
    /// Performs the actual artist bio API call
    private func performArtistBioRequest(artistId: String) async throws -> Result<String> {
        
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.artistBioEndpoint)/\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid artist bio URL")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("Sending artist bio request")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for bio request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Artist bio response size: \(data.count) bytes")
            
            if httpResponse.statusCode == 200 {
                let bioResponse = try decoder.decode(ArtistBioResponse.self, from: data)
                
                if let bio = bioResponse.bio, !bio.isEmpty {
                    logWithTimestamp("Retrieved bio (\(bio.count) characters)")
                    return .success(bio)
                } else {
                    logWithTimestamp("No artist bio available")
                    return .failure(.musicNerdError(.noBioAvailable))
                }
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== BIO RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
            } else {
                logWithTimestamp("=== GET ARTIST BIO ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Artist bio API returned a structured error")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse bio error response, treating as HTTP error")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Artist bio request failed")
            return .failure(Self.requestFailure(for: error))
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
        if let cachedFunFact = await MainActor.run(body: {
            EnrichmentCache.shared.retrieve(for: cacheKey)
        }) {
            guard !Task.isCancelled else {
                return .failure(.networkError(.timeout))
            }
            return .success(cachedFunFact)
        }

        let result = await fetchFunFact(artistId: artistId, type: type)
        guard !Task.isCancelled else {
            return .failure(.networkError(.timeout))
        }

        if case .success(let funFact) = result {
            await MainActor.run {
                EnrichmentCache.shared.store(
                    funFact,
                    for: cacheKey,
                    expirationInterval: AppSettings.shared.cacheExpirationInterval
                )
            }
        }

        return result
    }

    /// Fetches a fun fact without reading or writing the persistent enrichment cache.
    /// Current-playback knowledge uses this path so it leaves no new on-disk listening trace.
    func fetchFunFact(
        artistId: String,
        type: FunFactType
    ) async -> Result<String> {
        guard !artistId.isEmpty else {
            logWithTimestamp("Invalid artistId: empty string")
            return .failure(.musicNerdError(.artistNotFound))
        }

        // Check network connectivity before making API call
        await checkNetworkConnectivity()

        guard !Task.isCancelled else {
            return .failure(.networkError(.timeout))
        }
        
        guard await isNetworkConnected() else {
            logWithTimestamp("No network connection available for \(type.rawValue) fact")
            return .failure(.networkError(.noConnection))
        }
        
        // Execute fun fact request with retry logic
        return await withRetry(
            operation: "Fun fact (\(type.rawValue))"
        ) {
            try await performFunFactRequest(artistId: artistId, type: type)
        }
    }
    
    /// Performs the actual fun fact API call
    private func performFunFactRequest(artistId: String, type: FunFactType) async throws -> Result<String> {
        
        let baseURL = AppConfiguration.API.baseURL
        let endpoint = "\(AppConfiguration.API.funFactsEndpoint)/\(type.rawValue)?id=\(artistId)"
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logWithTimestamp("Invalid fun fact URL")
            return .failure(.networkError(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            logWithTimestamp("Sending \(type.rawValue) fact request")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logWithTimestamp("Invalid response type for fun facts request")
                return .failure(.networkError(.invalidResponse))
            }
            
            logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
            logWithTimestamp("Fun fact response size: \(data.count) bytes")
            
            if httpResponse.statusCode == 200 {
                let funFactsResponse = try decoder.decode(FunFactsResponse.self, from: data)
                
                // Check both funFact and text fields (API returns "text")
                let funFactText = funFactsResponse.funFact ?? funFactsResponse.text
                
                if let funFact = funFactText, !funFact.isEmpty {
                    logWithTimestamp("Retrieved \(type.rawValue) fun fact (\(funFact.count) characters)")
                    return .success(funFact)
                } else {
                    logWithTimestamp("No \(type.rawValue) fun fact available")
                    return .failure(.musicNerdError(.noFunFactAvailable))
                }
            } else if httpResponse.statusCode == 429 {
                logWithTimestamp("=== FUN FACT RATE LIMIT ERROR ===")
                logWithTimestamp("HTTP Status: 429 - Too Many Requests")
                return .failure(.networkError(.rateLimited))
            } else {
                logWithTimestamp("=== GET FUN FACT ERROR ===")
                logWithTimestamp("HTTP Status: \(httpResponse.statusCode)")
                if let errorResponse = try? decoder.decode(MusicNerdAPIError.self, from: data) {
                    logWithTimestamp("Fun facts API returned a structured error")
                    return .failure(.musicNerdError(.apiError(errorResponse.error)))
                } else {
                    logWithTimestamp("Could not parse fun facts error response, treating as HTTP error")
                    return .failure(.networkError(.serverError(httpResponse.statusCode)))
                }
            }
            
        } catch {
            logWithTimestamp("Fun facts request failed")
            return .failure(Self.requestFailure(for: error))
        }
    }

    static func requestFailure(for error: Error) -> AppError {
        if error is CancellationError || Task.isCancelled {
            return .networkError(.timeout)
        }

        if error is DecodingError || error is EncodingError {
            return .networkError(.invalidResponse)
        }

        guard let urlError = error as? URLError else {
            return .networkError(.invalidResponse)
        }

        switch urlError.code {
        case .timedOut, .cancelled:
            return .networkError(.timeout)
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkError(.noConnection)
        case .badURL, .unsupportedURL:
            return .networkError(.invalidURL)
        default:
            return .networkError(.invalidResponse)
        }
    }
    
    // MARK: - Network Connectivity Helper
    
    private func checkNetworkConnectivity() async {
        // Serialize monitor startup with the main-actor-published reachability state.
        await MainActor.run {
            reachabilityService.startMonitoring()
        }
        // Give a brief moment for initial status update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    private func isNetworkConnected() async -> Bool {
        await MainActor.run {
            reachabilityService.isConnected
        }
    }
    
    /// Waits for network connectivity to be restored with timeout
    private func waitForNetworkRecovery(timeout: TimeInterval = 5.0) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            guard !Task.isCancelled else { return false }

            if await isNetworkConnected() {
                logWithTimestamp("Network connectivity restored")
                return true
            }
            
            // Wait 0.5 seconds before checking again
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                return false
            }
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
            guard !Task.isCancelled else {
                return .failure(.networkError(.timeout))
            }

            do {
                let result = try await execute()

                guard !Task.isCancelled else {
                    return .failure(.networkError(.timeout))
                }
                
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
                        logWithTimestamp("\(operation) failed on attempt \(attempt), retrying in \(String(format: "%.1f", delay))s")
                        
                        // For network connection errors, wait for network recovery
                        if case .networkError(.noConnection) = error {
                            logWithTimestamp("Waiting for network recovery before retry...")
                            let networkRecovered = await waitForNetworkRecovery(timeout: delay)
                            if !networkRecovered {
                                guard !Task.isCancelled else {
                                    return .failure(.networkError(.timeout))
                                }
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
                            logWithTimestamp("\(operation) failed after \(attempt) attempts")
                        }
                        return result
                    }
                }
            } catch is CancellationError {
                return .failure(.networkError(.timeout))
            } catch {
                guard !Task.isCancelled else {
                    return .failure(.networkError(.timeout))
                }

                if attempt < attempts {
                    let delay = calculateRetryDelay(attempt: attempt)
                    logWithTimestamp("\(operation) threw an error on attempt \(attempt), retrying in \(String(format: "%.1f", delay))s")
                    
                    // Wait before retrying
                    do {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    } catch {
                        return .failure(.networkError(.timeout))
                    }
                    continue
                } else {
                    logWithTimestamp("\(operation) threw an error after \(attempt) attempts")
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
