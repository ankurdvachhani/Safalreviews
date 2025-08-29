import SwiftUI
import CoreImage.CIFilterBuiltins

extension Notification.Name {
    static let updateDrainageRecord = Notification.Name("updateDrainageRecord")
    static let RefreshDrainageList = Notification.Name("RefreshDrainageList")
}

// MARK: - Filter Model
struct DrainageFilter {
    var minAmount: Double?
    var maxAmount: Double?
    var minTemperature: Double?
    var maxTemperature: Double?
    var minPainLevel: Int?
    var maxPainLevel: Int?
    var minRecordedAt: Date?
    var maxRecordedAt: Date?
    var odor: [String] = []
    var fluidType: [String] = []
    var color: [String] = []
    var drainageType: [String] = []
    var consistency: [String] = []
    var patientId: String?
    
    var hasActiveFilters: Bool {
        return minAmount != nil || maxAmount != nil ||
               minTemperature != nil || maxTemperature != nil ||
               minPainLevel != nil || maxPainLevel != nil ||
               minRecordedAt != nil || maxRecordedAt != nil ||
               !odor.isEmpty || !fluidType.isEmpty || !color.isEmpty ||
               !drainageType.isEmpty || !consistency.isEmpty || patientId != nil
    }
    
    mutating func clearAll() {
        minAmount = nil
        maxAmount = nil
        minTemperature = nil
        maxTemperature = nil
        minPainLevel = nil
        maxPainLevel = nil
        minRecordedAt = nil
        maxRecordedAt = nil
        odor.removeAll()
        fluidType.removeAll()
        color.removeAll()
        drainageType.removeAll()
        consistency.removeAll()
        patientId = nil
    }
}

struct DrainageListView: View {
    @EnvironmentObject var store: DrainageStore
    @StateObject private var configService = ConfigurationService.shared
    @State private var showingAddDrainage = false
    @State private var searchText = ""
    @State private var selectedSortOption: DrainageSortOption = .dateDesc
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: DrainageEntry?
    @State private var showingSortSheet = false
    @State private var selectedEntryForBarcode: DrainageEntry?
    
    // Filter states
    @State private var showingFilterSheet = false
    @State private var currentFilter = DrainageFilter()
    
    // Patient filter properties
    let patientSlug: String?
    let patientName: String?
    let incidentId: String?
    
