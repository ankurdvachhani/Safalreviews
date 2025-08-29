//
//  ReportsList.swift
//  SafalCalendar
//
//  Created by Apple on 30/06/25.
//

import Foundation
import UIKit

// MARK: - Models
struct ReportResponselog: Codable {
    let success: Bool
    let data: [Report]
    let sort: SortInfo
    let pagination: PaginationInfo
    let errors: [String]?
    let timestamp: String?
    let message: String?
}

struct Report: Identifiable, Codable {
    let id: String
    let module: String
    let title: String
    let newValue: NewValue?
    let oldValue: NewValue?
    let formattedNewValue: String
    let formattedOldValue: String
    let referenceId: String?
    let userId: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case module, title, newValue, oldValue, formattedNewValue, formattedOldValue, referenceId, userId, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        module = try container.decode(String.self, forKey: .module)
        title = try container.decode(String.self, forKey: .title)
        newValue = try container.decodeIfPresent(NewValue.self, forKey: .newValue)
        oldValue = try container.decodeIfPresent(NewValue.self, forKey: .oldValue)
        formattedNewValue = try container.decode(String.self, forKey: .formattedNewValue)
        formattedOldValue = try container.decode(String.self, forKey: .formattedOldValue)
        referenceId = try container.decodeIfPresent(String.self, forKey: .referenceId)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        
        // Custom date decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }
}

struct NewValue: Codable {
    let name: String?
    let eventDate: Date?
    let meetingDate: Date?
    let description: String?
    let image: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let profilePicture: String?
    let durationValue: Int?
    let durationType: String?
    let locationType: String?
    let locationValue: String?
    let inviteeLimit: Int?
}

enum ReportSortOption: String, CaseIterable, Identifiable {
    case createdAt = "Created At"
    case module = "Module"
    case title = "Title"
    
    var id: String { rawValue }
    
    var sortDescriptor: (Report, Report) -> Bool {
        switch self {
        case .createdAt:
            return { $0.createdAt > $1.createdAt }
        case .module:
            return { $0.module < $1.module }
        case .title:
            return { $0.title < $1.title }
        }
    }
    
    var apiParameters: (String, String) {
        switch self {
        case .createdAt:
            return ("createdAt", "desc")
        case .module:
            return ("module", "asc")
        case .title:
            return ("title", "asc")
        }
    }
}

enum ReportSortOrder: String, CaseIterable, Identifiable {
    case ascending = "asc"
    case descending = "desc"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

enum ReportModuleFilter: String, CaseIterable, Identifiable {
    case all = "all"
    case drainage = "drainage"
    case incident = "incident"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all:
            return "All Modules"
        case .drainage:
            return "Drainage"
        case .incident:
            return "Incident"
        }
    }
}

struct ReportFilters {
    var sortOption: ReportSortOption = .createdAt
    var sortOrder: ReportSortOrder = .descending
    var moduleFilter: ReportModuleFilter = .all
    var startDate: Date?
    var endDate: Date?
    
    var hasActiveFilters: Bool {
        moduleFilter != .all || startDate != nil || endDate != nil
    }
    
    var apiParameters: [URLQueryItem] {
        var params: [URLQueryItem] = []
        
        // Sort parameters
        params.append(URLQueryItem(name: "orderBy", value: sortOption.apiParameters.0))
        params.append(URLQueryItem(name: "order", value: sortOrder.rawValue))
        
        // Module filter
        if moduleFilter != .all {
            params.append(URLQueryItem(name: "module", value: moduleFilter.rawValue))
        }
        
        // Date range filters
        if let startDate = startDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            params.append(URLQueryItem(name: "startDate", value: dateFormatter.string(from: startDate)))
        }
        
