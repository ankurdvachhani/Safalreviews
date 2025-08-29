import Foundation

struct LoginCredentials {
    var email: String
    var password: String
    var isOrganization: Bool
    var rememberMe: Bool
}

struct AuthenticationError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

enum AuthenticationState: Equatable {
    case authenticated
    case unauthenticated
    case error(Error)
    
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.authenticated, .authenticated):
            return true
        case (.unauthenticated, .unauthenticated):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
} 