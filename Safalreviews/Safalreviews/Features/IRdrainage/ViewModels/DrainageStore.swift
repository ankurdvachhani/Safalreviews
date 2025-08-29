import Foundation
import SwiftUI

struct DrainageResponse: Codable {
    let success: Bool
    let data: [DrainageEntry]
    let sort: SortInfo
    let pagination: PaginationInfo
    let errors: [String]
    let timestamp: String
    let message: String
}

struct SortInfo: Codable {
    let order: String
    let orderBy: String
}

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let current: Int
}

struct SingleDrainageResponse: Codable {
    let success: Bool
    let data: DrainageEntry
}

struct CommentRequest: Codable {
    let commentText: String
}

struct CommentResponse: Codable {
    let success: Bool
}

// Add this struct for the API request
struct DrainageEntryRequest: Codable {
    let patientId: String
    let patientName: String
    let amount: Double
    let amountUnit: String
    let location: String
    let fluidType: String
    let comments: String
    let color: String
    let colorOther: String?
    let consistency: [String]
    let odor: String
    let drainageType: String
    let isFluidSalineFlush: Bool
    let fluidSalineFlushAmount: Double
    let fluidSalineFlushAmountUnit: String
    let odorPresent: Bool
    let doctorNotified: Bool
    let painLevel: Int
    let temperature: Double
    let recordedAt: String
    let beforeImage: [String]
    let afterImage: [String]
    let fluidCupImage: [String]
    let incident: String?
}

@MainActor
class DrainageStore: ObservableObject {
    @Published var entries: [DrainageEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let networkManager = NetworkManager()
     var currentPage = 1
     var limit = 10
     var hasMorePages = true
    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var isFetching = false
    private var totalEntries = 0
    private let folderName = "safalirdrainmate"
    private(set) var initialPatientSlug: String?
    private(set) var initialIncidentId: String?
    private var currentSortOption: DrainageSortOption = .dateDesc
   // private let userSlug = TokenManager.shared.loadCurrentUser()?.userSlug
    
    func fetchDrainageDetail(id: String) async throws -> DrainageEntry {
        let endpoint = Endpoint(
            path: "\(APIConfig.Path.drainageEntries)/\(id)",
            method: .get
        )
        
        let response: SingleDrainageResponse = try await networkManager.fetch(endpoint)
        return response.data
    }
    // MARK: - Init
    init(patientSlug: String? = nil, incidentId: String? = nil) {
        self.initialPatientSlug = patientSlug
        self.initialIncidentId = incidentId
        print("🔍 DrainageStore init - patientSlug: \(patientSlug ?? "nil"), incidentId: \(incidentId ?? "nil")")
        Task {
            await fetchEntries(patientSlug: patientSlug, incidentId: incidentId)
        }
    }
    
    // MARK: - Public Methods
    func loadMoreIfNeeded(currentItem: DrainageEntry?, filter: DrainageFilter? = nil) async {
        guard let currentItem = currentItem,
              let lastItem = entries.last,
              currentItem.id == lastItem.id,
              !isLoading,
              hasMorePages,
              !isFetching
        else { return }
        
        print("📱 Triggering load more for page: \(currentPage)")
        print("📱 Current entries count: \(entries.count)")
        print("📱 Total entries available: \(totalEntries)")
        
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await fetchEntries(patientSlug: nil, incidentId: initialIncidentId, filter: filter, sortOption: currentSortOption) // Use current filters
        }
        
        // Wait for the fetch task to complete
        await fetchTask?.value
    }
    
    func fetchEntries(searchQuery: String = "", patientSlug: String? = nil, incidentId: String? = nil, filter: DrainageFilter? = nil, sortOption: DrainageSortOption = .dateDesc, resetPages: Bool = false) async {
        print("🔍 DrainageStore.fetchEntries - patientSlug: \(patientSlug ?? "nil"), incidentId: \(incidentId ?? "nil"), searchQuery: \(searchQuery)")
//        guard !isFetching else {
//            print("⚠️ Fetch already in progress, skipping...")
//            return
//        }
        
        if resetPages {
            currentPage = 1
            hasMorePages = true
            entries = []
            totalEntries = 0
        }
        
        guard hasMorePages else {
            print("⚠️ No more pages available, skipping...")
            return
        }
        
        isLoading = true
        isFetching = true
        errorMessage = nil
        
        print("🔄 Starting fetch for page \(currentPage)")
        
        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "page", value: "\(currentPage)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "search", value: searchQuery.isEmpty ? nil : searchQuery),
                URLQueryItem(name: "orderBy", value: sortOption.orderBy),
                URLQueryItem(name: "order", value: sortOption.order)
            ]

