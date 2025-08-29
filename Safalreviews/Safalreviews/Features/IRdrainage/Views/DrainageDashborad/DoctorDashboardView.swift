import SwiftUI
import Charts

struct DoctorDashboardView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: DashboardViewModel
    @StateObject private var configService = ConfigurationService.shared
    @State private var selectedTimeRange: DashboardViewModel.TimeRange = .week
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Filter Section
                filterSection
                
                // Stats Cards
                statsSection
                
                // Missed Drainages Section
                if let missedDrainages = viewModel.doctorDashboardData?.missedDrainages, !missedDrainages.isEmpty {
                    missedDrainagesSection
                }
                
                // Critical Alerts
                if !NotificationsViewModel.shared.getNotifications(for: "drainageTriggerHigh", isSeen: false).isEmpty {
                    criticalAlertsSection
                }
                
                // Quick Actions
                quickActionsSection
                
                // Active Incidents Section
                activeIncidentsSection
                
                // Weekly Drainage Chart Section
                weeklyDrainageChartSection
                
                // Patient Summary
             //   patientSummarySection
                
                // Drainage Type Pie Chart
                drainageTypePieChartSection
                
                // Patient-wise Drainage Bar Chart
                patientDrainageBarChartSection
                
                // Drainage Trends Chart
              //  drainageTrendsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                // Duration Segmented Picker
                VStack(alignment: .leading, spacing: 8) {
                    Label("Duration", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Picker("Duration", selection: $viewModel.selectedDuration) {
                        ForEach(DashboardDuration.allCases, id: \.self) { duration in
                            Text(duration.displayName).tag(duration)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: viewModel.selectedDuration) { _ in
                        Task {
                            await viewModel.loadDashboardData()
                        }
                    }
                }

                Divider()

                // Drainage Type Filter
                VStack(alignment: .leading, spacing: 8) {
                    Label("Drainage Type", systemImage: "drop.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Menu {
                        Button {
                            viewModel.selectedDrainageType = ""
                            Task { await viewModel.loadDashboardData() }
                        } label: {
                            Label("All Types", systemImage: viewModel.selectedDrainageType.isEmpty ? "checkmark" : "")
                        }

                        ForEach(DrainageEntry.drainageTypeOptions, id: \.self) { type in
                            Button {
                                viewModel.selectedDrainageType = type
                                Task { await viewModel.loadDashboardData() }
                            } label: {
                                Label(type, systemImage: viewModel.selectedDrainageType == type ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedDrainageType.isEmpty ? "All Types" : viewModel.selectedDrainageType)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2))
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Patients",
                value: "\(viewModel.doctorDashboardData?.stats.totalPatients ?? 0)",
                icon: "person.3.fill",
                color: .blue
            )
            .onTapGesture {
                NavigationManager.shared.navigate(to: .patientList)
            }
            
            StatCard(
                title: "Active Incidents",
                value: "\(viewModel.doctorDashboardData?.stats.activeIncidents ?? 0)",
                icon: "note.text.badge.plus",
                color: .orange
            )
            .onTapGesture {
                appState.selectedTab = .IncidentList
                // Set pending filter flag
                IncidentFilterManager.pendingActiveFilter = true
            }
            
            
            StatCard(
                title: "Total Drainage Count",
                value: "\(viewModel.doctorDashboardData?.stats.totalDrainageCount ?? 0)",
                icon: "list.clipboard.fill",
                color: .green
            )
            
            StatCard(
                title: "Total Drainage Amount",
                value: String(format: "%.0f ml", Double(viewModel.doctorDashboardData?.stats.totalDrainageAmount ?? 0)),
                icon: "drop.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Critical Alerts Section
    private var criticalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Drainages Alerts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let notifications = NotificationsViewModel.shared.getNotifications(for: "drainageTriggerHigh", isSeen: false)
                if !notifications.isEmpty {
                    Text("\(notifications.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            let notifications = NotificationsViewModel.shared.getNotifications(for: "drainageTriggerHigh", isSeen: false)
            if !notifications.isEmpty {
                ForEach(notifications.prefix(3)) { notification in
                    NotificationAlertRow(notification: notification)
                }
                
                if notifications.count > 3 {
                    Button("View All Alerts (\(notifications.count))") {
                        NavigationManager.shared.navigate(to: .notificationview)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No critical alerts")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            Task {
                await NotificationsViewModel.shared.fetchNotificationsByModule("drainageTriggerHigh", isSeen: false)
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.doctorDashboardData?.quickActions ?? []) { action in
                    QuickActionCard(action: action) {
                        handleQuickAction(action.action)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Active Incidents Section
    private var activeIncidentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Incidents")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let activeIncidents = viewModel.doctorDashboardData?.activeIncidents, !activeIncidents.isEmpty {
                    Text("\(activeIncidents.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            if let activeIncidents = viewModel.doctorDashboardData?.activeIncidents, !activeIncidents.isEmpty {
                ForEach(activeIncidents.prefix(3)) { incident in
                    ActiveIncidentRow(incident: incident)
                }
                
                if activeIncidents.count > 3 {
                    Button("View All Active (\(activeIncidents.count))") {
                        appState.selectedTab = .IncidentList
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No active incidents")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Weekly Drainage Chart Section
    private var weeklyDrainageChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Drainage Trends")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                Picker("Duration", selection: $viewModel.selectedLineChartDuration) {
                    ForEach(LineChartDashboardDuration.allCases, id: \.self) { duration in
                        Text(duration.displayName)
                            .foregroundColor(.black)
                            .tag(duration)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1) // border line
                )
                .onChange(of: viewModel.selectedLineChartDuration) { _ in
                    Task {
                        await viewModel.loadWeeklyDrainageData()
                    }
                }
            }
            
            if let weeklyData = viewModel.doctorDashboardData?.weeklyDrainageData, !weeklyData.isEmpty {
                WeeklyDrainageChart(data: weeklyData)
                    .frame(height: 200)
            } else {
                Text("No weekly drainage data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Patient Summary Section
    private var patientSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patient Overview")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to patient list
                    NavigationManager.shared.navigate(to: .patientList)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let patients = viewModel.doctorDashboardData?.patientSummaries, !patients.isEmpty {
                ForEach(patients.prefix(3)) { patient in
                    PatientSummaryRow(patient: patient)
                }
            } else {
                Text("No patients assigned")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Missed Drainages Section
    private var missedDrainagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Missed Drainages")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let missedDrainages = viewModel.doctorDashboardData?.missedDrainages, !missedDrainages.isEmpty {
                    Text("\(missedDrainages.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
            }
            
            if let missedDrainages = viewModel.doctorDashboardData?.missedDrainages, !missedDrainages.isEmpty {
                ForEach(missedDrainages.prefix(3)) { missed in
                    MissedDrainageRow(missed: missed)
                }
                
                if missedDrainages.count > 3 {
                    Button("View All Missed (\(missedDrainages.count))") {
                        // Navigate to missed drainages list
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("No missed drainages")
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Drainage Type Pie Chart Section
    private var drainageTypePieChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drainage Types Distribution")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let drainageTypeStats = viewModel.doctorDashboardData?.drainageTypeStats, !drainageTypeStats.isEmpty {
                DrainageTypePieChart(stats: drainageTypeStats)
                    .frame(height: 400)
            } else {
                Text("No drainage type data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Patient Drainage Bar Chart Section
    private var patientDrainageBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patient-wise Drainage Amount")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let patientStats = viewModel.doctorDashboardData?.patientDrainageStats, !patientStats.isEmpty {
                PatientDrainageBarChart(stats: patientStats)
                    .frame(height: 200)
            } else {
                Text("No patient drainage data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Drainage Trends Section
    private var drainageTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Drainage Trends")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(DashboardViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if let trends = viewModel.doctorDashboardData?.drainageTrends, !trends.isEmpty {
                DrainageTrendsChart(trends: trends)
                    .frame(height: 200)
            } else {
                Text("No trend data available")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func handleQuickAction(_ action: QuickAction.QuickActionType) {
        switch action {
        case .addEntry:
            if configService.isIncidentEnabled {
                NavigationManager.shared.navigate(
                    to: .addDrainage(),
                    style: .presentSheet()
                )
            }
        case .patientList:
            NavigationManager.shared.navigate(to: .patientList)
        case .criticalAlerts:
            NavigationManager.shared.navigate(to: .notificationview)
            break
        case .reports:
            NavigationManager.shared.navigate(to: .incidentReportList)
        case .settings:
            appState.selectedTab = .settings
        case .notifications:
            NavigationManager.shared.navigate(to: .notificationview)
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CriticalAlertRow: View {
    let alert: CriticalAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.alertType.icon)
                .foregroundColor(alert.alertType.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.patientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(alert.severity.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(alert.severity.color)
                    .clipShape(Capsule())
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NotificationAlertRow: View {
    let notification: NotificationItem
    
    private func formatNotificationDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        return "N/A"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("High")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                
                Text(formatNotificationDate(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct QuickActionCard: View {
    let action: QuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(action.color)
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveIncidentRow: View {
    let incident: IncidentStatsItem
    
    var body: some View {
        Button(action: {
            NavigationManager.shared.navigate(to: .incidentDetailById(incidentId: incident.id))
        }) {
            HStack(spacing: 12) {
                Image(systemName: "note.text.badge.plus")
                    .foregroundColor(.orange)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(incident.patientName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("ID: \(incident.incidentId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(incident.status)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(incident.totalDrainageCount) drainages")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(incident.totalAmountCount) ml")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PatientSummaryRow: View {
    let patient: PatientSummary
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.patientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(patient.totalEntries) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: patient.status.icon)
                        .foregroundColor(patient.status.color)
                        .font(.caption)
                    
                    Text(patient.status.rawValue)
                        .font(.caption)
                        .foregroundColor(patient.status.color)
                }
                
                Text(String(format: "%.1f ml avg", patient.averageVolume))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MissedDrainageRow: View {
    let missed: MissedDrainageItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundColor(.red)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(missed.patientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(missed.incidentName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Incident ID: \(missed.incidentId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(missed.drainageType)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Highlight the scheduled time
                Text(missed.formattedScheduleTime)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DrainageTypePieChart: View {
    let stats: [DrainageTypeStats]
    
    // Define colors for each drainage type
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .pink, .indigo]
    
    private func colorForIndex(_ index: Int) -> Color {
        colors[index % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Pie Chart
            Chart(stats) { stat in
                SectorMark(
                    angle: .value("Amount", stat.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2.0
                )
                .foregroundStyle(colorForIndex(stats.firstIndex(of: stat) ?? 0))
            }
            .chartLegend(.hidden)
            .frame(height: 150)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        VStack {
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(stats.reduce(0) { $0 + $1.amount }) ml")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            
            // Scrollable legend with matching colors
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(colorForIndex(index))
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.drainageType)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(stat.count) entries")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stat.amount) ml")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text("\(Int((Double(stat.amount) / Double(stats.reduce(0) { $0 + $1.amount })) * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxHeight: 200)
        }
    }
}

struct PatientDrainageBarChart: View {
    let stats: [PatientDrainageStats]
    
    var body: some View {
        Chart(stats) { stat in
            BarMark(
                x: .value("Amount", stat.amount),
                y: .value("Patient", stat.patientName)
            )
            .foregroundStyle(by: .value("Patient", stat.patientName))
            .annotation(position: .trailing) {
                Text("\(stat.amount) ml")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
            }
        }
    }
}

struct DrainageTrendsChart: View {
    let trends: [DrainageTrend]
    
    var body: some View {
        Chart(trends) { trend in
            LineMark(
                x: .value("Date", trend.date),
                y: .value("Volume", trend.totalVolume)
            )
            .foregroundStyle(.blue)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Date", trend.date),
                y: .value("Volume", trend.totalVolume)
            )
            .foregroundStyle(.blue.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

struct WeeklyDrainageChart: View {
    let data: [WeeklyDrainageItem]
    
    var body: some View {
        VStack(spacing: 12) {
            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                    Text("Amount (ml)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
//                HStack(spacing: 4) {
//                    Circle()
//                        .fill(.green)
//                        .frame(width: 8, height: 8)
//                    Text("Count")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Combined Chart
            Chart(data) { item in
                // Drainage Amount Line
                LineMark(
                    x: .value("Day", shortDayName(item.dayName)),
                    y: .value("Amount", item.drainageAmount)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                PointMark(
                    x: .value("Day", shortDayName(item.dayName)),
                    y: .value("Amount", item.drainageAmount)
                )
                .foregroundStyle(.blue)
                .annotation(position: .automatic) {
                    Text("\(item.drainageAmount)")
                        .font(.caption2)
                        .foregroundColor(.black)
                }
                
//                // Drainage Count Line
//                LineMark(
//                    x: .value("Day", shortDayName(item.dayName)),
//                    y: .value("Count", item.drainageCount)
//                )
//                .foregroundStyle(.green)
//                .lineStyle(StrokeStyle(lineWidth: 2))
//                
//                PointMark(
//                    x: .value("Day", shortDayName(item.dayName)),
//                    y: .value("Count", item.drainageCount)
//                )
//                .foregroundStyle(.green)
//                .annotation(position: .bottom) {
//                    Text("\(item.drainageCount)")
//                        .font(.caption2)
//                        .foregroundColor(.green)
//                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
    }
    
    private func shortDayName(_ fullName: String) -> String {
        switch fullName.lowercased() {
        case "sunday": return "SUN"
        case "monday": return "MON"
        case "tuesday": return "TUE"
        case "wednesday": return "WED"
        case "thursday": return "THU"
        case "friday": return "FRI"
        case "saturday": return "SAT"
        default: return fullName.prefix(3).uppercased()
        }
    }
}

// MARK: - Preview
struct DoctorDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorDashboardView(
            viewModel: DashboardViewModel()
        )
    }
} 
