import SwiftUI

/// Represents a navigation path in the app
struct NavigationPath: Identifiable, Hashable, Codable {
    let id: String
    let destination: NavigationDestination
    
    init(destination: NavigationDestination) {
        self.id = UUID().uuidString
        self.destination = destination
    }
    
    static func == (lhs: NavigationPath, rhs: NavigationPath) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Represents all possible navigation destinations in the app
enum NavigationDestination: Identifiable, Hashable, Codable {
    case profile
    case settings
    case login
    case signUp
    case forgotPassword
    case policyView(title: String, content: String, onAccept: () -> Void = {}, onReject: () -> Void = {})
    case changePassword
    case notificationview
    case notificationlistview(module: String)
    case createPost
    
    // MARK: - Identifiable Conformance
    var id: String {
        switch self {
        case .profile:
            return "profile"
        case .settings:
            return "settings"
        case .login:
            return "login"
        case .signUp:
            return "signUp"
        case .forgotPassword:
            return "forgotPassword"
        case .policyView(let title, _, _, _):
            return "policyView-\(title)"
        case .changePassword:
            return "changePassword"
        case .notificationview:
            return "Notifications"
        case .notificationlistview(let module):
            return "Notifications List-\(module)"
        case .createPost:
            return "createPost"
        }
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .profile:
            hasher.combine("profile")
        case .settings:
            hasher.combine("settings")
        case .login:
            hasher.combine("login")
        case .signUp:
            hasher.combine("signUp")
        case .forgotPassword:
            hasher.combine("forgotPassword")
        case .policyView(let title, let content, _, _):
            hasher.combine("policyView")
            hasher.combine(title)
            hasher.combine(content)
        case .changePassword:
            hasher.combine("changePassword")
        case .notificationview:
            hasher.combine("notificationview")
        case .notificationlistview(let module):
            hasher.combine("notificationlistview")
            hasher.combine(module)
        case .createPost:
            hasher.combine("createPost")
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable Conformance
    private enum CodingKeys: String, CodingKey {
        case type, id, title, content, module
    }
    
    private enum DestinationType: String, Codable {
        case  profile, settings
        case login, signUp, forgotPassword, policyView
        case changePassword
        case  notificationview, notificationlistview,createPost
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .profile:
            try container.encode(DestinationType.profile, forKey: .type)
        case .settings:
            try container.encode(DestinationType.settings, forKey: .type)
        case .login:
            try container.encode(DestinationType.login, forKey: .type)
        case .signUp:
            try container.encode(DestinationType.signUp, forKey: .type)
        case .forgotPassword:
            try container.encode(DestinationType.forgotPassword, forKey: .type)
        case .policyView(let title, let content, _, _):
            try container.encode(title, forKey: .title)
            try container.encode(content, forKey: .content)
            try container.encode(DestinationType.policyView, forKey: .type)
        case .changePassword:
            try container.encode(DestinationType.changePassword, forKey: .type)
        case .notificationview:
            try container.encode(DestinationType.notificationview, forKey: .type)
        case .notificationlistview(let module):
            try container.encode(DestinationType.notificationlistview, forKey: .type)
            try container.encode(module, forKey: .module)
        case .createPost:
            try container.encode(DestinationType.createPost, forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DestinationType.self, forKey: .type)
        
        switch type {
        case .profile:
            self = .profile
        case .settings:
            self = .settings
        case .login:
            self = .login
        case .signUp:
            self = .signUp
        case .forgotPassword:
            self = .forgotPassword
        case .policyView:
            let title = try container.decode(String.self, forKey: .title)
            let content = try container.decode(String.self, forKey: .content)
            self = .policyView(title: title, content: content)
        case .changePassword:
            self = .changePassword
        case .notificationview:
            self = .notificationview
        case .notificationlistview:
            let module = try container.decode(String.self, forKey: .module)
            self = .notificationlistview(module: module)
        case .createPost:
            self = .createPost
        }
    }
    
    @MainActor @ViewBuilder
    func view() -> some View {
        switch self {
        case .profile:
            ProfileView()
        case .settings:
            SettingsView()
        case .login:
            LoginView()
        case .signUp:
            SignUpView()
        case .forgotPassword:
            ForgotPasswordView()
        case .policyView(let title, let content, let onAccept, let onReject):
            PolicyView(title: title, content: content, onAccept: onAccept, onReject: onReject)
        case .changePassword:
            ChangePasswordView()
        case .notificationview:
            NotificationsView()
        case .notificationlistview(let module):
            NotificationsListView(module: module)
        case .createPost:
            CreatePostView()
        }
    }
}

/// Represents different types of navigation presentations
enum NavigationStyle {
    case push(withAccentColor: Color? = nil)
    case present(style: UIModalPresentationStyle = .automatic, withAccentColor: Color? = nil)
    case presentFullScreen(withAccentColor: Color? = nil)
    case presentSheet(withAccentColor: Color? = nil)
}

/// Main navigation manager class
@MainActor
final class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var paths: [NavigationDestination] = []
    @Published var presentedSheet: NavigationDestination?
    @Published var presentedFullScreen: NavigationDestination?
    private var previousAccentColor: UIColor?
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    /// Navigate to a destination
    func navigate(to destination: NavigationDestination, style: NavigationStyle = .push()) {
        let accentColor: UIColor?
        
        switch style {
        case .push(let color):
            paths.append(destination)
            accentColor = color?.uiColor
        case .present(let presentationStyle, let color):
            switch presentationStyle {
            case .pageSheet, .formSheet:
                presentedSheet = destination
            default:
                presentedFullScreen = destination
            }
            accentColor = color?.uiColor
        case .presentFullScreen(let color):
            presentedFullScreen = destination
            accentColor = color?.uiColor
        case .presentSheet(let color):
            presentedSheet = destination
            accentColor = color?.uiColor
        }
        
        if let color = accentColor {
            previousAccentColor = UIView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).tintColor
            UIView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).tintColor = color
        }
    }
    
    /// Go back one screen
    func goBack() {
        if !paths.isEmpty {
            paths.removeLast()
        }
    }
    
    /// Go back to root
    func goBackToRoot() {
        paths.removeAll()
    }
    
    /// Go back to a specific destination
    func goBackTo(_ destination: NavigationDestination) {
        if let index = paths.firstIndex(where: { $0 == destination }) {
            paths = Array(paths[0...index])
        }
    }
    
    /// Dismiss presented sheet or full-screen view
    func dismiss() {
        presentedSheet = nil
        presentedFullScreen = nil
        // Restore previous accent color
        if let previousColor = previousAccentColor {
            UIView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).tintColor = previousColor
            previousAccentColor = nil
        }
    }
    
    /// Replace entire navigation stack with new destination
    func replace(with destination: NavigationDestination) {
        paths = [destination]
    }
    
    /// Pop to previous view controller
    func popToPrevious() {
        if paths.count > 1 {
            paths.removeLast()
        }
    }
    
    /// Check if a specific destination is in the navigation stack
    func contains(_ destination: NavigationDestination) -> Bool {
        paths.contains(destination)
    }
}

// MARK: - View Extensions
extension View {
    /// Add navigation handling to a view
    func withNavigation() -> some View {
        NavigationStack(path: Binding(
            get: { NavigationManager.shared.paths },
            set: { NavigationManager.shared.paths = $0 }
        )) {
            self
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destination.view()
                }
                .sheet(item: Binding(
                    get: { NavigationManager.shared.presentedSheet },
                    set: { NavigationManager.shared.presentedSheet = $0 }
                )) { destination in
                    destination.view()
                }
                .fullScreenCover(item: Binding(
                    get: { NavigationManager.shared.presentedFullScreen },
                    set: { NavigationManager.shared.presentedFullScreen = $0 }
                )) { destination in
                    destination.view()
                }
        }
    }
    
    /// Add a custom back button
    func customBackButton() -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    NavigationManager.shared.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accent)
                }
            }
        }
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
} 