        if let endDate = endDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            params.append(URLQueryItem(name: "endDate", value: dateFormatter.string(from: endDate)))
        }
        
        return params
    }
    
    var debugDescription: String {
        var desc = "Sort: \(sortOption.rawValue) (\(sortOrder.rawValue))"
        if moduleFilter != .all {
            desc += ", Module: \(moduleFilter.rawValue)"
        }
        if let startDate = startDate {
            desc += ", Start: \(startDate.formatted(date: .abbreviated, time: .omitted))"
        }
        if let endDate = endDate {
            desc += ", End: \(endDate.formatted(date: .abbreviated, time: .omitted))"
        }
        return desc
    }
}

@MainActor
final class ReportsListViewModel: ObservableObject {
    @Published private(set) var reports: [Report] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published private(set) var hasMorePages = true
    @Published var filters = ReportFilters()
    
    private let networkManager = NetworkManager()
    private var currentPage = 1
    private let limit = 20
    private var searchTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var isFetching = false
    private var totalReports = 0
    private var currentSearchQuery = ""
    
    // MARK: - Init
    
    init() {
        Task {
            await fetchReports()
        }
    }
    
    // MARK: - Public Methods
    
    func loadMoreIfNeeded(currentItem: Report?) async {
        guard let currentItem = currentItem,
              let lastItem = reports.last,
              currentItem.id == lastItem.id,
              !isLoading,
              hasMorePages,
              !isFetching
        else { 
            print("🚫 Load more conditions not met:")
            print("  - Current item: \(currentItem?.id ?? "nil")")
            print("  - Last item: \(reports.last?.id ?? "nil")")
            print("  - Is loading: \(isLoading)")
            print("  - Has more pages: \(hasMorePages)")
            print("  - Is fetching: \(isFetching)")
            return 
        }
        
        print("📱 Triggering load more for page: \(currentPage)")
        print("📱 Current reports count: \(reports.count)")
        print("📱 Total reports available: \(totalReports)")
        
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await fetchReports(searchQuery: currentSearchQuery)
        }
        
