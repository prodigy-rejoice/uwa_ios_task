import SwiftUI

struct PostCardView: View {
    let post: Post
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Text(post.text)
                .font(.body)
                .foregroundStyle(.primary)
            RemoteImage(url: post.mediaURL)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Label(post.location, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            actions
        }
        .padding(16)
        .background(Color.white)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            RemoteImage(url: post.user.avatarURL)
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(post.user.name)
                    .font(.headline)
                Text("\(Self.relative.localizedString(for: post.createdAt, relativeTo: Date())) · \(post.city)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var actions: some View {
        HStack(spacing: 20) {
            Button(action: onLike) {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
            }
            .buttonStyle(.plain)
            .foregroundStyle(post.isLiked ? Color.accentColor : .secondary)
            .accessibilityLabel(post.isLiked ? "Unlike" : "Like")

            Label("\(post.commentCount)", systemImage: "bubble.right")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.subheadline)
    }

    private static let relative: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}

struct RemoteImage: View {
    let url: URL?

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(.systemGray5)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipped()
        .task(id: url) {
            image = await ImageCache.shared.image(for: url)
        }
    }
}
