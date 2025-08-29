import Foundation
import Combine

final class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var isOrganization = false
    @Published var rememberMe = false
    @Published var isLoading = false
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var showPassword = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // MARK: - 2FA Properties
    @Published var requires2FA = false
    @Published var twoFactorEmail: String?
    @Published var twoFactorPhone: String?
    @Published var twoFactorVerifyId: String?
    
    // MARK: - Validation Properties
    @Published var emailError: String?
    @Published var passwordError: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let networkManager: NetworkManager
    private let tokenManager = TokenManager.shared
    
    // MARK: - Initialization
    init(networkManager: NetworkManager = NetworkManager()) {
        self.networkManager = networkManager
        setupValidation()
        setupErrorHandling()
        loadSavedCredentials()
    }
    
    // MARK: - Public Methods
    func login() {
        guard validateInputs() else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let user: UserModel
                if isOrganization {
                    user = try await networkManager.signInOrganization(email: email, password: password)
                } else {
                    user = try await networkManager.signIn(email: email, password: password)
                }
                
                await MainActor.run {
                    self.isLoading = false
                    
                    if user.role == "Organization" || user.status == "Closed"{
                        self.authenticationState = .unauthenticated
                        tokenManager.clearUserData()
                        errorMessage = "This account currenty not supported"
                    } else {
                     
                        // Check if 2FA is required
                        if let auth2faEmail = user.auth2faEmail, !auth2faEmail.isEmpty,
                           let auth2faPhoneNumber = user.auth2faPhoneNumber, !auth2faPhoneNumber.isEmpty {
                            // Both email and phone are configured
                            self.twoFactorEmail = auth2faEmail
                            self.twoFactorPhone = auth2faPhoneNumber
                            self.requires2FA = true
                            print("2FA required - both email and phone configured")
                        } else if let auth2faEmail = user.auth2faEmail, !auth2faEmail.isEmpty {
                            // Only email is configured
                            self.twoFactorEmail = auth2faEmail
                            self.requires2FA = true
                            print("2FA required - email only configured")
                        } else if let auth2faPhoneNumber = user.auth2faPhoneNumber, !auth2faPhoneNumber.isEmpty {
                            // Only phone is configured
                            self.twoFactorPhone = auth2faPhoneNumber
                            self.requires2FA = true
                            print("2FA required - phone only configured")
                        } else {
                            // No 2FA required, proceed with normal login
                            self.completeLogin(user: user)
                        }
                    }
                }
            } catch let error as NetworkError {
                await handleNetworkError(error)
            } catch {
                await handleNetworkError(.unknown(error))
            }
        }
    }
    
    func registerFCMToken() {
        Task {
            if let token = UserDefaults.standard.string(forKey: "fcmToken") {
                do {
                    let networkManager: NetworkManager = DIContainer.shared.resolve()
                    let response = try await networkManager.registerFCMToken(token)
                    if response.success {
                        Logger.debug("Successfully Register FCM token")
                    }
                } catch {
                    Logger.error("Failed to delete FCM token: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 2FA Methods
    func send2FAVerificationCode(type: String, value: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await networkManager.sendCodeForVerification(
                type: type,
                value: value,
                phoneNumber: "",
                isSendRequest: true
            )
            
            await MainActor.run {
                self.isLoading = false
                
                if response.success ?? false {
                    self.twoFactorVerifyId = response.verifyId
                    self.successMessage = response.message ?? "Verification code sent successfully"
                    print("2FA verification code sent, verifyId: \(response.verifyId ?? "")")
                } else {
                    self.errorMessage = response.message ?? "Failed to send verification code"
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to send verification code: \(error.localizedDescription)"
            }
        }
    }
    
    func verify2FAOTP(otp: String, type: String) async {
        guard let verifyId = twoFactorVerifyId else {
            await MainActor.run {
                self.errorMessage = "Verification session expired. Please try again."
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await networkManager.sendCodeForVerification(
                type: otp,
                value: verifyId,
                phoneNumber: type == "Email" ? (twoFactorEmail ?? "") : (twoFactorPhone ?? ""),
                isSendRequest: false
            )
            
            await MainActor.run {
                self.isLoading = false
                
                if response.success ?? false {
                    // OTP verified successfully, now complete login with 2FA
                    self.completeLoginWith2FA(type: type, verifyId: verifyId)
                } else {
                    self.errorMessage = response.message ?? "Invalid verification code"
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to verify code: \(error.localizedDescription)"
            }
        }
    }
    
    private func completeLoginWith2FA(type: String, verifyId: String) {
        Task {
            do {
                let loginRequest = LoginWith2FARequest(
                    email: email,
                    password: password,
                    type2fa: type,
                    type2faVerifiedId: verifyId
                )
                
                let user = try await networkManager.loginWith2FA(request: loginRequest)
                
                await MainActor.run {
                    self.completeLogin(user: user)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func completeLogin(user: UserModel) {
        registerFCMToken()
        
        // Save user's name
        if let firstName = user.firstName {
            let displayName = [firstName, user.lastName].compactMap { $0 }.joined(separator: " ")
            TokenManager.shared.saveUserName(displayName)
        }
        
        // Save user's _id for host ID
        if let userId = user.id {
            TokenManager.shared.saveUserId(userId)
            print("✅ Saved host ID: \(userId)")
        }
        
        if self.rememberMe {
            // Save credentials securely
            saveCredentials()
        }
        
        // Store user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        // Store token if available
        if let token = user.token {
            self.tokenManager.saveToken(token)
        }
        
        self.authenticationState = .authenticated
        self.requires2FA = false
        self.twoFactorEmail = nil
        self.twoFactorPhone = nil
        self.twoFactorVerifyId = nil
    }
    
    func resetValidation() {
        emailError = nil
        passwordError = nil
    }
    
    private func saveCredentials() {
        // Save email and remember me state
        UserDefaults.standard.set(email, forKey: "saved_email")
        UserDefaults.standard.set(true, forKey: "remember_me")
    }
    
    private func loadSavedCredentials() {
        if UserDefaults.standard.bool(forKey: "remember_me") {
            email = UserDefaults.standard.string(forKey: "saved_email") ?? ""
            rememberMe = true
        }
    }
    
    func signOut() {
        // Clear authentication state
        authenticationState = .unauthenticated
        
        // Clear saved credentials if remember me is off
        if !rememberMe {
            UserDefaults.standard.removeObject(forKey: "saved_email")
            UserDefaults.standard.set(false, forKey: "remember_me")
        }
        
        // Delete the access token
        TokenManager.shared.deleteToken()
    }
    
    // MARK: - Private Methods
    private func validateInputs() -> Bool {
        // Reset errors
        emailError = nil
        passwordError = nil
        
        var isValid = true
        
        // Validate email
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            emailError = "Email is required"
            isValid = false
        } else if trimmedEmail != email {
            emailError = "Email cannot contain leading or trailing spaces"
            isValid = false
        } else if !isValidEmail(trimmedEmail) {
            emailError = "Please enter a valid email"
            isValid = false
        }
        
        // Validate password
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedPassword.isEmpty {
            passwordError = "Password is required"
            isValid = false
        } else if trimmedPassword != password {
            passwordError = "Password cannot contain spaces"
            isValid = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
            isValid = false
        }
        
        return isValid
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @MainActor
    private func handleNetworkError(_ error: NetworkError) {
        isLoading = false
        authenticationState = .error(error)
        errorMessage = NetworkErrorHandler.handle(error: error)
    }
    
    private func setupValidation() {
        // Email validation
        $email
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] email in
                if !email.isEmpty && !(self?.isValidEmail(email) ?? false) {
                    self?.emailError = "Please enter a valid email"
                } else {
                    self?.emailError = nil
                }
            }
            .store(in: &cancellables)
        
        // Password validation
        $password
            .dropFirst()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] password in
                if !password.isEmpty && password.count < 8 {
                    self?.passwordError = "Password must be at least 8 characters"
                } else {
                    self?.passwordError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupErrorHandling() {
        // Clear error message after 3 seconds
        $errorMessage
            .dropFirst()
            .filter { $0 != nil }
            .debounce(for: .seconds(3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
}

extension UserModel {
    var token: String? {
        // Add token property if it exists in your UserModel
        nil // Replace with actual token property
    }
} 
