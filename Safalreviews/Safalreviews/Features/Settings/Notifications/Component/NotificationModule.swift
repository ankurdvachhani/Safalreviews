//
//  NotificationModule.swift
//  SafalCalendar
//
//  Created by Apple on 27/06/25.
//

import Foundation
import SwiftUICore

enum NotificationModule: String, CaseIterable {
    case general = "general"
    
    var displayTitle: String {
        switch self {
        case .general:
            return "General"
        }
    }
    
    var priorityLabel: String? {
        switch self {
        case .general:
            return nil
        }
    }
    
    var priorityColor: Color {
        switch self {
        case .general:
            return .clear
        }
    }
    
    var icon: String {
        switch self {
        case .general:
            return "bell"
        }
    }
    
    var subtitle: String {
        switch self {
        case .general:
            return "Receive general notifications about updates and important information."
        }
    }
}

enum ReportModule: String, CaseIterable {
    case changeLog = "Change Log"
   

    
    var icon: String {
        switch self {
        case .changeLog:
            return "text.document"
        }
    }
    
    var subtitle: String {
        switch self {
        case .changeLog:
            return "View all changes made to the app."
        }
    }
}

