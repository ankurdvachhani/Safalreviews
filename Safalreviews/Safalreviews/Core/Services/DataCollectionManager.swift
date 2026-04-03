//
//  DataCollectionManager.swift
//  Safalreviews
//
//  Created by Antigravity on 23/03/26.
//

import Foundation
import CoreLocation
import UIKit

class DataCollectionManager: NSObject, ObservableObject {
    static let shared = DataCollectionManager()
    
    private let service: DataCollectionServing
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isTaskPending = false
    @Published var hasInterestsSet: Bool = UserDefaults.standard.bool(forKey: "hasInterestsSet")
    
    private init(service: DataCollectionServing = DataCollectionService()) {
        self.service = service
        super.init()
        setupLocationManager()
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 DataCollection: App became active, triggering collection.")
        triggerDataCollection()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Triggers the data collection with an optional delay.
    func triggerDataCollection(withDelay delay: TimeInterval = 0) {
        // Request permission if not already determined
        if locationManager.authorizationStatus == .notDetermined {
            print("📍 DataCollection: Status not determined, requesting permission.")
            requestLocationPermission()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            if lastLocation == nil {
                print("📍 DataCollection: Already authorized, starting location updates.")
                locationManager.startUpdatingLocation()
            }
        }
        
        guard !isTaskPending else { return }
        
        isTaskPending = true
        
        Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            await collectAndSendData()
            isTaskPending = false
        }
    }
    
    private func collectAndSendData() async {
        guard TokenManager.shared.getToken() != nil else {
            print("🚫 DataCollection: User not authenticated, skipping.")
            return
        }
        
        let user = TokenManager.shared.loadCurrentUser()
        let userId = TokenManager.shared.loadCurrentUser()?.id ?? ""
        let fcmToken = UserDefaults.standard.string(forKey: "fcmToken")
        
        // Basic location info if available
        let latitude = lastLocation?.coordinate.latitude
        let longitude = lastLocation?.coordinate.longitude
        let lastUpdate = lastLocation?.timestamp.iso8601String
        
        // Fetch IP Address
        var ipAddress: String? = nil
        if let url = URL(string: "https://api.ipify.org?format=json") {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    ipAddress = json["ip"] as? String
                }
            } catch {
                print("❌ Failed to fetch IP: \(error.localizedDescription)")
            }
        }

        // Reverse Geocode Address
        var address: String? = nil
        var zipCode: String? = nil
        
        if let location = lastLocation {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    address = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    
                    zipCode = placemark.postalCode
                }
            } catch {
                print("❌ Failed to reverse geocode: \(error.localizedDescription)")
            }
        }
        
        let request = DataCollectionRequest(
            userId: userId,
            gender: user?.metadata?.gender,
            languagePreference: "English", // Default or fetch from settings if available
            firstName: user?.firstName,
            lastName: user?.lastName,
            email: user?.email,
            phoneNumber: user?.phoneNumber,
            ip: ipAddress,
            tags: nil,
            interests: UserDefaults.standard.stringArray(forKey: "userInterests"),
            latitude: latitude,
            longitude: longitude,
            lastLocationUpdate: lastUpdate,
            fcmToken: fcmToken != nil ? [fcmToken!] : nil,
            address: address,
            state: user?.state,
            country: user?.country,
            zip: zipCode, id: ""
        )
        
        do {
            let response = try await service.sendDataCollection(request: request)
            if response.success {
                print("✅ DataCollection: Successfully shared information.")
            } else {
                print("⚠️ DataCollection: API returned success=false.")
            }
        } catch {
            print("❌ DataCollection: Failed to share information: \(error.localizedDescription)")
        }
    }

    /// Handles a notification open event and tracks the data count if the orchestrator ID is present.
    func handleNotificationOpen(userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["notificationOrchestratorId"] as? String else {
            print("ℹ️ DataCollection: No notificationOrchestratorId found in userInfo.")
            return
        }
        
        let userId = TokenManager.shared.getUserId() ?? ""
        print("📲 DataCollection: Tracking notification open for ID: \(id)")
        
        Task {
            do {
                let response = try await service.sendNotificationDataCount(id: id, userId: userId)
                if response.success {
                    print("✅ DataCollection: Successfully tracked notification open.")
                } else {
                    print("⚠️ DataCollection: Failed to track notification open (success=false).")
                }
            } catch {
                print("❌ DataCollection: Error tracking notification open: \(error.localizedDescription)")
            }
        }
    }

    func setInterestsStatus(isSet: Bool) {
        self.hasInterestsSet = isSet
        UserDefaults.standard.set(isSet, forKey: "hasInterestsSet")
    }
}

// MARK: - CLLocationManagerDelegate
extension DataCollectionManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 DataCollection: Location permission granted.")
            locationManager.startUpdatingLocation()
            // Trigger call immediately when permission is granted
            triggerDataCollection()
        case .denied, .restricted:
            print("📍 DataCollection: Location permission denied.")
            // Still trigger data collection, just without location info
            triggerDataCollection()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.lastLocation = location
        // Optional: stop updating to save battery if we only need a one-time snap
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ DataCollection: Location update failed: \(error.localizedDescription)")
    }
}

// MARK: - Helper Extensions
private extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
