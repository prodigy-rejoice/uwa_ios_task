import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isOffline {
                    offlineBanner
                }
                Group {
                    if viewModel.isLoading && viewModel.posts.isEmpty {
                        status(title: "Loading posts...", showsProgress: true, retry: false)
                    } else if let message = viewModel.errorMessage, viewModel.posts.isEmpty {
                        status(title: message, showsProgress: false, retry: true)
                    } else if viewModel.posts.isEmpty {
                        status(
                            title: "No posts yet",
                            message: "Check back later for new posts.",
                            showsProgress: false,
                            retry: true
                        )
                    } else {
                        feed
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.white)
            .navigationTitle("UWA Social")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.accentColor)
        .task {
            await viewModel.loadFeed()
        }
    }

    private var feed: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.posts) { post in
                    PostCardView(post: post) {
                        viewModel.toggleLike(for: post)
                    }
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentPost: post) }
                    }
                    Divider()
                }
                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
        }
        .background(Color(.systemGray6))
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var offlineBanner: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("You're offline")
                .font(.subheadline.weight(.semibold))
            Text("Showing previously loaded posts")
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red)
        .foregroundStyle(.white)
    }

    private func status(
        title: String,
        message: String? = nil,
        showsProgress: Bool,
        retry: Bool
    ) -> some View {
        VStack(spacing: 12) {
            if showsProgress {
                ProgressView()
            }
            Text(title)
                .font(.headline)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if retry {
                Button("Retry") {
                    Task { await viewModel.loadFeed() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
    }
}
