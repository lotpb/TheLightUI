//
//  VideoUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/9/20.
//  Copyright © 2020 Peter Balsamo. All rights reserved.
//

import SwiftUI
import AVKit

struct VideoUI: View {
    private static let videoURL = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
    
    @State private var player: AVPlayer
    @State private var isPlaying = false
    @State private var showsControls = false
    @State private var progress: Float = 0
    
    init() {
        _player = State(initialValue: AVPlayer(url: Self.videoURL))
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    PlayerView(player: $player)
                    
                    if showsControls {
                        VideoControls(
                            player: $player,
                            isPlaying: $isPlaying,
                            showsControls: $showsControls,
                            progress: $progress
                        )
                    }
                }
                
                if showsControls {
                    Button(action: { showsControls = false }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
            .frame(height: UIScreen.main.bounds.height / 3.5)
            .onTapGesture {
                showsControls = true
            }
            
            GeometryReader { _ in
                VStack {
                    Text("Custom Video Player")
                        .foregroundColor(.white)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            player.play()
            isPlaying = true
        }
        .onDisappear {
            player.pause()
            isPlaying = false
        }
    }
}

struct VideoUI_Previews: PreviewProvider {
    static var previews: some View {
        VideoUI()
    }
}

struct VideoControls: View {
    @Binding var player: AVPlayer
    @Binding var isPlaying: Bool
    @Binding var showsControls: Bool
    @Binding var progress: Float
    
    @State private var timeObserverToken: Any?
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Button {
                    seek(to: currentSeconds - 10)
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(20)
                }
                
                Spacer()
                
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(20)
                }
                
                Spacer()
                
                Button {
                    seek(to: currentSeconds + 10)
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(20)
                }
            }
            
            Spacer()
            
            CustomProgressBar(value: $progress, player: $player, isPlaying: $isPlaying)
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .onTapGesture {
            showsControls = false
        }
        .onAppear(perform: addTimeObserver)
        .onDisappear(perform: removeTimeObserver)
    }
    
    private var durationSeconds: Double {
        let seconds = player.currentItem?.duration.seconds ?? 0
        return seconds.isFinite ? seconds : 0
    }
    
    private var currentSeconds: Double {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? seconds : 0
    }
    
    private func togglePlayback() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seek(to seconds: Double) {
        guard durationSeconds > 0 else { return }
        let clampedSeconds = min(max(seconds, 0), durationSeconds)
        player.seek(to: CMTime(seconds: clampedSeconds, preferredTimescale: 1))
    }
    
    private func addTimeObserver() {
        guard timeObserverToken == nil else { return }
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { _ in
            guard durationSeconds > 0 else { return }
            progress = Float(currentSeconds / durationSeconds)
            if progress >= 1.0 {
                isPlaying = false
            }
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}

struct CustomProgressBar: UIViewRepresentable {
    @Binding var value: Float
    @Binding var player: AVPlayer
    @Binding var isPlaying: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumTrackTintColor = .red
        slider.maximumTrackTintColor = .gray
        slider.thumbTintColor = .red
        slider.value = value
        slider.addTarget(context.coordinator, action: #selector(context.coordinator.changed(slider:)), for: .valueChanged)
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = value
    }
    
    class Coordinator: NSObject {
        var parent: CustomProgressBar
        
        init(parent: CustomProgressBar) {
            self.parent = parent
        }
        
        @objc func changed(slider: UISlider) {
            guard let duration = parent.player.currentItem?.duration.seconds, duration.isFinite else { return }
            let seconds = Double(slider.value * Float(duration))
            parent.player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
            
            if slider.isTracking {
                parent.player.pause()
            } else if parent.isPlaying {
                parent.player.play()
            }
        }
    }
}

class HostVideoUI: UIHostingController<VideoUI> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

struct PlayerView: UIViewControllerRepresentable {
    @Binding var player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resize
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