            // Append incidentId query item if provided
            if let incidentId = incidentId {
                print("🔍 Adding incidentId query item: \(incidentId)")
                queryItems.append(URLQueryItem(name: "incident", value: incidentId))
            }

            // Append role-specific query item
            if let patientSlug = patientSlug {
                // If patientSlug is provided, filter by that specific patient
                print("🔍 Adding patientId query item: \(patientSlug)")
                queryItems.append(URLQueryItem(name: "patientId", value: patientSlug))
            } else if TokenManager.shared.loadCurrentUser()?.role != "Patient" && patientSlug == nil && incidentId == nil {
                print("🔍 Adding userId query item: \(TokenManager.shared.getUserId())")
                queryItems.append(URLQueryItem(name: "userId", value: TokenManager.shared.getUserId()))
            } else if TokenManager.shared.loadCurrentUser()?.role == "Patient" {
                let currentPatientSlug = TokenManager.shared.loadCurrentUser()?.userSlug
                print("🔍 Adding current patientId query item: \(currentPatientSlug ?? "nil")")
                queryItems.append(URLQueryItem(name: "patientId", value: currentPatientSlug))
            }
            
            // Add filter parameters if filter is provided
            if let filter = filter {
                // Single value filters
                if let minAmount = filter.minAmount {
                    queryItems.append(URLQueryItem(name: "minAmount", value: String(minAmount)))
                }
                if let maxAmount = filter.maxAmount {
                    queryItems.append(URLQueryItem(name: "maxAmount", value: String(maxAmount)))
                }
                if let minTemperature = filter.minTemperature {
                    queryItems.append(URLQueryItem(name: "minTemperature", value: String(minTemperature)))
                }
                if let maxTemperature = filter.maxTemperature {
                    queryItems.append(URLQueryItem(name: "maxTemperature", value: String(maxTemperature)))
                }
                if let minPainLevel = filter.minPainLevel {
                    queryItems.append(URLQueryItem(name: "minPainLevel", value: String(minPainLevel)))
                }
                if let maxPainLevel = filter.maxPainLevel {
                    queryItems.append(URLQueryItem(name: "maxPainLevel", value: String(maxPainLevel)))
                }
                if let minRecordedAt = filter.minRecordedAt {
                    let dateFormatter = ISO8601DateFormatter()
                    queryItems.append(URLQueryItem(name: "minRecordedAt", value: dateFormatter.string(from: minRecordedAt)))
                }
                if let maxRecordedAt = filter.maxRecordedAt {
                    let dateFormatter = ISO8601DateFormatter()
                    queryItems.append(URLQueryItem(name: "maxRecordedAt", value: dateFormatter.string(from: maxRecordedAt)))
                }
                
                // Multi-value filters (arrays)
                for (index, odor) in filter.odor.enumerated() {
                    queryItems.append(URLQueryItem(name: "odor[\(index)]", value: odor))
                }
                for (index, fluidType) in filter.fluidType.enumerated() {
                    queryItems.append(URLQueryItem(name: "fluidType[\(index)]", value: fluidType))
                }
                for (index, color) in filter.color.enumerated() {
                    queryItems.append(URLQueryItem(name: "color[\(index)]", value: color))
                }
                for (index, drainageType) in filter.drainageType.enumerated() {
                    queryItems.append(URLQueryItem(name: "drainageType[\(index)]", value: drainageType))
                }
                for (index, consistency) in filter.consistency.enumerated() {
                    queryItems.append(URLQueryItem(name: "consistency[\(index)]", value: consistency))
                }
                // Single value filter for patientId
                if let patientId = filter.patientId {
                    queryItems.append(URLQueryItem(name: "patientId", value: patientId))
                }
            }

            // Create the endpoint
            let endpoint = Endpoint(
                path: APIConfig.Path.drainageEntries,
                queryItems: queryItems
            )
            
            print("📡 API Request - Page: \(currentPage), Limit: \(limit), Search: \(searchQuery)")
            
            let response: DrainageResponse = try await networkManager.fetch(endpoint)
            
