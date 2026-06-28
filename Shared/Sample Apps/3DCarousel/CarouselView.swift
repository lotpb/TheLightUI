//
//  CarouselView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

@available(iOS 18.0, *)
struct CarouselView: View {

    @State private var currentTab = CarouselPage.pages.first?.id ?? "p1"
    
    private let pages = CarouselPage.pages
    
    private var currentPage: CarouselPage {
        pages.first { $0.id == currentTab } ?? pages[0]
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Image(currentPage.resolvedImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .overlay(.ultraThinMaterial)
            .colorScheme(.dark)
            
            TabView(selection: $currentTab) {
                ForEach(pages) { page in
                    CarouselBodyView(page: page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}

@available(iOS 18.0, *)
struct CarouselPage: Identifiable {
    let id: String
    let imageName: String
    let title: String
    let subtitle: String
    let profileName: String
    let profileSubtitle: String
    let stats: [CarouselStat]
    
    var resolvedImageName: String {
        UIImage(named: imageName) == nil ? Self.fallbackImageName : imageName
    }
    
    static let fallbackImageName = "taylor_swift_profile"
    
    static let pages = [
        CarouselPage(
            id: "p1",
            imageName: "p1",
            title: "Human Integration Supervisor",
            subtitle: "A compact profile card with carousel depth and motion.",
            profileName: "Peter",
            profileSubtitle: "Apple Sheep",
            stats: Self.defaultStats
        ),
        CarouselPage(
            id: "p2",
            imageName: "p2",
            title: "Creative Systems Lead",
            subtitle: "Swipe through featured cards with a soft glass backdrop.",
            profileName: "Peter",
            profileSubtitle: "Design Lab",
            stats: Self.defaultStats
        ),
        CarouselPage(
            id: "p3",
            imageName: "p3",
            title: "Product Strategy Partner",
            subtitle: "A focused presentation surface for people and work highlights.",
            profileName: "Peter",
            profileSubtitle: "Studio Desk",
            stats: Self.defaultStats
        ),
        CarouselPage(
            id: "p4",
            imageName: "p4",
            title: "Experience Builder",
            subtitle: "Layered imagery, stats, and profile context in one card.",
            profileName: "Peter",
            profileSubtitle: "TheLight UI",
            stats: Self.defaultStats
        )
    ]
    
    private static let defaultStats = [
        CarouselStat(value: "1303", label: "Posts"),
        CarouselStat(value: "3103", label: "Followers"),
        CarouselStat(value: "1603", label: "Following")
    ]
}

@available(iOS 18.0, *)
struct CarouselStat: Identifiable {
    let id = UUID()
    let value: String
    let label: String
}

@available(iOS 18.0, *)
#Preview("Carousel - Dark") {
    CarouselView()
        .preferredColorScheme(.dark)
}
