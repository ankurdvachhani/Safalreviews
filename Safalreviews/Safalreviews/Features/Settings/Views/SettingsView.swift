import SwiftUI
import FirebaseCrashlytics

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var CMSviewModel = SignUpViewModel()
    @State private var showingLogoutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var password = ""
    @State private var isDeleting = false

    private func handleLogout() {
        Task {
            if let token = UserDefaults.standard.string(forKey: "fcmToken") {
                do {
                    let networkManager: NetworkManager = DIContainer.shared.resolve()
                    let response = try await networkManager.deleteFCMToken(token)
                    if response.success {
                        Logger.debug("Successfully deleted FCM token")
                    }
                } catch {
                    Logger.error("Failed to delete FCM token: \(error.localizedDescription)")
                }
            }
            // Remove the stored token
            UserDefaults.standard.removeObject(forKey: "fcmToken")

            // Sign out and reset tab
            NavigationManager.shared.goBackToRoot()
            appState.selectedTab = .Drainage
            appState.signOut()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                // Profile Section
                Section {
                    SettingsRow(
                        viewModel: viewModel, icon: "person.circle.fill",
                        iconColor: Color.dynamicAccent,
                        title: "Profile",
                        subtitle: "Manage your personal information"
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NavigationManager.shared.navigate(to: .profile)
                    }

                    SettingsRow(
                        viewModel: viewModel,
                        icon: "lock.fill",
                        iconColor: Color.dynamicAccent,
                        title: "Change Password",
                        subtitle: "Update your account password"
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        NavigationManager.shared.navigate(to: .changePassword)
                    }
                }

                    Section {
                        NavigationLink {
                            ReportView()
                        } label: {
                            SettingsRow(
                                viewModel: viewModel,
                                icon: "list.bullet.rectangle.portrait",
                                iconColor: Color.dynamicAccent,
                                title: "Reports",
                                subtitle: "View your reports"
                            )
                        }
                    }
                    
                // Notifications Section
                Section {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "bell.and.waves.left.and.right",
                            iconColor: Color.dynamicAccent,
                            title: "Notification Settings",
                            subtitle: "Customize your notification preferences"
                        )
                    }
                }

                // Security Section
                Section {
                    NavigationLink {
                        TwoFactorAuthenticationView()
                    } label: {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "lock.shield.fill",
                            iconColor: Color.dynamicAccent,
                            title: "Two-Factor Authentication",
                            subtitle: viewModel.isTwoFactorEnabled ? "Enabled" : "Add an extra layer of security to your account"
                        )
                    }
                }


//                // Legal & Support Section
                Section {
                    NavigationLink {
                        SettingPolicyView(
                            title: "Terms & Conditions",
                            content: CMSviewModel.termsAndConditionsContent,
                            onAccept: {},
                            onReject: {}
                        )
                    } label: {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "doc.text.fill",
                            iconColor: Color.dynamicAccent,
                            title: "Terms & Conditions",
                            subtitle: "Read our terms of service"
                        )
                    }

                    NavigationLink {
                        SettingPolicyView(
                            title: "Privacy Policy",
                            content: CMSviewModel.privacyPolicyContent,
                            onAccept: {},
                            onReject: {}
                        )
                    } label: {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "hand.raised.fill",
                            iconColor: Color.dynamicAccent,
                            title: "Privacy Policy",
                            subtitle: "Learn how we protect your data"
                        )
                    }

//                    NavigationLink {
//                        //   ContactUsView()
//                    } label: {
//                        SettingsRow(
//                            viewModel: viewModel,
//                            icon: "envelope.fill",
//                            iconColor: Color.dynamicAccent,
//                            title: "Contact Us",
//                            subtitle: "Get in touch with our support team"
//                        )
//                    }
                }

                // Account Actions Section
                Section {
                    Button(action: { showingLogoutAlert = true }) {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "rectangle.portrait.and.arrow.right",
                            iconColor: .red,
                            title: "Logout",
                            subtitle: "Sign out of your account"
                        )
                    }

                    Button(action: { showingDeleteAccountAlert = true }) {
                        SettingsRow(
                            viewModel: viewModel,
                            icon: "person.crop.circle.badge.minus",
                            iconColor: .red,
                            title: "Delete Account",
                            subtitle: "Permanently remove your account"
                        )
                    }
                }

//                // Theme Settings Section
//                Section {
//                    NavigationLink {
//                        ThemeSettingsView()
//                    } label: {
//                        Label("Theme Settings", systemImage: "paintbrush")
//                    }
//                }
            }
            .listStyle(.insetGrouped) // Optional: controls section styling
            .scrollContentBackground(.hidden) // Hide default background of the List
            // .background(Color.dynamicBackground) // Custom background
        }
        .sheet(isPresented: $showingDeleteAccountAlert) {
            PasswordAlertView(
                password: $password,
                isPresented: $showingDeleteAccountAlert,
                viewModel: viewModel,
                onDelete: {
                    Task {
                        let success = await viewModel.deleteAccount(password: password)
                        if success {
                            // Sign out and reset tab on successful deletion
                            appState.selectedTab = .Drainage
                            appState.signOut()
                        }
                    }
                }
            )
        }
        .onAppear {
            Task {
                await viewModel.fetchProfile()
            }
        }
        .background(Color(.systemGroupedBackground)) // Custom background
        .navigationTitle("Settings")
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    @ObservedObject var viewModel: ProfileViewModel
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            if title == "Profile" {
                if let profilePictureUrl = viewModel.profile.profilePictureUrl,
                   !profilePictureUrl.isEmpty {
                    AsyncImage(url: URL(string: profilePictureUrl)) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .frame(width: 35, height: 35)
                                .font(.system(size: 35, weight: .semibold))
                                .foregroundColor(iconColor)
                                .clipShape(Circle())

                        case .failure:
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(iconColor)
                                .frame(width: 32, height: 32)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(iconColor)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            } else {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PasswordAlertView: View {
    @Binding var password: String
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: ProfileViewModel
    var onDelete: () -> Void
    
    // Add validation state
    private var isPasswordValid: Bool {
        password.count >= 8
    }
    
    private var validationMessage: String {
        if let error = viewModel.errorMessage {
            return error
        }
        if password.isEmpty { return "" }
        return isPasswordValid ? "" : "Password must be at least 8 characters"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                    .padding(.top, 24)
                
                Text("Delete Account")
                    .font(.title3.bold())
                    .foregroundColor(.red)
                
                Text("Enter your password to confirm account deletion. This action is irreversible.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(password.isEmpty ? Color.clear :
                                   (isPasswordValid ? Color.green : Color.red), lineWidth: 1)
                    )
                
                if !validationMessage.isEmpty {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onDelete()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(password.isEmpty || viewModel.isLoading ? Color.red.opacity(0.5) : Color.red)
                )
                .disabled(password.isEmpty || !isPasswordValid || viewModel.isLoading)
                
                Button(action: {
                    isPresented = false
                    password = ""
                }) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.dynamicAccent)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AppState())
    }
}
