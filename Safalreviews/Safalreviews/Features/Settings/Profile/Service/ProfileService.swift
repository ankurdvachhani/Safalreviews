import Foundation
import UIKit

//// MARK: - Verification Models
//struct CodeSendVerificatonRequest: Codable {
//    let type: String
//    let value: String
//    let userCheck: Bool?
//
//    enum CodingKeys: String, CodingKey {
//        case type
//        case value
//        case userCheck
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(type, forKey: .type)
//        try container.encode(value, forKey: .value)
//        try container.encode(userCheck, forKey: .userCheck)
//    }
//}
//
//struct CodeVerificatonRequest: Codable {
//    let otp: String
//    let verifyId: String
//    let value: String
//
//    enum CodingKeys: String, CodingKey {
//        case otp
//        case verifyId
//        case value
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(otp, forKey: .otp)
//        try container.encode(verifyId, forKey: .verifyId)
//        try container.encode(value, forKey: .value)
//    }
//}

// MARK: - Profile Response Models
struct ProfiledResponse: Codable {
    let success: Bool
    let data: UserModel
}

// MARK: - Two-Factor Authentication Models
struct TwoFactorAuthRequest: Codable {
    let auth2faEmail: String
    let auth2faPhoneNumber: String
    let auth2faEmailVerifiedId: String
    let auth2faPhoneNumberVerifiedId: String
    let auth2faBackup: Bool
}

struct TwoFactorAuthResponse: Codable {
    let success: Bool
    let data: TwoFactorAuthData?
    let errors: [String]?
    let timestamp: String?
    let message: String?
}

struct TwoFactorAuthData: Codable {
    let auth2faBackupPassword: [String]?
}


protocol ProfileServicing {
    func fetchProfile() async throws -> UserModel
    func updateProfile(firstName: String, lastName: String, email: String, phoneNumber: String, country: String, state: String, dob: String, gender: String, profilePicture: String, phoneNumberVerifyId: String?, emailVerifyId: String?) async throws -> UserUpdateResponse
    func uploadImage(_ image: UIImage) async throws -> String?
    func sendCodeForVerification(type: String, value: String, phoneNumber: String, isSendRequest: Bool) async throws -> VerificationResponse
    func deleteAccount(password: String) async throws -> Bool
    func updateTwoFactorAuthentication(enabled: Bool) async throws -> Bool
    func updateTwoFactorAuthentication(request: TwoFactorAuthRequest) async throws -> (Bool, [String]?)
}

