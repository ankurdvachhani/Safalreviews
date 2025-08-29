import SwiftUI
import Combine

final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated: Bool = false
    @Published var currentTheme: Theme = .system
    @Published var selectedTab: Tab = .Drainage
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        loadPersistedState()
        checkAuthenticationStatus()
    }
    
    // MARK: - Public Methods
    func signOut() {
        TokenManager.shared.deleteToken()
        isAuthenticated = false
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Add any state observation or Combine subscriptions here
        $currentTheme
            .dropFirst()
            .sink { [weak self] theme in
                self?.persistTheme(theme)
            }
            .store(in: &cancellables)
    }
    
    private func loadPersistedState() {
        // Load any persisted state here
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = Theme(rawValue: savedTheme) {
            currentTheme = theme
        }
    }
    
    private func checkAuthenticationStatus() {
        if TokenManager.shared.getToken() != nil {
            isAuthenticated = true
        }
    }
    
    private func persistTheme(_ theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
    }
}

// MARK: - Enums
extension AppState {
    enum Theme: String {
        case light
        case dark
        case system
    }
    
    enum Tab: String, Hashable {
        case Drainage
        case PatientList
        case dashboard
        case settings
        case IncidentList
        
        var title: String {
            switch self {
            case .PatientList: return "Patients"
            case .Drainage: return "Drainage"
            case .dashboard: return "Dashboard"
            case .IncidentList: return "IncidentList"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .Drainage: return "syringe"
            case .PatientList: return "person"
            case .dashboard: return "house"
            case .IncidentList:return "note.text.badge.plus"
            case .settings: return "gear"
            }
        }
    }
} 
