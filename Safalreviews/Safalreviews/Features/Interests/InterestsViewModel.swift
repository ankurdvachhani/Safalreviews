//
//  InterestsViewModel.swift
//  Safalreviews
//
//  Created by Antigravity on 23/03/30.
//

import Foundation
import Combine

class InterestsViewModel: ObservableObject {
    @Published var allInterests: [Interest] = []
    @Published var selectedInterests: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaved = false
    
    private let service: DataCollectionServing
    private var cancellables = Set<AnyCancellable>()
    
    init(service: DataCollectionServing = DataCollectionService()) {
        self.service = service
    }
    
    @MainActor
    func fetchAllInterests() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchInterests()
            if response.success {
                self.allInterests = response.data
            } else {
                self.errorMessage = "Failed to fetch interests"
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func fetchUserSelectedInterests() async {
        guard let userId = TokenManager.shared.getUserId() else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await service.fetchUserInterests(userId: userId)
            if let interests = response.data?.interests {
                self.selectedInterests = Set(interests)
                UserDefaults.standard.set(interests, forKey: "userInterests")
            }
        } catch {
            print("Error fetching user interests: \(error.localizedDescription)")
            // We don't set errorMessage here as it might just be the first time
        }
        isLoading = false
    }
    
    @MainActor
    func saveInterests() async {
        guard let userId = TokenManager.shared.loadCurrentUser()?.id  else { return }
        isLoading = true
        errorMessage = nil
        
        // We use the existing sendDataCollection but only with the interests field
        // This keeps it consistent with how the API expects the update.
        // Actually, we should call the full data collection update.
        
        let user = TokenManager.shared.loadCurrentUser()
        let request = DataCollectionRequest(
            userId: userId,
            gender: user?.metadata?.gender,
            languagePreference: "English", 
            firstName: user?.firstName,
            lastName: user?.lastName,
            email: user?.email,
            phoneNumber: user?.phoneNumber,
            ip: nil,
            tags: nil,
            interests: Array(selectedInterests),
            latitude: nil,
            longitude: nil,
            lastLocationUpdate: nil,
            fcmToken: nil,
            address: nil,
            state: user?.state,
            country: user?.country,
            zip: nil,id: ""
        )
        
        do {
            let response = try await service.sendDataCollection(request: request)
            if response.success {
                let interestsArray = Array(selectedInterests)
                UserDefaults.standard.set(interestsArray, forKey: "userInterests")
                DataCollectionManager.shared.setInterestsStatus(isSet: true)
                self.isSaved = true
            } else {
                self.errorMessage = "Failed to save interests"
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func toggleInterest(_ value: String) {
        if selectedInterests.contains(value) {
            selectedInterests.remove(value)
        } else {
            selectedInterests.insert(value)
        }
    }
}
