//
//  ReportView.swift
//  SafalCalendar
//
//  Created by Apple on 02/07/25.
//

import SwiftUI

struct ReportView: View {
    @State private var selectedModule: ReportModule = .IncidentReport

    var body: some View {
        List {
            ForEach(filteredModules, id: \.self) { module in
                NavigationLink(destination: destinationView(for: module)) {
                    HStack {
                        Image(systemName: module.icon)
                            .foregroundColor(.dynamicAccent)
                            .frame(width: 30)

                        VStack(alignment: .leading) {
                            Text(module.rawValue)
                                .font(.headline)
                            
                                Text(module.subtitle)
                                .font(.caption)
                                .fontWeight(.light)
                                .foregroundColor(.secondary)
                            
                        }

                        Spacer()

                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            Task {
             //
            }
        }
        .listStyle(.plain)
        .navigationTitle("Reports")
    }
    
    /// Filtered modules based on user role
    private var filteredModules: [ReportModule] {
        let currentUser = TokenManager.shared.loadCurrentUser()
        
        // If user is not a Patient, show all modules
        if currentUser?.role != "Patient" {
            return ReportModule.allCases
        } else {
            // If user is a Patient, hide IncidentReport
            return ReportModule.allCases.filter { $0 != .IncidentReport }
        }
    }
    
    @ViewBuilder
    private func destinationView(for module: ReportModule) -> some View {
        switch module {
        case .changeLog:
            ReportsListView()
        case .IncidentReport:
            IncidentReportListView()
        }
    }
}

#Preview {
    ReportView()
}
