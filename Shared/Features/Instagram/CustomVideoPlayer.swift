//
//  CustomVideoPlayer.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import AVKit
import SwiftUI

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let showsPlaybackControls: Bool
    let videoGravity: AVLayerVideoGravity
    let loops: Bool

    init(
        player: AVPlayer,
        showsPlaybackControls: Bool = false,
        videoGravity: AVLayerVideoGravity = .resizeAspectFill,
        loops: Bool = true
    ) {
        self.player = player
        self.showsPlaybackControls = showsPlaybackControls
        self.videoGravity = videoGravity
        self.loops = loops
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(player: player, loops: loops)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        configure(controller)
        context.coordinator.startObserving()
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        configure(controller)
        context.coordinator.updatePlayer(player, loops: loops)
    }

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        controller.player?.pause()
        controller.player = nil
        coordinator.stopObserving()
    }

    private func configure(_ controller: AVPlayerViewController) {
        if controller.player !== player {
            controller.player = player
        }

        controller.showsPlaybackControls = showsPlaybackControls
        controller.videoGravity = videoGravity
        player.actionAtItemEnd = loops ? .none : .pause
    }

    /// Marked `@unchecked Sendable` because the coordinator is only ever used on
    /// the main thread: SwiftUI creates and drives it there, and its KVO / end-of-
    /// playback observers hop back before mutating state.
    final class Coordinator: NSObject, @unchecked Sendable {
        private var player: AVPlayer
        private var loops: Bool
        private var endPlaybackObserver: NSObjectProtocol?
        private var currentItemObserver: NSKeyValueObservation?

        init(player: AVPlayer, loops: Bool) {
            self.player = player
            self.loops = loops
            super.init()
        }

        deinit {
            stopObserving()
        }

        func updatePlayer(_ player: AVPlayer, loops: Bool) {
            guard self.player !== player || self.loops != loops else { return }

            stopObserving()
            self.player = player
            self.loops = loops
            self.player.actionAtItemEnd = loops ? .none : .pause
            startObserving()
        }

        func startObserving() {
            guard currentItemObserver == nil else {
                observeCurrentItem()
                return
            }

            observeCurrentItem()
            currentItemObserver = player.observe(\.currentItem, options: [.new]) { [weak self] _, _ in
                self?.observeCurrentItem()
            }
        }

        func stopObserving() {
            stopObservingEndPlayback()
            currentItemObserver = nil
        }

        private func observeCurrentItem() {
            stopObservingEndPlayback()

            guard loops, let currentItem = player.currentItem else { return }

            endPlaybackObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: currentItem,
                queue: .main
            ) { [weak self] _ in
                self?.restartPlayback()
            }
        }

        private func stopObservingEndPlayback() {
            guard let endPlaybackObserver else { return }

            NotificationCenter.default.removeObserver(endPlaybackObserver)
            self.endPlaybackObserver = nil
        }

        private func restartPlayback() {
            player.seek(to: .zero)
            player.play()
        }
    }
}
