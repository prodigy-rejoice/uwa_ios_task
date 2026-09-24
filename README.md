# UWA Social

A simple iOS social feed built with SwiftUI. It loads posts in pages, supports local likes, handles common loading states, and shows the last saved posts when the network is unavailable.

## Features

* Paginated feed with infinite scrolling
* Pull to refresh
* Like posts locally
* Loading, empty, error, and offline states
* Image caching
* Basic offline caching
* Unit tests for the feed logic

## Architecture

The app uses a simple MVVM structure:

```text
FeedView
    ↓
FeedViewModel
    ↓
APIService / OfflineCacheService
```

`FeedViewModel` handles the feed state, pagination, and likes, while the view focuses on displaying the UI.

I kept the structure intentionally simple for the scope of the assessment rather than adding extra layers that weren't necessary.

## Implementation

* **SwiftUI** is used for the UI.
* **MVVM** keeps the UI and feed logic separate.
* **async/await** is used for loading data and images.
* Posts are loaded from a local mock API that behaves like a paginated API.
* **NSCache** is used to avoid downloading the same images repeatedly.
* The last successful feed is saved locally as JSON so it can still be displayed when the network is unavailable.
* Likes are handled locally and update immediately.

The mock API provides three pages of posts, with 10 posts per page.

## Pagination

The first page is loaded when the feed opens. As the user gets near the end of the list, the next page is loaded automatically.

The app prevents multiple pagination requests from happening at the same time and stops requesting more posts when there are no more pages.

Pulling down to refresh starts again from the first page.

## Offline Support

After a successful load, the current posts are saved locally.

If a later request fails and cached posts are available, the app displays them with an offline message. Pagination is disabled while offline.

If there is no cached data yet, the app shows an error state with a Retry option.

## Testing

The feed view model has tests covering:

* Successful initial loading
* Pagination
* Error handling
* Liking a post

![simulator_screenshot_63086251-A19B-4D89-8494-D92FF94011B7](https://github.com/user-attachments/assets/d4338d52-5b12-4bb2-b6fb-8bd2f5273892)


![simulator_screenshot_2DE5E2ED-FF42-48E4-BAF6-31463D58CFE1](https://github.com/user-attachments/assets/d83c438c-7cd8-46c0-8450-3aaa9d7d308e)

