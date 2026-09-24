import Foundation
import Network

enum APIError: Error {
    case invalidURL
    case network
    case server
    case decoding
}

protocol APIServicing: Sendable {
    func fetchPosts(page: Int, limit: Int) async throws -> PostPage
}

extension Notification.Name {
    static let uwaReachabilityChanged = Notification.Name("uwaReachabilityChanged")
}

/// Watches the network path and confirms it with a short request.
/// The simulator can report an unsatisfied path while Wi-Fi is actually up, which left the offline banner stuck.
nonisolated final class Reachability: @unchecked Sendable {
    static let shared = Reachability()

    private let monitor = NWPathMonitor()
    private static let probeURL = URL(string: "https://captive.apple.com/hotspot-detect.html")

    private init() {
        monitor.pathUpdateHandler = { _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .uwaReachabilityChanged, object: nil)
            }
        }
        monitor.start(queue: DispatchQueue(label: "uwa.reachability"))
    }

    func confirmConnected() async -> Bool {
        if monitor.currentPath.status == .satisfied {
            return true
        }
        guard let probeURL = Self.probeURL else { return false }

        var request = URLRequest(url: probeURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return response is HTTPURLResponse
        } catch {
            return false
        }
    }
}

/// Local stand-in for `GET /posts?page=&limit=`.
/// A public mock API does not return this post shape, so pages are sliced from in-memory data.
final class APIService: APIServicing {
    func fetchPosts(page: Int, limit: Int) async throws -> PostPage {
        try await Task.sleep(nanoseconds: 350_000_000)
        guard await Reachability.shared.confirmConnected() else { throw APIError.network }
        guard page > 0, limit > 0 else { throw APIError.invalidURL }

        let all = MockFeed.posts
        let start = (page - 1) * limit
        guard start < all.count else {
            return PostPage(posts: [], page: page, hasMore: false)
        }

        let end = min(start + limit, all.count)
        return PostPage(posts: Array(all[start..<end]), page: page, hasMore: end < all.count)
    }
}

private enum MockFeed {
    static let posts: [Post] = makePosts()

    private static func makePosts() -> [Post] {
        let users: [User] = [
            user(1, "John Doe", 12),
            user(2, "Jane Doe", 5),
            user(3, "Amaka Okonkwo", 32),
            user(4, "Chinedu Obi", 15),
            user(5, "Fatima Bello", 47),
            user(6, "Tunde Bakare", 8),
            user(7, "Adaeze Nwosu", 25),
            user(8, "Ibrahim Musa", 60)
        ]

        let lines: [(String, String, Int, Int, Int)] = [
            ("Market day in Yaba was loud in the best way. New fabric, old friends.", "Lagos, Nigeria", 1015, 120, 24),
            ("Sunrise over the hills. Worth the early alarm.", "Abuja, Nigeria", 1016, 87, 10),
            ("Shared a plate of suya after rehearsal. The band is getting tight.", "Enugu, Nigeria", 1018, 64, 8),
            ("The bridge looks different after the rain.", "Port Harcourt, Nigeria", 1025, 203, 31),
            ("Planted tomatoes on the balcony. We will see who wins, me or the birds.", "Ibadan, Nigeria", 1036, 41, 6),
            ("Match day. Green everywhere.", "Kano, Nigeria", 1043, 318, 57),
            ("Found a quiet corner of the library and stayed too long.", "Zaria, Nigeria", 1049, 22, 3),
            ("Boat ride at dusk. The water was warm.", "Calabar, Nigeria", 1050, 156, 19),
            ("New mural on the side of the studio. Come see it this weekend.", "Lagos, Nigeria", 1069, 98, 14),
            ("Family lunch ran for four hours. Nobody was in a hurry.", "Abeokuta, Nigeria", 1074, 73, 11),
            ("First coffee, then the long edit. Sending the cut tonight.", "Abuja, Nigeria", 1080, 55, 9),
            ("The market cats have unionized. They want fish.", "Lagos, Nigeria", 1084, 140, 22),
            ("Training at dawn. Legs are complaining, playlist is not.", "Benin City, Nigeria", 129, 36, 4),
            ("Sold out of the small jars by noon. Thank you.", "Onitsha, Nigeria", 133, 88, 16),
            ("A short walk turned into a long one. The city was kind today.", "Kaduna, Nigeria", 160, 47, 7),
            ("Rehearsal photos from last night. The light was unfairly good.", "Lagos, Nigeria", 164, 211, 28),
            ("Rain on the zinc roof is still my favorite sound.", "Owerri, Nigeria", 177, 63, 5),
            ("We finally fixed the generator. Neighborhood group chat can rest.", "Uyo, Nigeria", 180, 129, 33),
            ("Sunday best, slightly wrinkled. Church first, then chin-chin.", "Ilorin, Nigeria", 201, 74, 12),
            ("The team shipped. Celebrating with grilled fish.", "Lagos, Nigeria", 225, 256, 41),
            ("Classroom windows open, harmattan light coming in.", "Jos, Nigeria", 244, 39, 6),
            ("Night market noodles. Spicy enough.", "Abuja, Nigeria", 250, 91, 13),
            ("Paint on my hands and nowhere else I need to be.", "Lagos, Nigeria", 292, 118, 17),
            ("Cousin brought plantains from home. Immediate upgrade to the week.", "Asaba, Nigeria", 312, 67, 9),
            ("Last light on the waterfront. See you tomorrow.", "Lagos, Nigeria", 326, 174, 21)
        ]

        let now = Date()
        return lines.enumerated().map { index, line in
            let hours = (index + 1) * 2
            return Post(
                id: index + 1,
                user: users[index % users.count],
                text: line.0,
                mediaURL: url("https://picsum.photos/id/\(line.2)/800/500"),
                location: line.1,
                createdAt: now.addingTimeInterval(TimeInterval(-hours * 3600)),
                likeCount: line.3,
                commentCount: line.4,
                isLiked: false
            )
        }
    }

    private static func user(_ id: Int, _ name: String, _ avatar: Int) -> User {
        User(
            id: id,
            name: name,
            avatarURL: url("https://i.pravatar.cc/150?img=\(avatar)")
        )
    }

    private static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Invalid mock URL: \(string)")
        }
        return url
    }
}
