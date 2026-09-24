import Foundation

struct Post: Codable, Identifiable, Equatable {
    let id: Int
    let user: User
    let text: String
    let mediaURL: URL
    let location: String
    let createdAt: Date
    var likeCount: Int
    let commentCount: Int
    var isLiked: Bool

    var city: String {
        location.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? location
    }
}

struct PostPage: Codable, Equatable {
    let posts: [Post]
    let page: Int
    let hasMore: Bool
}
