import SwiftUI
import Foundation

struct InstagramStory {
    let handle: String
    let imageName: String
    let isLive: Bool
    let imageURL: URL?
}

struct StoryImageView: View {
    let story: InstagramStory
    
    var body: some View {
        if let url = story.imageURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Image(story.imageName)
                        .resizable()
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(story.imageName)
                        .resizable()
                        .scaledToFill()
                @unknown default:
                    Image(story.imageName)
                        .resizable()
                        .scaledToFill()
                }
            }
        } else {
            Image(story.imageName)
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview {
    let sample = InstagramStory(
        handle: "Your story",
        imageName: "taylor_swift_profile",
        isLive: true,
        imageURL: URL(string: "https://example.com/sample.jpg")
    )
    StoryImageView(story: sample)
}
