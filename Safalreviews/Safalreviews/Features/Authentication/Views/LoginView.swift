import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @State private var showForgotPassword = false
    @State private var show2FAVerification = false
    @State private var selected2FAMethod: String = ""
    @State private var showOTPView = false
    @State private var otp = ""
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    logoSection
                    
                    // Form
                    formSection
                    
                    // Action buttons
                    actionButtons
                    
                    // Additional options
                    additionalOptions
                    
                }
                .padding(.horizontal, 24)
            }
            .disabled(viewModel.isLoading)
            
//            if viewModel.isLoading {
//                progressView()
//            }
        }
        .withGradientBackground()
        .toast(message: $viewModel.errorMessage)
        .toast(message: $viewModel.successMessage, type: .success)
        .onChange(of: viewModel.authenticationState) { newState in
            if case .authenticated = newState {
                withAnimation {
                    appState.isAuthenticated = true
                    Task {
                     //   await themeManager.fetchColors()
                    }
                }
            }
        }
        .onChange(of: viewModel.requires2FA) { requires2FA in
            if requires2FA {
                show2FAVerification = true
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            NavigationView {
                ForgotPasswordView()
            }
        }
        .sheet(isPresented: $show2FAVerification) {
            TwoFactorAuthSelectionView(
                viewModel: viewModel,
                isPresented: $show2FAVerification,
                selectedMethod: $selected2FAMethod,
                showOTPView: $showOTPView
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showOTPView) {
            TwoFactorOTPView(
                viewModel: viewModel,
                selectedMethod: selected2FAMethod,
                isPresented: $showOTPView,
                otp: $otp
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 8) {
            Image("Manual")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("Sign In")
                .font(.title)
                .fontWeight(.bold)
        }
        .padding(.top, 60)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            CustomTextField(
                title: "Email*",
                placeholder: "Enter your email",
                text: $viewModel.email,
                error: viewModel.emailError
            )
            
            CustomTextField(
                title: "Password*",
                placeholder: "Enter your password",
                text: $viewModel.password,
                error: viewModel.passwordError,
                isSecure: true,
                showSecureText: $viewModel.showPassword
            )
            
            // Checkboxes
            VStack(spacing: 12) {
                
                Toggle("Remember me", isOn: $viewModel.rememberMe)
                    .font(.subheadline)
                    .tint(Color.dynamicAccent)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation {
                    viewModel.login()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.dynamicAccent)
                        .cornerRadius(12)
                } else {
                    Text("SIGN IN")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color.dynamicAccent)
                        .cornerRadius(12)
                }
            }
            .disabled(viewModel.isLoading)
            
            Button("Forgot Password?") {
                NavigationManager.shared.navigate(
                    to: .forgotPassword,
                    style: .presentSheet()
                )
            }
            .foregroundColor(Color.dynamicAccent)
        }
    }
    
    private var additionalOptions: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                
                Button("Sign Up") {
                    NavigationManager.shared.navigate(
                        to: .signUp,
                        style: .presentFullScreen()
                    )
                    
                }
                .foregroundColor(Color.dynamicAccent)
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Two-Factor Authentication Selection View
struct TwoFactorAuthSelectionView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Binding var isPresented: Bool
    @Binding var selectedMethod: String
    @Binding var showOTPView: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            // Header
            VStack(spacing: 12) {
                Text("Two-Factor Authentication")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Please select a verification method to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)
            
            // Verification options
            VStack(spacing: 16) {
                // Email Option
                if let email = viewModel.twoFactorEmail, !email.isEmpty {
                    Button(action: {
                        selectedMethod = "Email"
                        Task {
                            await viewModel.send2FAVerificationCode(type: "Email", value: email)
                            if viewModel.successMessage != nil {
                                showOTPView = true
                                isPresented = false
                            }
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                                .foregroundColor(.dynamicAccent)
                                .frame(width: 32, height: 32)
                                .background(Color.dynamicAccent.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Phone Option
                if let phone = viewModel.twoFactorPhone, !phone.isEmpty {
                    Button(action: {
                        selectedMethod = "PhoneNumber"
                        Task {
                            await viewModel.send2FAVerificationCode(type: "PhoneNumber", value: phone)
                            if viewModel.successMessage != nil {
                                showOTPView = true
                                isPresented = false
                            }
                        }
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: "phone.fill")
                                .font(.title2)
                                .foregroundColor(.dynamicAccent)
                                .frame(width: 32, height: 32)
                                .background(Color.dynamicAccent.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Phone")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(phone)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer(minLength: 20)
            
            // Cancel button
            Button("Cancel") {
                isPresented = false
            }
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.bottom, 34)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Two-Factor OTP View
struct TwoFactorOTPView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    let selectedMethod: String
    @Binding var isPresented: Bool
    @Binding var otp: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 20)
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: selectedMethod == "Email" ? "envelope.fill" : "phone.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.dynamicAccent)
                    .frame(width: 60, height: 60)
                    .background(Color.dynamicAccent.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(spacing: 8) {
                    Text("Verify \(selectedMethod == "Email" ? "Email" : "Phone")")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("We've sent a 6-digit verification code to your \(selectedMethod.lowercased())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 32)
            
            // OTP Input
            VStack(spacing: 16) {
                TextField("Enter 6-digit code", text: $otp)
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .onChange(of: otp) { newValue in
                        let numericOnly = newValue.filter { $0.isNumber }
                        if numericOnly.count > 6 {
                            otp = String(numericOnly.prefix(6))
                        } else {
                            otp = numericOnly
                        }
                    }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.verify2FAOTP(otp: otp, type: selectedMethod)
                            if viewModel.authenticationState == .authenticated {
                                isPresented = false
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Verify")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dynamicAccent)
                        .cornerRadius(16)
                    }
                    .disabled(otp.count != 6 || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        Task {
                            if selectedMethod == "Email", let email = viewModel.twoFactorEmail {
                                await viewModel.send2FAVerificationCode(type: "Email", value: email)
                            } else if selectedMethod == "PhoneNumber", let phone = viewModel.twoFactorPhone {
                                await viewModel.send2FAVerificationCode(type: "PhoneNumber", value: phone)
                            }
                        }
                    }) {
                        Text("Resend Code")
                            .font(.subheadline)
                            .foregroundColor(.dynamicAccent)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            
            Spacer(minLength: 20)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
        .withNavigation()
} 
