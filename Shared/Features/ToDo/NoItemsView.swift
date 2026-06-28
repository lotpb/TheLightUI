//
//  NoItemsView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//
import SwiftUI

struct NoItemsView: View {
    
    @State private var animate = false
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack(spacing: 10) {
                Text("there are no items")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("maybe you should add a bunch of items")
                    .padding(.bottom, 15)
                NavigationLink {
                    AddView()
                } label: {
                    Text("Add Something")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(animate ? Color.purple : Color.orange)
                        .cornerRadius(15)
                }
                .padding(.horizontal, animate ? 30 : 50)
                .shadow(
                    color: animate ? Color.purple.opacity(0.7) : Color.orange.opacity(0.7),
                    radius: animate ? 30 : 10,
                    x: 0,
                    y: animate ? 25 : 10
                )
                .scaleEffect(animate ? 1.1 : 1.3)
                .offset(y: animate ? 6 : 0)
            }
            .frame(maxWidth: 400)
            .multilineTextAlignment(.center)
            .padding(30)
            .onAppear(perform: addAnimation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func addAnimation() {
        guard !animate else { return }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(
                Animation
                    .easeInOut(duration: 2.0)
                    .repeatForever()
            ) {
                animate.toggle()
            }
        }
    }
}

struct NoItemsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoItemsView()
                .navigationTitle("No Item")
        }
    }
}

