import Combine
import Foundation

@MainActor
final class FeedViewModel: ObservableObject {
    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var isOffline = false

    private var currentPage = 1
    private var hasMorePages = true
    private let pageSize = 10
    private let api: APIServicing
    private let cache: OfflineCacheService
    private var reachabilityObserver: NSObjectProtocol?

    init(
        api: APIServicing = APIService(),
        cache: OfflineCacheService = OfflineCacheService(),
        monitorsNetwork: Bool = true
    ) {
        self.api = api
        self.cache = cache
        guard monitorsNetwork else { return }
        reachabilityObserver = NotificationCenter.default.addObserver(
            forName: .uwaReachabilityChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleReachabilityChange()
            }
        }
    }

    deinit {
        if let reachabilityObserver {
            NotificationCenter.default.removeObserver(reachabilityObserver)
        }
    }

    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = posts.isEmpty
        errorMessage = nil
        isOffline = false
        currentPage = 1

        do {
            let page = try await api.fetchPosts(page: 1, limit: pageSize)
            posts = page.posts
            hasMorePages = page.hasMore
            isOffline = false
            try? cache.save(posts)
        } catch {
            applyCachedFallback()
        }

        isLoading = false
    }

    func refresh() async {
        await loadFeed()
    }

    func loadMoreIfNeeded(currentPost: Post) async {
        guard let last = posts.last, last.id == currentPost.id else { return }
        guard !isOffline, hasMorePages, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let nextPage = currentPage + 1
        do {
            let page = try await api.fetchPosts(page: nextPage, limit: pageSize)
            currentPage = nextPage
            posts.append(contentsOf: page.posts)
            hasMorePages = page.hasMore
            try? cache.save(posts)
        } catch {
            // Keep the posts already on screen. The next scroll can try again.
        }
    }

    func toggleLike(for post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
    }

    private func handleReachabilityChange() async {
        let online = await Reachability.shared.confirmConnected()
        if online {
            guard isOffline else { return }
            isLoading = false
            await loadFeed()
        } else if !isOffline {
            applyCachedFallback()
        }
    }

    private func applyCachedFallback() {
        if let cached = cache.load(), !cached.isEmpty {
            posts = cached
            isOffline = true
            hasMorePages = false
            errorMessage = nil
        } else if posts.isEmpty {
            errorMessage = "Unable to load posts."
        }
    }
}
