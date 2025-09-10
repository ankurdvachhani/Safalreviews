import Foundation

// MARK: - Media Presentation Data
struct MediaPresentationData: Identifiable {
    let id = UUID()
    let mediaURLs: [String]
    let initialIndex: Int
}
