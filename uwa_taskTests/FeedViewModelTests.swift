import XCTest
@testable import uwa_task

@MainActor
final class FeedViewModelTests: XCTestCase {
    private var cacheDirectory: URL!

    override func setUpWithError() throws {
        cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    func testInitialLoadPopulatesPostsAndClearsLoading() async {
        let api = MockAPIService()
        api.pages[1] = PostPage(posts: [samplePost(id: 1), samplePost(id: 2)], page: 1, hasMore: true)
        let viewModel = makeViewModel(api: api)

        await viewModel.loadFeed()

        XCTAssertEqual(viewModel.posts.map(\.id), [1, 2])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isOffline)
    }

    func testPaginationAppendsTheNextPage() async {
        let api = MockAPIService()
        api.pages[1] = PostPage(posts: [samplePost(id: 1), samplePost(id: 2)], page: 1, hasMore: true)
        api.pages[2] = PostPage(posts: [samplePost(id: 3)], page: 2, hasMore: false)
        let viewModel = makeViewModel(api: api)

        await viewModel.loadFeed()
        await viewModel.loadMoreIfNeeded(currentPost: viewModel.posts[1])

        XCTAssertEqual(viewModel.posts.map(\.id), [1, 2, 3])
        XCTAssertEqual(api.requestedPages, [1, 2])
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    func testFailedLoadWithNoCacheSetsError() async {
        let api = MockAPIService()
        api.error = APIError.network
        let viewModel = makeViewModel(api: api)

        await viewModel.loadFeed()

        XCTAssertTrue(viewModel.posts.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Unable to load posts.")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isOffline)
    }

    func testLikeTogglesStateAndCount() async {
        let api = MockAPIService()
        api.pages[1] = PostPage(posts: [samplePost(id: 4, likeCount: 10)], page: 1, hasMore: false)
        let viewModel = makeViewModel(api: api)

        await viewModel.loadFeed()
        viewModel.toggleLike(for: viewModel.posts[0])

        XCTAssertTrue(viewModel.posts[0].isLiked)
        XCTAssertEqual(viewModel.posts[0].likeCount, 11)

        viewModel.toggleLike(for: viewModel.posts[0])

        XCTAssertFalse(viewModel.posts[0].isLiked)
        XCTAssertEqual(viewModel.posts[0].likeCount, 10)
    }

    private func makeViewModel(api: MockAPIService) -> FeedViewModel {
        FeedViewModel(api: api, cache: OfflineCacheService(directory: cacheDirectory), monitorsNetwork: false)
    }

    private func samplePost(id: Int, likeCount: Int = 1) -> Post {
        Post(
            id: id,
            user: User(id: id, name: "Tester", avatarURL: URL(string: "https://example.com/a.png")!),
            text: "Hello",
            mediaURL: URL(string: "https://example.com/p.png")!,
            location: "Lagos, Nigeria",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            likeCount: likeCount,
            commentCount: 2,
            isLiked: false
        )
    }
}

private final class MockAPIService: APIServicing {
    var pages: [Int: PostPage] = [:]
    var error: Error?
    private(set) var requestedPages: [Int] = []

    func fetchPosts(page: Int, limit: Int) async throws -> PostPage {
        requestedPages.append(page)
        if let error { throw error }
        return pages[page] ?? PostPage(posts: [], page: page, hasMore: false)
    }
}
