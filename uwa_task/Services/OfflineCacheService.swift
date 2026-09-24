import Foundation

final class OfflineCacheService {
    private let fileURL: URL

    init(directory: URL? = nil) {
        let folder = directory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        fileURL = folder.appendingPathComponent("cached-posts.json")
    }

    func save(_ posts: [Post]) throws {
        let data = try JSONEncoder().encode(posts)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() -> [Post]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([Post].self, from: data)
    }
}