            if !Task.isCancelled {
                totalEntries = response.pagination.total
                hasMorePages = response.pagination.current < totalEntries
                
                print("📥 Received response - Total: \(response.pagination.total), Current page: \(currentPage)")
                
                if currentPage == 1 {
                    entries = response.data
                } else {
                    // Filter out duplicates before appending
                    let newEntries = response.data.filter { newEntry in
                        !entries.contains { $0.id == newEntry.id }
                    }
                    entries.append(contentsOf: newEntries)
                }
                
                // Only increment page if we got data
                if !response.data.isEmpty {
                    currentPage += 1
                }
                
                print("📊 Pagination Status:")
                print("  - Current Page: \(currentPage)")
                print("  - Total Entries: \(totalEntries)")
                print("  - Loaded Entries: \(entries.count)")
                print("  - Has More Pages: \(hasMorePages)")
                print("  - New Data Count: \(response.data.count)")
            } else {
                print("⚠️ Task was cancelled during fetch")
            }
        } catch {
            if !Task.isCancelled {
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .cancelled:
                        print("⚠️ Network request was cancelled")
                    default:
                        errorMessage = error.localizedDescription
                        print("❌ Error: \(error.localizedDescription)")
                    }
                } else {
                    errorMessage = error.localizedDescription
                    print("❌ Error: \(error.localizedDescription)")
                }
            } else {
                print("⚠️ Task was cancelled during error handling")
            }
        }
        
        isLoading = false
        isFetching = false
        print("✅ Fetch completed for page \(currentPage - 1)")
    }
    
    func refreshEntries(patientSlug: String? = nil, incidentId: String? = nil, filter: DrainageFilter? = nil, sortOption: DrainageSortOption? = nil) async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            // Reset pagination and clear loading state
            currentPage = 1
            hasMorePages = true
            entries = []
            isLoading = true
            errorMessage = nil
            
            let sortToUse = sortOption ?? currentSortOption
            await fetchEntries(patientSlug: patientSlug, incidentId: incidentId, filter: filter, sortOption: sortToUse)
            
            isLoading = false
            refreshTask = nil
        }
        
        // Wait for the refresh task to complete
        await refreshTask?.value
    }
    
    func updateSortOption(_ sortOption: DrainageSortOption, filter: DrainageFilter? = nil) async {
        currentSortOption = sortOption
        await refreshEntries(patientSlug: initialPatientSlug, incidentId: initialIncidentId, filter: filter, sortOption: currentSortOption)
    }
    
    func searchEntries(query: String, filter: DrainageFilter? = nil) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task
        searchTask = Task {
            // Reset pagination
            currentPage = 1
            hasMorePages = true
            
            // Wait a bit to avoid too many API calls while typing
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            if !Task.isCancelled {
                await fetchEntries(searchQuery: query, filter: filter, sortOption: currentSortOption, resetPages: true)
            }
        }
    }
    
    func deleteEntry(_ entry: DrainageEntry) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let endpoint = Endpoint(
                path: "\(APIConfig.Path.drainageEntries)/\(entry.id)",
                method: .delete
            )
            
            print("🗑️ Deleting entry: \(entry.id)")
            
            let _: EmptyResponse = try await networkManager.fetch(endpoint)
            
            // Remove from local array if it exists
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries.remove(at: index)
            }
            print("✅ Entry deleted successfully")
            successMessage = "Entry deleted successfully"
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to delete entry: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Comment Methods
    
    func addComment(to entryId: String, commentText: String) async  {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = CommentRequest(commentText: commentText)
            
            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + "\(APIConfig.Path.drainageEntries)/\(entryId)") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(CommentResponse.self, from: data)
                successMessage = "Comment added successfully"
            } else {
                throw NetworkError.apiError("Failed to add comment: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
           
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Missing key '\(key.stringValue)' – \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type '\(type)' – \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found for type '\(type)' – \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to decode server response"
           
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred"
        }
    }
    
    func addEntry(_ entry: DrainageEntry) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Format date to match API expectation
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let request = DrainageEntryRequest(
                patientId: entry.patientId ?? "",
                patientName: entry.patientName ?? "",
                amount: entry.amount,
                amountUnit: entry.amountUnit,
                location: entry.location,
                fluidType: entry.fluidType,
                comments: entry.comments ?? "",
                color: entry.color,
                colorOther: entry.colorOther,
                consistency: entry.consistency,
                odor: entry.odor,
                drainageType: entry.drainageType,
                isFluidSalineFlush: entry.isFluidSalineFlush ?? false,
                fluidSalineFlushAmount: entry.fluidSalineFlushAmount ?? 0,
                fluidSalineFlushAmountUnit: entry.fluidSalineFlushAmountUnit ?? "ml",
                odorPresent: entry.odorPresent ?? false,
                doctorNotified: entry.doctorNotified ?? false,
                painLevel: entry.painLevel ?? 0,
                temperature: entry.temperature ?? 0,
                recordedAt: dateFormatter.string(from: entry.recordedAt),
                beforeImage: entry.beforeImage,
                afterImage: entry.afterImage,
                fluidCupImage: entry.fluidCupImage,
                incident: entry.incidentId
            )

            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + APIConfig.Path.drainageEntries) else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let response = try decoder.decode(SingleDrainageResponse.self, from: data)
                entries.insert(response.data, at: 0)
                successMessage = "Entry added successfully"
               
            } else {
                throw NetworkError.apiError("Failed to add entry: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        } catch let decodingError as DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Missing key '\(key.stringValue)' – \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type '\(type)' – \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found for type '\(type)' – \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to decode server response"
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func updateEntry(_ entry: DrainageEntry) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Format date to match API expectation
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let request = DrainageEntryRequest(
                patientId: TokenManager.shared.getUserId() ?? "",
                patientName: TokenManager.shared.getUserName() ?? "",
                amount: entry.amount,
                amountUnit: entry.amountUnit,
                location: entry.location,
                fluidType: entry.fluidType,
                comments: entry.comments ?? "",
                color: entry.color,
                colorOther: entry.colorOther,
                consistency: entry.consistency,
                odor: entry.odor,
                drainageType: entry.drainageType,
                isFluidSalineFlush: entry.isFluidSalineFlush ?? false,
                fluidSalineFlushAmount: entry.fluidSalineFlushAmount ?? 0,
                fluidSalineFlushAmountUnit: entry.fluidSalineFlushAmountUnit ?? "ml",
                odorPresent: entry.odorPresent ?? false,
                doctorNotified: entry.doctorNotified ?? false,
                painLevel: entry.painLevel ?? 0,
                temperature: entry.temperature ?? 0,
                recordedAt: dateFormatter.string(from: entry.recordedAt),
                beforeImage: entry.beforeImage,
                afterImage: entry.afterImage,
                fluidCupImage: entry.fluidCupImage,
                incident: entry.incidentId
            )

            // Create the URL request
            guard let url = URL(string: APIConfig.baseURL + APIConfig.Path.drainageEntries + "/\(entry.id)") else {
                throw NetworkError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "PUT"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            // Log the request
            NetworkLogger.log(request: urlRequest)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                
                // Decode the response
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let response = try decoder.decode(SingleDrainageResponse.self, from: data)
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = response.data
                }
                successMessage = "Entry updated successfully"
              
            } else {
                throw NetworkError.apiError("Failed to update entry: \(httpResponse.statusCode)")
            }
            
        } catch let error as NetworkError {
            print("Network error occurred: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }catch let decodingError as DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("Missing key '\(key.stringValue)' – \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type '\(type)' – \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value not found for type '\(type)' – \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to decode server response"
        } catch {
            print("Unexpected error occurred: \(error.localizedDescription)")
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    // MARK: - Image Upload
    func uploadEventImage(_ image: UIImage) async throws -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.4) else {
            throw NetworkError.invalidData
        }
        
        // Get image details
        let imageSize = Int64(imageData.count)
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "image_\(timestamp).jpg"
        
        print("Preparing to upload image: \(uniqueFileName) with size: \(imageSize)")
        
        // 1. Get upload URL with correct file information
        let fileInfo = FileInfo(
            name: uniqueFileName,
            type: "image/jpeg",
            size: imageSize
        )
        
        let uploadRequest = UploadUrlRequest(
            files: [fileInfo],
            folderName: folderName
        )
        
        // Get upload URL using NetworkManager
        let uploadUrlResponse = try await networkManager.getUploadUrls(request: uploadRequest)
        guard let uploadData = uploadUrlResponse.data.first else {
            throw NetworkError.invalidResponse
        }
        
        print("Got signed URL for upload: \(uploadData.signedUrl)")
        
        // 2. Upload image using NetworkManager
        try await networkManager.uploadFile(
            url: uploadData.signedUrl,
            data: imageData,
            contentType: "image/jpeg"
        )
        
        print("Image upload completed successfully")
        return uploadData.url
    }
}
