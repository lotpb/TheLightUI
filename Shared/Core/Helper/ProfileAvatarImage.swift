import SwiftUI
import SDWebImageSwiftUI

struct ProfileAvatarImage: View {
    let urlString: String?
    let fallbackImageName: String

    init(urlString: String?, fallbackImageName: String = "taylor_swift_profile") {
        self.urlString = urlString
        self.fallbackImageName = fallbackImageName
    }

    var body: some View {
        if let imageURL {
            WebImage(url: imageURL)
                .placeholder {
                    fallbackImage
                }
                .resizable()
                .scaledToFill()
        } else {
            fallbackImage
        }
    }

    private var imageURL: URL? {
        guard let urlString else { return nil }

        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURLString.isEmpty else { return nil }

        return URL(string: trimmedURLString)
    }

    private var fallbackImage: some View {
        Image(fallbackImageName)
            .resizable()
            .scaledToFill()
    }
}
