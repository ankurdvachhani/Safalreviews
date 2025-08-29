import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var qaManager: QuickActionsManager
    @StateObject private var navigationManager = NavigationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationsViewModel = NotificationsViewModel.shared
    @StateObject private var updateViewModel = UpdateAlertViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isFirstAppear = true
    @State private var shouldRefreshList = false
    
    var body: some View {
        ZStack {
            if !networkMonitor.isConnected {
                NoInternetView()
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(2)
            }
            
            ZStack {
                if appState.isAuthenticated {
                    mainView
                        .task {
                            await notificationsViewModel.fetchNotificationCount()
                           // notificationsViewModel.startPollingNotifications()
                        }
                } else {
                    LoginView()
                }
            }
            .opacity(networkMonitor.isConnected ? 1 : 0.3)
        }
        .onChange(of: qaManager.quickAction) { newValue in
            print("Quick Action changed: \(String(describing: newValue))")
            handleQAData()
        }
        .onAppear {
            // Check for stored shortcut item only on first appear
            if isFirstAppear {
                checkStoredShortcutItem()
                isFirstAppear = false
            }
        }
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        .withNavigation()
        .withThemeColors()
        .sheet(isPresented: $updateViewModel.isPresented, content: {
            UpdateAlertView(
                updateStatus: updateViewModel.updateStatus,
                version: updateViewModel.version,
                onUpdate: {
                    updateViewModel.openAppStore()
                },
                onLater: {
                    updateViewModel.isPresented = false
                }
            )
            .interactiveDismissDisabled(updateViewModel.updateStatus == .force)
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.hidden)
        })
        .task {
            await updateViewModel.checkForUpdates()
        }
    }
    
    private func checkStoredShortcutItem() {
        // Check for stored shortcut item in UserDefaults
        if let storedShortcutType = UserDefaults.standard.string(forKey: "LaunchShortcutItemType") {
            print("Found stored shortcut item: \(storedShortcutType)")
            
            // Handle the stored shortcut item
            // add delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleQuickAction(storedShortcutType)
            }
          
            
            // Clear the stored shortcut item
            UserDefaults.standard.removeObject(forKey: "LaunchShortcutItemType")
            UserDefaults.standard.removeObject(forKey: "LaunchShortcutItemUserInfo")
            UserDefaults.standard.synchronize()
        }
    }
    private func handleQuickAction(_ actionType: String) {
        print("Handling quick action: \(actionType)")
        
        // Ensure this runs on the main thread and only when authenticated
        DispatchQueue.main.async {
            guard appState.isAuthenticated else {
                print("User not authenticated, cannot handle quick action")
                return
            }
            
            switch actionType {
            case "com.yourapp.createMeeting":
                appState.selectedTab = .Drainage
            case "com.yourapp.MeetingList":
                appState.selectedTab = .Drainage
                
            case "com.yourapp.report":
                appState.selectedTab = .Drainage
                
            case "com.yourapp.createEvent":
                appState.selectedTab = .Drainage
            case "com.yourapp.eventList":
                appState.selectedTab = .Drainage
                
                
            default:
                print("Unknown quick action: \(actionType)")
                appState.selectedTab = .Drainage
            }
        }
    }
    
    private func handleQAData() {
        guard appState.isAuthenticated else { return }
        
        switch qaManager.quickAction {
        case .createMeeting:
            appState.selectedTab = .Drainage
        case .meetingList:
            appState.selectedTab = .Drainage
        case .createEvent:
            appState.selectedTab = .Drainage
        case .eventList:
            appState.selectedTab = .Drainage
        case .report:
            appState.selectedTab = .Drainage
        case nil:
            print("No quick action")
        }
        
        // Reset the quick action
        qaManager.quickAction = nil
        // Clear the stored shortcut item
        UserDefaults.standard.removeObject(forKey: "LaunchShortcutItemType")
        UserDefaults.standard.removeObject(forKey: "LaunchShortcutItemUserInfo")
        UserDefaults.standard.synchronize()
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            AppHeader()

            // Tab View
            TabView(selection: $appState.selectedTab) {
              
//                
//                DashboardView()
//                    .tag(AppState.Tab.dashboard)
//                    .tabItem {
//                        Image(systemName: "house")
//                        Text("Dashboard")
//                    }
//
//                
//                if TokenManager.shared.loadCurrentUser()?.role != "Patient" {
//                    PatientListView()
//                      .tag(AppState.Tab.PatientList)
//                      .tabItem {
//                          Image(systemName: "person")
//                          Text("Patients")
//                      }
//                }
//                
//                IRDrainageView()
//                    .tag(AppState.Tab.Drainage)
//                    .tabItem {
//                        Image(systemName: "syringe")
//                        Text("My Drainage")
//                    }
//                    .id(appState.selectedTab)
//
//             
//                IncidentListView()
//                    .tag(AppState.Tab.IncidentList)
//                    .tabItem {
//                        Image(systemName: "note.text.badge.plus")
//                        Text("Incident")
//                    }
//                    .id(appState.selectedTab)
                
                SettingsView()
                    .tag(AppState.Tab.settings)
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
            }
            .tint(Color.dynamicAccent)
        }
        .edgesIgnoringSafeArea(.top)
    }
}



struct AppHeader: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var notificationsViewModel = NotificationsViewModel.shared

    var body: some View {
        VStack(spacing: 0) {
            Color(.systemBackground)
                .frame(height: UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows
                    .first?.safeAreaInsets.top ?? 0)

            HStack(spacing: 16) {
                // App Title
                Text("Safal")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.dynamicAccent) +
                    Text(" IRDrainMate")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.dynamicAccent)

                Spacer()
               
               Button(action: {
                   NavigationManager.shared.navigate(to: .notificationview, style: .push(withAccentColor: Color.dynamicAccent))
               }) {
                   ZStack(alignment: .topTrailing) {
                       Image(systemName: "bell")
                           .font(.system(size: 20, weight: .medium))
                           .foregroundColor(Color.dynamicAccent)
                       
                       if notificationsViewModel.unreadCount > 0 {
                           Text("\(notificationsViewModel.unreadCount)")
                               .font(.system(size: 12, weight: .bold))
                               .foregroundColor(.white)
                               .padding(4)
                               .background(Color.red)
                               .clipShape(Circle())
                               .offset(x: 10, y: -10)
                       }
                   }
               }
               
               Button(action: {
                   NavigationManager.shared.navigate(to: .barcodeScanner, style: .presentFullScreen())
               }) {
                   Image(systemName: "barcode.viewfinder")
                       .font(.system(size: 20, weight: .medium))
                       .foregroundColor(Color.dynamicAccent)
               }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .task {
            await notificationsViewModel.fetchNotificationCount()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}



class QuickActionsManager: ObservableObject {
    static let instance = QuickActionsManager()
    @Published var quickAction: shortQuickAction? = nil

    func handleQaItem(_ item: UIApplicationShortcutItem) {
        print("Shortcut tapped: \(item.type)")
        switch item.type {
        case "com.yourapp.createMeeting":
            quickAction = .createMeeting
        case "com.yourapp.MeetingList":
            quickAction = .meetingList
        case "com.yourapp.report":
            quickAction = .report
        case "com.yourapp.createEvent":
            quickAction = .createEvent
        case "com.yourapp.eventList":
            quickAction = .eventList
        default:
            quickAction = nil
        }
    }
}

enum shortQuickAction: Hashable {
    case createMeeting
    case meetingList
    case report
    case createEvent
    case eventList
}
