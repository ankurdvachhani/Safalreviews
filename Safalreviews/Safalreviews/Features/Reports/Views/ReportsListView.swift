//
//  ReportsListView.swift
//  SafalCalendar
//
//  Created by Apple on 30/06/25.
//

import SwiftUI

struct ReportsListView: View {
    @StateObject private var viewModel = ReportsListViewModel()
    @State private var searchText = ""
    @State private var showingSortSheet = false
    @State private var showingFilterSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar and sort/filter buttons
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    searchBar
                    
                    // Filter button
                    Button {
                        showingFilterSheet = true
                    } label: {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color.dynamicAccent)
                            
                            // Red dot indicator for active filters
                            if viewModel.filters.hasActiveFilters {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    
                    // Sort button
                    Button {
                        showingSortSheet = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(Color.dynamicAccent)
                    }
                }
                .padding()
            }
            .padding(.vertical, 12)
            
            // Content
            if viewModel.isLoading && viewModel.reports.isEmpty {
                reportsShimmerList
            } else if !searchText.isEmpty && filteredReports.isEmpty {
                ReportNoSearchResultsView(searchText: searchText)
            } else if viewModel.reports.isEmpty {
                EmptyReportsView()
            } else {
                reportsList
            }
        }
        .navigationTitle("Change Log")
        .sheet(isPresented: $showingSortSheet) {
            ReportSortSheet(
                selectedSortOption: $viewModel.filters.sortOption,
                selectedSortOrder: $viewModel.filters.sortOrder,
                isPresented: $showingSortSheet
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showingSortSheet) { isPresented in
            if !isPresented {
                // Apply filters when sort sheet is dismissed
                viewModel.applyFilters()
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ReportFilterSheet(
                filters: $viewModel.filters,
                isPresented: $showingFilterSheet
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: showingFilterSheet) { isPresented in
            if !isPresented {
                // Apply filters when filter sheet is dismissed
                viewModel.applyFilters()
            }
        }
        .onChange(of: searchText) { newValue in
            print("🔎 Search Text Changed to: \(newValue)")
            if newValue.isEmpty {
                // Reset pagination and fetch fresh data when search is cleared
                viewModel.resetPagination()
                Task {
                    await viewModel.fetchReports()
                }
            } else {
                viewModel.searchReports(query: newValue)
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshReports()
            }
        }
        .toast(message: $viewModel.errorMessage, type: .error)
        .toast(message: $viewModel.successMessage, type: .success)
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("Search by title name...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var reportsList: some View {
        ZStack {
            List {
                ForEach(filteredReports) { report in
                    ReportRow(report: report)
                        .contentShape(Rectangle())
                        .task {
                            // Only trigger pagination for the last item in the original reports array
                            if let lastReport = viewModel.reports.last,
                               report.id == lastReport.id {
                                await viewModel.loadMoreIfNeeded(currentItem: report)
                            }
                        }
                }
                
                // Loading indicator at the bottom
                if viewModel.isLoading && !viewModel.reports.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
                
                // End of list indicator
                if !viewModel.hasMorePages && !viewModel.reports.isEmpty {
                    HStack {
                        Spacer()
                        Text("End of reports")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                try? await Task.sleep(nanoseconds: 500_000_000) // Add a small delay
                await viewModel.refreshReports()
            }
        }
    }
    
    private var reportsShimmerList: some View {
        List {
            ForEach(0..<5) { _ in
                ShimmerReportRow()
            }
        }
        .listStyle(.plain)
        .disabled(true)
    }
    
    private var filteredReports: [Report] {
        print("🔍 Total Reports: \(viewModel.reports.count)")
        return viewModel.reports
    }
}

struct ReportRow: View {
    let report: Report
    
    private var moduleIcon: String {
        switch report.module {
        case "event":
            return "calendar"
        case "meeting":
            return "video"
        case "profile":
            return "person.circle"
        default:
            return "doc.text"
        }
    }
    
    private var moduleColor: Color {
        switch report.module {
        case "event":
            return Color.dynamicEvent
        case "meeting":
            return Color.dynamicMeeting
        case "profile":
            return Color.dynamicAccent
        default:
            return Color.dynamicAccent
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and Module
            HStack {
                Image(systemName: moduleIcon)
                    .foregroundColor(moduleColor)
                    .font(.system(size: 18))
                
                Text(report.module.capitalized)
                    .font(.subheadline)
                    .foregroundColor(moduleColor)
                
                Spacer()
                
                Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(report.title)
                .font(.headline)
                .lineLimit(2)
            
            // Changes
            if !report.formattedNewValue.isEmpty {
                Text("New value:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(report.formattedNewValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    
            }
            
            if !report.formattedOldValue.isEmpty {
                Text("Old value:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(report.formattedOldValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                   
            }
            
        }
        .padding(.vertical, 8)
    }
}

struct ShimmerReportRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                EventShimmerBox(width: 24, height: 24)
                EventShimmerBox(width: 80, height: 16)
                Spacer()
                EventShimmerBox(width: 100, height: 16)
            }
            
            EventShimmerBox(width: .infinity, height: 20)
            EventShimmerBox(width: .infinity, height: 16)
            EventShimmerBox(width: .infinity, height: 16)
        }
        .padding(.vertical, 8)
    }
}
struct EventShimmerBox: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: height/4)
            .fill(LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray5),
                    Color(.systemGray6),
                    Color(.systemGray5)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(width: width == .infinity ? nil : width, height: height)
            .frame(maxWidth: width == .infinity ? .infinity : nil)
            .mask(
                RoundedRectangle(cornerRadius: height/4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .white, .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .offset(x: isAnimating ? (width == .infinity ? UIScreen.main.bounds.width : width) : -(width == .infinity ? UIScreen.main.bounds.width : width))
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

struct EmptyReportsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent)
            
            Text("No Reports")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("There are no reports to display at this time")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReportNoSearchResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.dynamicAccent)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No reports found for '\(searchText)'")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Try different keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReportSortSheet: View {
    @Binding var selectedSortOption: ReportSortOption
    @Binding var selectedSortOrder: ReportSortOrder
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Sort Options
                Section(header: Text("Sort By")) {
                    ForEach(ReportSortOption.allCases) { option in
                        HStack {
                            Button(action: {
                                selectedSortOption = option
                            }) {
                                HStack {
                                    Image(systemName: selectedSortOption == option ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSortOption == option ? .accentColor : .gray)
                                    Text(option.rawValue)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                    }
                }
                
                // Sort Order
                Section(header: Text("Order")) {
                    ForEach(ReportSortOrder.allCases) { order in
                        HStack {
                            Button(action: {
                                selectedSortOrder = order
                            }) {
                                HStack {
                                    Image(systemName: selectedSortOrder == order ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedSortOrder == order ? .accentColor : .gray)
                                    Text(order.displayName)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Sort Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        isPresented = false
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct ReportFilterSheet: View {
    @Binding var filters: ReportFilters
    @Binding var isPresented: Bool
    @State private var tempFilters: ReportFilters
    @Environment(\.dismiss) private var dismiss
    
    init(filters: Binding<ReportFilters>, isPresented: Binding<Bool>) {
        self._filters = filters
        self._isPresented = isPresented
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Module Filter
                Section(header: Text("Module")) {
                    ForEach(ReportModuleFilter.allCases) { module in
                        HStack {
                            Button(action: {
                                tempFilters.moduleFilter = module
                            }) {
                                HStack {
                                    Image(systemName: tempFilters.moduleFilter == module ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(tempFilters.moduleFilter == module ? .accentColor : .gray)
                                    Text(module.displayName)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                    }
                }
                
                // Date Range Filter
                Section(header: Text("Date Range")) {
                    DatePicker("Start Date", selection: Binding(
                        get: { tempFilters.startDate ?? Date() },
                        set: { tempFilters.startDate = $0 }
                    ), displayedComponents: [.date])
                    
                    DatePicker("End Date", selection: Binding(
                        get: { tempFilters.endDate ?? Date() },
                        set: { tempFilters.endDate = $0 }
                    ), displayedComponents: [.date])
                    
                    if tempFilters.startDate != nil || tempFilters.endDate != nil {
                        Button("Clear Date Range") {
                            tempFilters.startDate = nil
                            tempFilters.endDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filter Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        tempFilters = ReportFilters()
                        filters = tempFilters
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filters = tempFilters
                        isPresented = false
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    ReportsListView()
}
