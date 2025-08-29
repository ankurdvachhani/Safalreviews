import Foundation
import SwiftUI

@MainActor
class IncidentReportStore: ObservableObject {
    @Published var reports: [IncidentReport] = []
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
    private var totalReports = 0
    
    // MARK: - Init
    init() {
        Task {
            await fetchReports()
        }
    }
    
    // MARK: - Public Methods
    func loadMoreIfNeeded(currentItem: IncidentReport?) async {
        guard let currentItem = currentItem,
              let lastItem = reports.last,
              currentItem.id == lastItem.id,
              !isLoading,
              hasMorePages,
              !isFetching
        else { return }
        
        print("📱 Triggering load more for page: \(currentPage)")
        print("📱 Current reports count: \(reports.count)")
        print("📱 Total reports available: \(totalReports)")
        
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create new fetch task
        fetchTask = Task {
            await fetchReports()
        }
        
        // Wait for the fetch task to complete
        await fetchTask?.value
    }
    
    func fetchReports(searchQuery: String = "", resetPages: Bool = false, sortOption: IncidentReportSortOption = .dateDesc) async {
        print("🔍 IncidentReportStore.fetchReports - searchQuery: \(searchQuery)")
        
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
        
        print("🔄 Starting fetch for page \(currentPage)")
        
        do {
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "page", value: "\(currentPage)"),
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "order", value: sortOption.apiOrder),
                URLQueryItem(name: "orderBy", value: sortOption.apiOrderBy)
            ]
            
            if !searchQuery.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: searchQuery))
            }

            // Create the endpoint
            let endpoint = Endpoint(
                path: "/api/report",
                queryItems: queryItems
            )
            
            print("📡 API Request - Page: \(currentPage), Limit: \(limit), Search: \(searchQuery)")
            
            let response: IncidentReportListResponse = try await networkManager.fetch(endpoint)
            
            if !Task.isCancelled {
                totalReports = response.pagination.total
                hasMorePages = response.pagination.current < totalReports
                
                print("📥 Received response - Total: \(response.pagination.total), Current page: \(currentPage)")
                
                if currentPage == 1 {
                    reports = response.data
                } else {
                    // Filter out duplicates before appending
                    let newReports = response.data.filter { newReport in
                        !reports.contains { $0.id == newReport.id }
                    }
                    reports.append(contentsOf: newReports)
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
    
    func refreshReports() async {
        // Cancel any existing refresh task
        refreshTask?.cancel()
        
        // Create new refresh task
        refreshTask = Task {
            // Reset pagination and clear loading state
            currentPage = 1
            hasMorePages = true
            reports = []
            isLoading = true
            errorMessage = nil
            
            await fetchReports()
            
            isLoading = false
            refreshTask = nil
        }
        
        // Wait for the refresh task to complete
        await refreshTask?.value
    }
    
    func searchReports(query: String) {
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
                await fetchReports(searchQuery: query, resetPages: true)
            }
        }
    }
    
    // MARK: - Report Download
    
    func downloadReport(reportId: String) async throws -> URL {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current device time zone
            let timeZone = TimeZone.current.identifier
            
            let endpoint = Endpoint(
                path: "/api/report/\(reportId)",
                method: .get,
                queryItems: [
                    URLQueryItem(name: "tz", value: timeZone)
                ]
            )
            
            print("📄 Downloading report: \(reportId) with timezone: \(timeZone)")
            
            let response: incidentReportResponse = try await networkManager.fetch(endpoint)
            
            guard let signedUrl = response.data.urlSign,
                  let url = URL(string: signedUrl) else {
                throw NetworkError.invalidURL
            }
            
            print("✅ Report URL obtained: \(signedUrl)")
            return url
            
        } catch {
            print("❌ Failed to download report: \(error.localizedDescription)")
            errorMessage = "Failed to download report: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Fetch Single Report
    
    func fetchReportDetail(id: String) async throws -> IncidentReport {
        do {
            // Get current device time zone
            let timeZone = TimeZone.current.identifier
            
            let endpoint = Endpoint(
                path: "/api/report/\(id)",
                method: .get,
                queryItems: [
                    URLQueryItem(name: "tz", value: timeZone)
                ]
            )
            
            print("📄 Fetching report details: \(id) with timezone: \(timeZone)")
            
            let response: incidentReportResponse = try await networkManager.fetch(endpoint)
            
            // Convert the response data to IncidentReport
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            let createdAt = dateFormatter.date(from: response.data.createdAt) ?? Date()
            let updatedAt = dateFormatter.date(from: response.data.updatedAt) ?? Date()
            
            let report = IncidentReport(
                id: response.data.id,
                userId: response.data.userId,
                title: response.data.title,
                reportId: response.data.reportId,
                organizationId: response.data.organizationId,
                refId: response.data.refId,
                url: response.data.url,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            print("✅ Report details fetched successfully")
            return report
            
        } catch {
            print("❌ Failed to fetch report details: \(error.localizedDescription)")
            errorMessage = "Failed to fetch report details: \(error.localizedDescription)"
            throw error
        }
    }
}
