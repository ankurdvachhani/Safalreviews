//
//  DataCollectionService.swift
//  Safalreviews
//
//  Created by Antigravity on 23/03/26.
//

import Foundation

struct DataCollectionRequest: Codable {
    let userId: String?
    let gender: String?
    let languagePreference: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let ip: String?
    let tags: [String]?
    let interests: [String]?
    let latitude: Double?
    let longitude: Double?
    let lastLocationUpdate: String?
    let fcmToken: [String]?
    let address: String?
    let state: String?
    let country: String?
    let zip: String?
    let id: String
}

struct Interest: Codable, Identifiable {
    var id: String { value }
    let label: String
    let value: String
}

struct InterestsResponse: Codable {
    let success: Bool
    let data: [Interest]
}

struct UserInterestsData: Codable {
    let _id: String
    let interests: [String]?
    let tags: [String]?
}

struct UserInterestsResponse: Codable {
    let success: Bool
    let data: UserInterestsData?
}

struct DataCollectionResponse: Codable {
    let success: Bool
}

struct NotificationDataCountRequest: Codable {
    let userId: String
    let device: String
    let id: String
}

protocol DataCollectionServing {
    func sendDataCollection(request: DataCollectionRequest) async throws -> DataCollectionResponse
    func sendNotificationDataCount(id: String, userId: String?) async throws -> DataCollectionResponse
    func fetchInterests() async throws -> InterestsResponse
    func fetchUserInterests(userId: String) async throws -> UserInterestsResponse
}

class DataCollectionService: DataCollectionServing {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager = DIContainer.shared.resolve()) {
        self.networkManager = networkManager
    }
    
    func sendDataCollection(request: DataCollectionRequest) async throws -> DataCollectionResponse {
        guard let url = URL(string: APIConfig.utilitiesUrl + APIConfig.Path.dataCollection) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        
        // Encode the request
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(DataCollectionResponse.self, from: data)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch {
            NetworkLogger.log(response: nil, data: nil, error: error)
            throw error
        }
    }
    
    func sendNotificationDataCount(id: String, userId: String?) async throws -> DataCollectionResponse {
        guard let url = URL(string: APIConfig.utilitiesUrl + APIConfig.Path.notificationDataCount) else {
            throw NetworkError.invalidURL
        }
        
        let request = NotificationDataCountRequest(
            userId: userId ?? "",
            device: "IOS",
            id: id
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        
        // Encode the request
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(DataCollectionResponse.self, from: data)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch {
            NetworkLogger.log(response: nil, data: nil, error: error)
            throw error
        }
    }
    
    func fetchInterests() async throws -> InterestsResponse {
        guard let url = URL(string: APIConfig.utilitiesUrl + APIConfig.Path.interests) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(InterestsResponse.self, from: data)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch {
            NetworkLogger.log(response: nil, data: nil, error: error)
            throw error
        }
    }
    
    func fetchUserInterests(userId: String) async throws -> UserInterestsResponse {
        var components = URLComponents(string: APIConfig.utilitiesUrl + APIConfig.Path.dataCollection)
        components?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Log the response
            NetworkLogger.log(response: response, data: data, error: nil)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(UserInterestsResponse.self, from: data)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch {
            NetworkLogger.log(response: nil, data: nil, error: error)
            throw error
        }
    }
}