    init(patientSlug: String? = nil, patientName: String? = nil, incidentId: String? = nil) {
        self.patientSlug = patientSlug
        self.patientName = patientName
        self.incidentId = incidentId
        print("🔍 DrainageListView init - patientSlug: \(patientSlug ?? "nil"), patientName: \(patientName ?? "nil"), incidentId: \(incidentId ?? "nil")")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar and buttons row
            if patientSlug == nil && incidentId == nil{
                HStack(spacing: 12) {
                    searchBar
                    
                    // Sort button
                    Button {
                        showingSortSheet = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.up.arrow.down.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.dynamicAccent)
                        }
                    }
                    
                    // Filter button
                    Button {
                        showingFilterSheet = true
                    } label: {
                        ZStack {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color.dynamicAccent)
                            
                            // Red dot indicator for active filters
                            if currentFilter.hasActiveFilters {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                    
                    // Create button - only show if incident is enabled in configuration
                    if configService.isIncidentEnabled {
                        Button {
                            NavigationManager.shared.navigate(to: .addDrainage(), style: .presentSheet())
                        } label: {
                            Circle()
                                .fill(Color.dynamicAccent)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.dynamicAccent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding()
            }
           
            
            // Content
            ZStack {
                if store.isLoading && store.entries.isEmpty {
                    drainageShimmerList
                } else if !searchText.isEmpty && filteredEntries.isEmpty {
                    DrainageNoSearchResultsView(searchText: searchText)
                } else if store.entries.isEmpty && currentFilter.hasActiveFilters {
                    DrainageNoFilterResultsView(currentFilter: currentFilter) {
                        // Clear filters action
                        currentFilter.clearAll()
                        Task {
                            await store.refreshEntries(patientSlug: store.initialPatientSlug, incidentId: store.initialIncidentId, filter: currentFilter)
                        }
                    }
                } else if store.entries.isEmpty {
                    if let patientName = patientName, !patientName.isEmpty {
                        EmptyPatientDrainageView(patientName: patientName)
                    } else {
                        EmptyDrainageView()
                    }
                } else {
                    drainageList
                }
            }
            .navigationTitle(navigationTitle)
        }
        .onAppear {
            // Add notification observer
            NotificationCenter.default.addObserver(
                forName: .RefreshDrainageList,
                object: nil,
                queue: .main
            ) { _ in
                Task {
                    await store.refreshEntries(patientSlug: store.initialPatientSlug, incidentId: store.initialIncidentId, filter: currentFilter)
                }
            }
            // DrainageStore is already initialized with the correct patient filter
            print("🔍 onAppear - patientSlug: \(patientSlug ?? "nil"), patientName: \(patientName ?? "nil"), incidentId: \(incidentId ?? "nil")")
            // No need to fetch again as DrainageStore.init() already handles this
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(self)
        }
        .sheet(isPresented: $showingAddDrainage) {
            NavigationView {
                AddDrainageView()
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingSortSheet) {
            DrainageSortSheet(
                selectedSortOption: $selectedSortOption,
                isPresented: $showingSortSheet,
                onSortChanged: { newSortOption in
                    Task {
                        await store.updateSortOption(newSortOption, filter: currentFilter)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingFilterSheet) {
            DrainageFilterSheet(
                filter: $currentFilter,
                onApply: {
                    Task {
                        await store.refreshEntries(patientSlug: store.initialPatientSlug, incidentId: store.initialIncidentId, filter: currentFilter)
                    }
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: searchText) { newValue in
            store.searchEntries(query: newValue, filter: currentFilter)
        }
        .toast(message: $store.errorMessage, type: .error)
        .toast(message: $store.successMessage, type: .success)
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    Task {
                        await store.deleteEntry(entry)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this drainage entry? This action cannot be undone.")
        }
        .sheet(item: $selectedEntryForBarcode) { entry in
            BarcodeDisplayView(drainageId: entry.drainageId ?? "")
        }
    }
    
    private var drainageList: some View {
        List {
            ForEach(filteredEntries) { entry in
                PesentDrainageRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NavigationManager.shared.navigate(to: .drainageDetail(entry: entry))
                    }
                    .task {
                        await store.loadMoreIfNeeded(currentItem: entry, filter: currentFilter)
                    }
                .swipeActions(edge: .trailing) {
                    // Barcode button
                    if let drainageId = entry.drainageId, !drainageId.isEmpty {
                        Button {
                            selectedEntryForBarcode = entry
                        } label: {
                            Label("DrainageID Code", systemImage: "barcode")
                        }
                        .tint(.blue)
                    }
                    
                    if entry.userId == TokenManager.shared.getUserId() {
                        Button(role: .destructive) {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                  
                }
                .contextMenu {
                    // Barcode option
                    if let drainageId = entry.drainageId, !drainageId.isEmpty {
                        Button {
                            selectedEntryForBarcode = entry
                        } label: {
                            Label("DrainageID Code", systemImage: "barcode")
                        }
                    }
                    
                    if entry.userId == TokenManager.shared.getUserId() {
                        Button(role: .destructive) {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            try? await Task.sleep(nanoseconds: 500_000_000) // Add a small delay
            await store.refreshEntries(patientSlug: store.initialPatientSlug, incidentId: store.initialIncidentId, filter: currentFilter)
        }
    }
    
    private var drainageShimmerList: some View {
        List {
            ForEach(0..<5) { _ in
                DrainageShimmerRow()
            }
        }
        .listStyle(.plain)
        .disabled(true)
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            TextField("Search Drainage...", text: $searchText)
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
    
    private var filteredEntries: [DrainageEntry] {
        // Server-side sorting is now handled by the API
        return store.entries
    }
    
    private var navigationTitle: String {
        if let incidentId = incidentId, !incidentId.isEmpty {
            return "Incident Records"
        } else if let patientName = patientName, !patientName.isEmpty {
            return "\(patientName)'s Drainage"
        } else {
            return "Drainage Entries"
        }
    }
}

// MARK: - Supporting Views
struct DrainageShimmerRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                DrainageShimmerBox(width: 150, height: 20)
                Spacer()
                DrainageShimmerBox(width: 80, height: 20)
            }
            
            HStack {
                DrainageShimmerBox(width: 100, height: 16)
                Spacer()
                DrainageShimmerBox(width: 120, height: 16)
            }
        }
        .padding(.vertical, 8)
    }
}

struct DrainageShimmerBox: View {
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
            .frame(width: width, height: height)
            .mask(
                RoundedRectangle(cornerRadius: height/4)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, .white, .clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .offset(x: isAnimating ? width : -width)
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

struct EmptyDrainageView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "drop.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent)
            
            Text("No Drainage Entries")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first drainage entry by tapping the + button above")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyPatientDrainageView: View {
    let patientName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent)
            
            Text("No Records Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No drainage entries found for \(patientName)")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("This patient may not have any drainage records yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DrainageNoSearchResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.dynamicAccent)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No drainage entries found for '\(searchText)'")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Try different keywords or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DrainageNoFilterResultsView: View {
    let currentFilter: DrainageFilter
    let onClearFilters: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 60))
                .foregroundColor(Color.dynamicAccent)
            
            Text("No Matching Records")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No drainage entries match your current filter criteria")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Show active filters summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Filters:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    if let minAmount = currentFilter.minAmount {
                        Text("• Min Amount: \(Int(minAmount)) ml")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let maxAmount = currentFilter.maxAmount {
                        Text("• Max Amount: \(Int(maxAmount)) ml")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let minTemp = currentFilter.minTemperature {
                        Text("• Min Temperature: \(minTemp, specifier: "%.1f")°F")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let maxTemp = currentFilter.maxTemperature {
                        Text("• Max Temperature: \(maxTemp, specifier: "%.1f")°F")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let minPain = currentFilter.minPainLevel {
                        Text("• Min Pain Level: \(minPain)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let maxPain = currentFilter.maxPainLevel {
                        Text("• Max Pain Level: \(maxPain)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !currentFilter.color.isEmpty {
                        Text("• Colors: \(currentFilter.color.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !currentFilter.fluidType.isEmpty {
                        Text("• Fluid Types: \(currentFilter.fluidType.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !currentFilter.drainageType.isEmpty {
                        Text("• Drainage Types: \(currentFilter.drainageType.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !currentFilter.consistency.isEmpty {
                        Text("• Consistency: \(currentFilter.consistency.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !currentFilter.odor.isEmpty {
                        Text("• Odor: \(currentFilter.odor.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let patientId = currentFilter.patientId {
                        Text("• Patient ID: \(patientId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(spacing: 12) {
                Text("Try adjusting your filters or")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button {
                    onClearFilters()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear All Filters")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.dynamicAccent)
                    .cornerRadius(25)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct DrainageSortSheet: View {
    @Binding var selectedSortOption: DrainageSortOption
    @Binding var isPresented: Bool
    let onSortChanged: (DrainageSortOption) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            Text("Sort & Order")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 12)
                .padding(.bottom, 10)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Date/Time Sorting
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Date & Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        ForEach([DrainageSortOption.dateDesc, .dateAsc, .createdAtDesc, .createdAtAsc]) { option in
                            SortOptionRow(option: option, isSelected: option == selectedSortOption) {
                                selectedSortOption = option
                                onSortChanged(option)
                                isPresented = false
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Amount Sorting
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Fluid Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        ForEach([DrainageSortOption.amountDesc, .amountAsc]) { option in
                            SortOptionRow(option: option, isSelected: option == selectedSortOption) {
                                selectedSortOption = option
                                onSortChanged(option)
                                isPresented = false
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Location Sorting
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        ForEach([DrainageSortOption.locationAsc, .locationDesc]) { option in
                            SortOptionRow(option: option, isSelected: option == selectedSortOption) {
                                selectedSortOption = option
                                onSortChanged(option)
                                isPresented = false
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Health Metrics Sorting
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Health Metrics")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        
                        ForEach([DrainageSortOption.painLevelDesc, .painLevelAsc, .temperatureDesc, .temperatureAsc]) { option in
                            SortOptionRow(option: option, isSelected: option == selectedSortOption) {
                                selectedSortOption = option
                                onSortChanged(option)
                                isPresented = false
                            }
                        }
                    }
                }
            }
            
            HStack(spacing: 12) {
                // Reset button
                Button(action: {
                    selectedSortOption = .dateDesc
                    onSortChanged(.dateDesc)
                    isPresented = false
                }) {
                    Text("Reset")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.red)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
                
                // Cancel button
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Cancel")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(Color.dynamicAccent)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dynamicAccent, lineWidth: 2)
                        )
                }
            }
            .padding()
        }
        .background(Color.dynamicBackground)
        .cornerRadius(20)
    }
}

struct PesentDrainageRow: View {
    let entry: DrainageEntry
    
    private var netFluidAmount: Double {
        let totalAmount = entry.amount
        let salineFlushAmount = entry.fluidSalineFlushAmount ?? 0
        return totalAmount - salineFlushAmount
    }
    
    private var shouldShowPatientName: Bool {
        TokenManager.shared.loadCurrentUser()?.role != "Patient"
    }
    
    private var cellBackgroundColor: Color {
        let painLevel = entry.painLevel ?? 0
        switch painLevel {
        case 0...2: return .gray.opacity(0.1)
        case 3...5: return .yellow.opacity(0.1)
        case 6...8: return .orange.opacity(0.1)
        default: return .red.opacity(0.1)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Patient Info Row (only show if role is not Patient)
            if shouldShowPatientName, let patientName = entry.patientName, !patientName.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.dynamicAccent)
                    
                    Text(patientName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
            
            // Location and Drainage Type Row
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(entry.location)
                    .font(.headline)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Image(systemName: "drop.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
                
                Text(entry.drainageType)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                        
                        // Total Fluid Amount
                        Text("\(Int(entry.amount)) \(entry.amountUnit)")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }
                    
                    // Net Fluid Amount (if saline flush is present)
                    if entry.isFluidSalineFlush == true && entry.fluidSalineFlushAmount != nil && entry.fluidSalineFlushAmount! > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "drop.degreesign")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("Net: \(Int(netFluidAmount)) \(entry.amountUnit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Details Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "barcode")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(entry.drainageId ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(entry.recordedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Comment count
                    if let commentsArray = entry.commentsArray, !commentsArray.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "message.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            
                            Text("\(commentsArray.count)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Pain Level - Full Width
            PainLevelView(level: entry.painLevel ?? 0)
        }
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
}

struct PainLevelView: View {
    let level: Int
    
    private var painColor: Color {
        switch level {
        case 0...2: return .gray
        case 3...5: return .yellow
        case 6...8: return .orange
        default: return .red
        }
    }
    
    private var backgroundColor: Color {
        switch level {
        case 0...2: return .gray.opacity(0.2)
        case 3...5: return .yellow.opacity(0.2)
        case 6...8: return .orange.opacity(0.2)
        default: return .red.opacity(0.2)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(painColor)
            
            Text("\(level)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(painColor)
                .frame(width: 20, alignment: .center)
            
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(width: 40, height: 6)
                    .foregroundColor(Color.gray.opacity(0.3))
                
                Capsule()
                    .frame(width: CGFloat(min(level, 10)) * 4, height: 6)
                    .foregroundColor(painColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Barcode Display View
struct BarcodeDisplayView: View {
    let drainageId: String
    @Environment(\.dismiss) private var dismiss
    @State private var isBarcodeGenerated = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Drainage ID Barcode")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !drainageId.isEmpty {
                    VStack(spacing: 16) {
                        BarcodeView(data: drainageId)
                            .frame(height: 120)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onAppear {
                                isBarcodeGenerated = true
                            }
                        
                        Text(drainageId)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        Text("Scan this barcode to access drainage details")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "barcode")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No drainage ID available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("This drainage entry doesn't have a barcode ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("BarcodeDisplayView appeared with drainageId: \(drainageId)")
        }
    }
}

// MARK: - Drainage Filter Sheet
struct DrainageFilterSheet: View {
    @Binding var filter: DrainageFilter
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempFilter: DrainageFilter
    @State private var minAmountText = "0"
    @State private var maxAmountText = ""
    @State private var minTemperatureText = "0"
    @State private var maxTemperatureText = ""
    @State private var minPainLevelText = "0"
    @State private var maxPainLevelText = ""
    
    // Dropdown states
    @State private var showFluidTypeDropdown = false
    @State private var showColorDropdown = false
    @State private var showDrainageTypeDropdown = false
    @State private var showConsistencyDropdown = false
    @State private var showOdorDropdown = false
    @State private var showPatientDropdown = false
    @StateObject private var patientViewModel = PatientSelectionViewModel()
    
    init(filter: Binding<DrainageFilter>, onApply: @escaping () -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._tempFilter = State(initialValue: filter.wrappedValue)
        
        // Initialize text fields
        if let minAmount = filter.wrappedValue.minAmount {
            self._minAmountText = State(initialValue: String(format: "%.0f", minAmount))
        }
        if let maxAmount = filter.wrappedValue.maxAmount {
            self._maxAmountText = State(initialValue: String(format: "%.0f", maxAmount))
        }
        if let minTemp = filter.wrappedValue.minTemperature {
            self._minTemperatureText = State(initialValue: String(format: "%.1f", minTemp))
        }
        if let maxTemp = filter.wrappedValue.maxTemperature {
            self._maxTemperatureText = State(initialValue: String(format: "%.1f", maxTemp))
        }
        if let minPain = filter.wrappedValue.minPainLevel {
            self._minPainLevelText = State(initialValue: String(minPain))
        }
        if let maxPain = filter.wrappedValue.maxPainLevel {
            self._maxPainLevelText = State(initialValue: String(maxPain))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Patient Filter - Only show for non-Patient users
                if TokenManager.shared.loadCurrentUser()?.role != "Patient" {
                    Section(header: Text("Patient")) {
                        Button(action: {
                            showPatientDropdown.toggle()
                            if showPatientDropdown && patientViewModel.patients.isEmpty {
                                Task {
                                    await patientViewModel.fetchPatients()
                                }
                            }
                        }) {
                            HStack {
                                if let patientId = tempFilter.patientId,
                                   let selectedPatient = patientViewModel.patients.first(where: { $0.userSlug == patientId }) {
                                    Text(selectedPatient.firstName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Patient")
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: showPatientDropdown ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showPatientDropdown {
                            if patientViewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading patients...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading)
                            } else {
                                ForEach(patientViewModel.patients) { patient in
                                    HStack {
                                        Button(action: {
                                            if tempFilter.patientId == patient.userSlug {
                                                tempFilter.patientId = nil
                                            } else {
                                                tempFilter.patientId = patient.userSlug
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: tempFilter.patientId == patient.userSlug ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(tempFilter.patientId == patient.userSlug ? .accentColor : .gray)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(patient.firstName)
                                                        .foregroundColor(.primary)
                                                    Text(patient.email ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        Spacer()
                                    }
                                    .padding(.leading)
                                    .task {
                                        await patientViewModel.loadMoreIfNeeded(currentPatient: patient)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Amount Range
                Section(header: Text("Fluid Amount (ml)")) {
                    HStack {
                        TextField("Min", text: $minAmountText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        TextField("Max", text: $maxAmountText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Temperature Range
                Section(header: Text("Temperature (°F)")) {
                    HStack {
                        TextField("Min", text: $minTemperatureText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        TextField("Max", text: $maxTemperatureText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Pain Level Range
                Section(header: Text("Pain Level (0-10)")) {
                    HStack {
                        TextField("Min", text: $minPainLevelText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("-")
                            .foregroundColor(.secondary)
                        
                        TextField("Max", text: $maxPainLevelText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                
//                // Date Range cuurently not use in after later i will use this
//                Section(header: Text("Date Range")) {
//                    DatePicker("From", selection: Binding(
//                        get: { tempFilter.minRecordedAt ?? Date() },
//                        set: { tempFilter.minRecordedAt = $0 }
//                    ), displayedComponents: [.date])
//                    
//                    DatePicker("To", selection: Binding(
//                        get: { tempFilter.maxRecordedAt ?? Date() },
//                        set: { tempFilter.maxRecordedAt = $0 }
//                    ), displayedComponents: [.date])
//                }
                
                // Multi-select Filters with Dropdowns
                
                Section(header: Text("Color")) {
                    Button(action: {
                        showColorDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.color.isEmpty ? "Select Colors" : "\(tempFilter.color.count) selected")
                                .foregroundColor(tempFilter.color.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showColorDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showColorDropdown {
                        ForEach(DrainageEntry.colorOptions.filter { $0 != "Other" }, id: \.self) { color in
                            HStack {
                                Button(action: {
                                    if tempFilter.color.contains(color) {
                                        tempFilter.color.removeAll { $0 == color }
                                    } else {
                                        tempFilter.color.append(color)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.color.contains(color) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.color.contains(color) ? .accentColor : .gray)
                                        Text(color)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                
                Section(header: Text("Odor")) {
                    Button(action: {
                        showOdorDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.odor.isEmpty ? "Select Odors" : "\(tempFilter.odor.count) selected")
                                .foregroundColor(tempFilter.odor.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showOdorDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showOdorDropdown {
                        ForEach(DrainageEntry.odorOptions.filter { $0 != "Other" }, id: \.self) { odor in
                            HStack {
                                Button(action: {
                                    if tempFilter.odor.contains(odor) {
                                        tempFilter.odor.removeAll { $0 == odor }
                                    } else {
                                        tempFilter.odor.append(odor)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.odor.contains(odor) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.odor.contains(odor) ? .accentColor : .gray)
                                        Text(odor)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                Section(header: Text("Fluid Type")) {
                    Button(action: {
                        showFluidTypeDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.fluidType.isEmpty ? "Select Fluid Types" : "\(tempFilter.fluidType.count) selected")
                                .foregroundColor(tempFilter.fluidType.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showFluidTypeDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showFluidTypeDropdown {
                        ForEach(DrainageEntry.fluidTypes.filter { $0 != "Other" }, id: \.self) { type in
                            HStack {
                                Button(action: {
                                    if tempFilter.fluidType.contains(type) {
                                        tempFilter.fluidType.removeAll { $0 == type }
                                    } else {
                                        tempFilter.fluidType.append(type)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.fluidType.contains(type) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.fluidType.contains(type) ? .accentColor : .gray)
                                        Text(type)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
            
                
                Section(header: Text("Drainage Type")) {
                    Button(action: {
                        showDrainageTypeDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.drainageType.isEmpty ? "Select Drainage Types" : "\(tempFilter.drainageType.count) selected")
                                .foregroundColor(tempFilter.drainageType.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showDrainageTypeDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showDrainageTypeDropdown {
                        ForEach(DrainageEntry.drainageTypeOptions.filter { $0 != "Other" }, id: \.self) { type in
                            HStack {
                                Button(action: {
                                    if tempFilter.drainageType.contains(type) {
                                        tempFilter.drainageType.removeAll { $0 == type }
                                    } else {
                                        tempFilter.drainageType.append(type)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.drainageType.contains(type) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.drainageType.contains(type) ? .accentColor : .gray)
                                        Text(type)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                Section(header: Text("Consistency")) {
                    Button(action: {
                        showConsistencyDropdown.toggle()
                    }) {
                        HStack {
                            Text(tempFilter.consistency.isEmpty ? "Select Consistencies" : "\(tempFilter.consistency.count) selected")
                                .foregroundColor(tempFilter.consistency.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: showConsistencyDropdown ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showConsistencyDropdown {
                        ForEach(DrainageEntry.consistencyOptions.filter { $0 != "Other" }, id: \.self) { consistency in
                            HStack {
                                Button(action: {
                                    if tempFilter.consistency.contains(consistency) {
                                        tempFilter.consistency.removeAll { $0 == consistency }
                                    } else {
                                        tempFilter.consistency.append(consistency)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: tempFilter.consistency.contains(consistency) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(tempFilter.consistency.contains(consistency) ? .accentColor : .gray)
                                        Text(consistency)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }
                            .padding(.leading)
                        }
                    }
                }
                
            }
            .navigationTitle("Filter Drainage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        tempFilter.clearAll()
                        minAmountText = ""
                        maxAmountText = ""
                        minTemperatureText = ""
                        maxTemperatureText = ""
                        minPainLevelText = ""
                        maxPainLevelText = ""
                        applyFilters()
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        onApply()
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    private func applyFilters() {
        // Apply text field values to tempFilter
        if !minAmountText.isEmpty, let value = Double(minAmountText) {
            tempFilter.minAmount = value
        } else {
            tempFilter.minAmount = nil
        }
        
        if !maxAmountText.isEmpty, let value = Double(maxAmountText) {
            tempFilter.maxAmount = value
        } else {
            tempFilter.maxAmount = nil
        }
        
        if !minTemperatureText.isEmpty, let value = Double(minTemperatureText) {
            tempFilter.minTemperature = value
        } else {
            tempFilter.minTemperature = nil
        }
        
        if !maxTemperatureText.isEmpty, let value = Double(maxTemperatureText) {
            tempFilter.maxTemperature = value
        } else {
            tempFilter.maxTemperature = nil
        }
        
        if !minPainLevelText.isEmpty, let value = Int(minPainLevelText) {
            tempFilter.minPainLevel = max(0, min(10, value))
        } else {
            tempFilter.minPainLevel = nil
        }
        
        if !maxPainLevelText.isEmpty, let value = Int(maxPainLevelText) {
            tempFilter.maxPainLevel = max(0, min(10, value))
        } else {
            tempFilter.maxPainLevel = nil
        }
        
        // Update the actual filter
        filter = tempFilter
    }
}

// MARK: - Sort Option Row Component
struct SortOptionRow: View {
    let option: DrainageSortOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option.rawValue)
                    .foregroundColor(.dynamicAccent)
                    .padding(.vertical, 14)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.dynamicAccent)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal)
            .background(isSelected ? Color.dynamicAccent.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
        Divider()
    }
}

#Preview {
    DrainageListView()
        .environmentObject(DrainageStore())
}