        // Wait for the fetch task to complete
        await fetchTask?.value
    }
    
    func resetPagination() {
        currentPage = 1
        hasMorePages = true
        reports = []
        totalReports = 0
        currentSearchQuery = ""
        isLoading = false
        isFetching = false
        errorMessage = nil
        successMessage = nil
        
        // Cancel any existing tasks
        searchTask?.cancel()
        refreshTask?.cancel()
        fetchTask?.cancel()
        
        print("🔄 Pagination reset")
    }
    
    func applyFilters() {
        resetPagination()
        Task {
            await fetchReports()
        }
    }
    
    func clearFilters() {
        filters = ReportFilters()
        applyFilters()
    }
    
    func fetchReports(searchQuery: String = "", resetPages: Bool = false) async {
        guard !isFetching else { 
            print("⚠️ Fetch already in progress, skipping...")
            return 
        }
        
        if resetPages {
            currentPage = 1
            hasMorePages = true
            reports = []
            totalReports = 0
        }
        
        guard hasMorePages else { 
            print("⚠️ No more pages available, skipping...")
            return 
        }
        
        isLoading = true
        isFetching = true
        errorMessage = nil
        currentSearchQuery = searchQuery
        
        print("🔄 Starting fetch for page \(currentPage)")
        
        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "page", value: "\(currentPage)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "search", value: searchQuery.isEmpty ? nil : searchQuery)
            ]
            
            // Add filter parameters
            queryItems.append(contentsOf: filters.apiParameters)
            
            let endpoint = Endpoint(
                path: APIConfig.Path.reportChangeLog,
                queryItems: queryItems
            )
            
            print("📡 API Request - Page: \(currentPage), Limit: \(limit), Search: \(searchQuery)")
            print("📡 Filters: \(filters.debugDescription)")
            print("📡 Full URL: \(endpoint.url?.absoluteString ?? "Invalid URL")")
            
            let response: ReportResponselog = try await networkManager.fetch(endpoint)
            
            if !Task.isCancelled {
                totalReports = response.pagination.total
                
                // Calculate if there are more pages BEFORE incrementing currentPage
                let totalPages = Int(ceil(Double(response.pagination.total) / Double(limit)))
                hasMorePages = currentPage < totalPages
                
                print("📥 Received response - Total: \(response.pagination.total), Current page: \(currentPage), Total pages: \(totalPages)")
                print("📥 Response data count: \(response.data.count)")
                print("📥 Has more pages: \(hasMorePages)")
                
                if currentPage == 1 {
                    reports = response.data
                    print("📥 First page - Set reports to \(reports.count) items")
                } else {
                    // Filter out duplicates before appending
                    let newReports = response.data.filter { newReport in
                        !reports.contains { $0.id == newReport.id }
                    }
                    reports.append(contentsOf: newReports)
                    print("📥 Subsequent page - Added \(newReports.count) new items, total now: \(reports.count)")
                }
                
                // Only increment page if we got data
                if !response.data.isEmpty {
                    currentPage += 1
                }
                
                print("📊 Pagination Status:")
                print("  - Current Page: \(currentPage)")
                print("  - Total Reports: \(totalReports)")
                print("  - Loaded Reports: \(reports.count)")
                print("  - Has More Pages: \(hasMorePages)")
                print("  - New Data Count: \(response.data.count)")
            }
        } catch {
            if !Task.isCancelled {
                print("❌ Error details:")
                print("  - Error type: \(type(of: error))")
                print("  - Error description: \(error.localizedDescription)")
                
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .cancelled:
                        print("⚠️ Network request was cancelled")
                    case .noInternet:
                        print("❌ No internet connection")
                    case .invalidURL:
                        print("❌ Invalid URL")
                    case .invalidResponse:
                        print("❌ Invalid response")
                    case .unauthorized:
                        print("❌ Unauthorized")
                    case .apiError(let message):
                        print("❌ API Error: \(message)")
                    case .serverError(let code):
                        print("❌ Server Error: \(code)")
                    case .decodingError:
                        print("❌ Decoding Error")
                    case .unknown(let underlyingError):
                        print("❌ Unknown Error: \(underlyingError)")
                    case .noData:
                        print("❌ Unknown Error: ")
                    }
                } else {
                    print("❌ Non-network error: \(error)")
                }
                
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
        isFetching = false
        print("✅ Fetch completed for page \(currentPage - 1)")
    }
    
    func searchReports(query: String) {
        // Cancel any existing search task
        searchTask?.cancel()
        
        // Create a new search task
        searchTask = Task {
            // Reset pagination
            currentPage = 1
            hasMorePages = true
            reports = []
            totalReports = 0
            currentSearchQuery = query
            
            // Wait a bit to avoid too many API calls while typing
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled
            if !Task.isCancelled {
                await fetchReports(searchQuery: query, resetPages: true)
            }
        }
    }
    
    func refreshReports() async {
        // Cancel any existing tasks
        searchTask?.cancel()
        refreshTask?.cancel()
        fetchTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            // Reset pagination and clear loading state
            currentPage = 1
            hasMorePages = true
            reports = []
            totalReports = 0
            currentSearchQuery = ""
            isLoading = true
            errorMessage = nil
            
            do {
                var queryItems: [URLQueryItem] = [
                    URLQueryItem(name: "page", value: "1"),
                    URLQueryItem(name: "limit", value: "\(limit)")
                ]
                
                // Add filter parameters
                queryItems.append(contentsOf: filters.apiParameters)
                
                let endpoint = Endpoint(
                    path: APIConfig.Path.reportChangeLog,
                    queryItems: queryItems
                )
                
                let response: ReportResponselog = try await networkManager.fetch(endpoint)
                
                if !Task.isCancelled {
                    reports = response.data
                    totalReports = response.pagination.total
                    currentPage = 2 // Set to 2 since we just loaded page 1
                    
                    // Calculate if there are more pages
                    let totalPages = Int(ceil(Double(response.pagination.total) / Double(limit)))
                    hasMorePages = 1 < totalPages
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            
            isLoading = false
        }
        
        // Wait for the refresh task to complete
        await refreshTask?.value
    }
}


