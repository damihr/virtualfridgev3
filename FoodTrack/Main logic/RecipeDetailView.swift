//
//  RecipeDetailView.swift
//  FoodTrack
//
//  Created by Damir Kamalov on 27.06.2025.
//
import SwiftUI
import WebKit
import Combine

struct RecipeDetailView: View {
    let recipe: MyRecipe
    let imageURL: URL?
    @State private var showVideoPlayer: Bool = false

    var body: some View {
        ScrollView {
            // Image
            if let url = imageURL {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: { Color.gray.opacity(0.2) }
                .frame(height: 240).clipped()
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.name)
                    .font(.largeTitle).bold()

                if let desc = recipe.description {
                    Text(desc)
                }

                // YouTube Video Preview
                if !recipe.name.isEmpty {
                    YouTubePreviewView(query: "\(recipe.name) recipe")
                        .padding(.vertical, 8)
                }

                if !recipe.ingredients.isEmpty {
                    Text("Ingredients")
                        .font(.title3).bold().padding(.top, 8)
                    ForEach(recipe.ingredients, id: \.self) { ing in
                        Text("• \(ing)")
                    }
                }

                if !recipe.steps.isEmpty {
                    Text("Instructions")
                        .font(.title3).bold().padding(.top, 8)
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.0) { idx, step in
                            Text("\(idx + 1). \(step)")
                                .font(.body)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - YouTube Preview View

struct YouTubePreviewView: View {
    let query: String
    @State private var video: YouTubeVideo? = YouTubeCache.shared.get(query: "")
    @State private var showPlayer = false
    @State private var isLoading = true
    @State private var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Video Tutorial")
                .font(.title3).bold()

            if isLoading {
                HStack {
                    ProgressView()
                    Text("Searching YouTube...")
                        .foregroundColor(.secondary)
                }
            } else if let video = video {
                if showPlayer {
                    YouTubePlayerView(videoID: video.id)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(12)
                } else {
                    Button(action: { showPlayer = true }) {
                        ZStack {
                            AsyncImage(url: video.thumbnailURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: { Color.gray.opacity(0.2) }
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(12)

                            Rectangle()
                                .foregroundColor(Color.black.opacity(0.18))
                                .cornerRadius(12)

                            Image(systemName: "play.circle.fill")
                                .resizable()
                                .frame(width: 56, height: 56)
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(video.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            } else {
                Text(error ?? "No relevant video found.")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .onAppear {
            if let cached = YouTubeCache.shared.get(query: query) {
                self.video = cached
                self.isLoading = false
            } else {
                fetchYouTubeVideo()
            }
        }
    }

    func fetchYouTubeVideo() {
        isLoading = true
        error = nil

        let apiKey = "AIzaSyD-ptyF2LEaK_9xVxHMNU5VjxobeTVhQSQ" // 🔐 Ideally load from Secrets.plist
        let searchQuery = "\(query) step-by-step recipe".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=\(searchQuery)&key=\(apiKey)"

        guard let url = URL(string: urlStr) else {
            self.error = "Invalid request."
            self.isLoading = false
            return
        }

        let start = Date()

        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                let elapsed = Date().timeIntervalSince(start)
                print("⏱ YouTube API call took \(elapsed)s")

                isLoading = false

                guard let data = data else {
                    self.error = "No data received."
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let items = json["items"] as? [[String: Any]],
                       let first = items.first,
                       let id = (first["id"] as? [String: Any])?["videoId"] as? String,
                       let snippet = first["snippet"] as? [String: Any],
                       let title = snippet["title"] as? String,
                       let thumbInfo = snippet["thumbnails"] as? [String: Any],
                       let highThumb = thumbInfo["high"] as? [String: Any],
                       let thumbURLStr = highThumb["url"] as? String,
                       let thumbURL = URL(string: thumbURLStr) {

                        let found = YouTubeVideo(id: id, title: title, thumbnailURL: thumbURL)
                        self.video = found
                        YouTubeCache.shared.set(query: query, video: found)

                    } else {
                        self.error = "No relevant video found."
                    }
                } catch {
                    self.error = "Failed to parse response."
                }
            }
        }.resume()
    }
}

// MARK: - Caching

class YouTubeCache {
    static let shared = YouTubeCache()
    private var cache: [String: YouTubeVideo] = [:]

    func get(query: String) -> YouTubeVideo? {
        cache[query.lowercased()]
    }

    func set(query: String, video: YouTubeVideo) {
        cache[query.lowercased()] = video
    }
}

// MARK: - Models & WebView

struct YouTubeVideo {
    let id: String
    let title: String
    let thumbnailURL: URL
}

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
        <style>
            html, body {
                margin: 0;
                padding: 0;
                background-color: transparent;
                overflow: hidden;
                height: 100%;
            }
            iframe {
                border: none;
                width: 100%;
                height: 100%;
            }
        </style>
        </head>
        <body>
        <iframe src="https://www.youtube.com/embed/\(videoID)?playsinline=1&autoplay=1&modestbranding=1&rel=0&showinfo=0&controls=1"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowfullscreen>
        </iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