actor ProfileService: ProfileServicing {
    func deleteAccount(password: String) async throws -> Bool {
        let endpoint = Endpoint(path: APIConfig.Path.deleteAccount)
        
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        request.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        var bodyData:[String:Any] = [:]
        if let token = UserDefaults.standard.string(forKey: "fcmToken") {
             bodyData = ["password": password,"fcm": token] as! [String: Any]
        }else{
            bodyData = ["password": password] as! [String: Any]
        }
       
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData)
        } catch {
            throw NetworkError.apiError("invalid Password")
        }
        
        let response: EmptyResponse = try await networkManager.fetch(endpoint, urlRequest: request)
        return response.success
    }
    
  
    
    private let networkManager: NetworkManaging
    
    init(networkManager: NetworkManaging = NetworkManager()) {
        self.networkManager = networkManager
    }
    
    func fetchProfile() async throws -> UserModel {
        let endpoint = Endpoint(path: APIConfig.Path.userProfile)
        
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        request.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        
        let response: ProfiledResponse = try await networkManager.fetch(endpoint, urlRequest: request)
        // Store user data
        let user: UserModel = response.data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        return response.data
    }
    
    func resizedImage(_ image: UIImage, maxWidth: CGFloat = 1080) -> UIImage {
          let scale = maxWidth / image.size.width
          let newHeight = image.size.height * scale
          let newSize = CGSize(width: maxWidth, height: newHeight)
          
          UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
          image.draw(in: CGRect(origin: .zero, size: newSize))
          let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          
          return resizedImage ?? image
      }
    
    func uploadImage(_ image: UIImage) async throws -> String? {
        let smallImage = resizedImage(image)
        guard let imageData = smallImage.jpegData(compressionQuality: 0.2) else {
            throw NetworkError.invalidData
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let uniqueFileName = "profile_image_\(timestamp).jpg"
        
        print("📤 Uploading profile image: \(uniqueFileName)")
        
        let uploadRequest = ProfileImageUploadRequest(
            fileName: uniqueFileName,
            folder: "reviews/profiles/pictures"
        )
        
        return try await uploadMedia(uploadRequest: uploadRequest, filedata: imageData, contentType: "image/jpeg")
    }
    
    private func uploadMedia<T: Codable>(uploadRequest: T, filedata: Data, contentType: String) async throws -> String? {
        
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Path.getUploadUrls) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: "Cookie")
        urlRequest.httpBody = try JSONEncoder().encode(uploadRequest)
        
        // Log the request
        NetworkLogger.log(request: urlRequest)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        // Log the response
        NetworkLogger.log(response: response, data: data, error: nil)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let uploadUrlResponse = try JSONDecoder().decode(ProfileImageUploadResponse.self, from: data)
            
            print("Got signed URL for upload: \(uploadUrlResponse.data.uploadUrl)")
            
            // Upload file using NetworkManager
            try await networkManager.uploadFile(
                url: uploadUrlResponse.data.uploadUrl,
                data: filedata,
                contentType: contentType
            )
            
            print("✅ Profile image uploaded successfully")
            return uploadUrlResponse.data.fileUrl
        } else {
            throw NetworkError.apiError("Failed to get upload URL: \(httpResponse.statusCode)")
        }
    }
    
    func updateProfile(firstName: String, lastName: String, email: String, phoneNumber: String, country: String, state: String, dob: String, gender: String, profilePicture: String, phoneNumberVerifyId: String?, emailVerifyId: String?) async throws -> UserUpdateResponse {
        // First fetch current profile to compare email
        let currentProfile = try await fetchProfile()
        
        guard let userId = TokenManager.shared.getUserId() else {
            throw NetworkError.unauthorized
        }
        
        let endpoint = Endpoint(path: "\(APIConfig.Path.userUpdateById)/\(userId)")
        
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        request.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        
        // Create mutable dictionary for body data
        var bodyData: [String: Any] = [:]
        
        // Only add non-empty values
        if !firstName.isEmpty {
            bodyData["firstName"] = firstName
        }
        
        if !lastName.isEmpty {
            bodyData["lastName"] = lastName
        }
        
        // Only add email if it's different from current profile
        if !email.isEmpty && email != currentProfile.email {
            bodyData["email"] = email
        }
        
        // Always add emailVerifyId (even if empty)
        bodyData["emailVerifyId"] = emailVerifyId ?? ""
        
        if !country.isEmpty {
            bodyData["country"] = country
        }
        
        if !state.isEmpty {
            bodyData["state"] = state
        }
        
        if !dob.isEmpty {
            bodyData["dob"] = dob
        }
        
        // Add gender as top-level field
        if !gender.isEmpty {
            bodyData["gender"] = gender
        }
        
        // Add username as top-level field (get from current profile metadata)
        if let currentUsername = currentProfile.metadata?.username, !currentUsername.isEmpty {
            bodyData["username"] = currentUsername
        }
        
        // Add phone number only if it's not empty and not just "+"
        if !phoneNumber.isEmpty && phoneNumber != "+" {
            let formattedPhoneNumber = phoneNumber.starts(with: "+") ? phoneNumber : "\(phoneNumber)"
            bodyData["phoneNumber"] = formattedPhoneNumber
        }else{
            if !country.isEmpty {
               // bodyData["phoneNumber"] = ""
            }
        }
        
        // Add profilePicture if available
        if !profilePicture.isEmpty {
            bodyData["profilePicture"] = profilePicture
        }
        
        // Always add phoneNumberVerifyId (even if empty)
        bodyData["phoneNumberVerifyId"] = phoneNumberVerifyId ?? ""
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData)
        } catch {
            throw NetworkError.invalidResponse
        }
        
        let response: UserUpdateResponse = try await networkManager.fetch(endpoint, urlRequest: request)
        return response // Return the full response with message and error details
    }
    
    func sendCodeForVerification(type: String, value: String, phoneNumber: String, isSendRequest: Bool) async throws -> VerificationResponse {
        // Use the same endpoint as NetworkManager for consistency
        guard let url = URL(string: APIConfig.authModuleURLString + APIConfig.Path.codeVerification) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = isSendRequest ? "POST" : "PUT"
        request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        request.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        
        if isSendRequest {
            let resetRequest = CodeSendVerificatonRequest(type: type, value: value, userCheck: true)
            request.httpBody = try? JSONEncoder().encode(resetRequest)
        } else {
            let resetRequest = CodeVerificatonRequest(otp: type, verifyId: value, value: phoneNumber)
            request.httpBody = try? JSONEncoder().encode(resetRequest)
        }
        
        return try await networkManager.fetch(Endpoint(path: ""), urlRequest: request)
    }
    
    func updateTwoFactorAuthentication(enabled: Bool) async throws -> Bool {
        let endpoint = Endpoint(path: "/api/user/two-factor-auth")
        
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        request.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        
        let bodyData = ["enabled": enabled] as [String: Any]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyData)
        } catch {
            throw NetworkError.apiError("Invalid request data")
        }
        
        let response: UserUpdateResponse = try await networkManager.fetch(endpoint, urlRequest: request)
        return response.success
    }
    
    func updateTwoFactorAuthentication(request: TwoFactorAuthRequest) async throws -> (Bool, [String]?) {
        let endpoint = Endpoint(path: APIConfig.Path.userUpdate)
        
        guard let url = URL(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue(APIConfig.ContentType.json, forHTTPHeaderField: APIConfig.Header.contentType)
        urlRequest.setValue("access_token=\(TokenManager.shared.getToken() ?? "")", forHTTPHeaderField: APIConfig.Header.cookie)
        
        let bodyData: [String: Any] = [
            "auth2faEmail": request.auth2faEmail,
            "auth2faPhoneNumber": request.auth2faPhoneNumber,
            "auth2faEmailVerifiedId": request.auth2faEmailVerifiedId,
            "auth2faPhoneNumberVerifiedId": request.auth2faPhoneNumberVerifiedId,
            "auth2faBackup": request.auth2faBackup
        ]
        
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: bodyData)
        } catch {
            throw NetworkError.apiError("Invalid request data")
        }
        
        let response: TwoFactorAuthResponse = try await networkManager.fetch(endpoint, urlRequest: urlRequest)
        
        // Extract backup codes from the data object
        let backupCodes = response.data?.auth2faBackupPassword
        
        return (response.success, backupCodes)
    }
}

struct UserUpdateResponse: Codable {
    let success: Bool
    let message: String?
    let error: String?
   
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case error
    }
}


// MARK: - Profile Image Upload Models

struct ProfileImageUploadRequest: Codable {
    let fileName: String
    let folder: String
}

struct ProfileImageUploadResponse: Codable {
    let status: String
    let data: ProfileUploadData
}

struct ProfileUploadData: Codable {
    let uploadUrl: String
    let fileUrl: String
}

extension NetworkError {
    static let uploadFailed = NetworkError.apiError("Failed to upload image")
    static let invalidData = NetworkError.apiError("Failed to upload image")
}
