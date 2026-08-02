//
//  WaveUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 6/13/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct WaveUI: View {
    @State private var isAlternateColorEnabled = false

    var body: some View {
        ZStack(alignment: .top) {
            waveLayers
            header
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var waveLayers: some View {
        ZStack {
            WaveFormUI(color: .purple.opacity(0.8), amplitude: 150, isReversed: false)
            WaveFormUI(
                color: (isAlternateColorEnabled ? Color.purple : Color.cyan).opacity(0.6),
                amplitude: 140,
                isReversed: true
            )
        }
    }

    private var header: some View {
        HStack {
            Text("Wave's")
                .font(.largeTitle.bold())

            Spacer()

            Toggle(isOn: $isAlternateColorEnabled) {
                Image(systemName: "eyedropper.halffull")
                    .font(.title2)
            }
            .toggleStyle(.button)
            .tint(.purple)
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct WaveFormUI: View {
    private let color: Color
    private let amplitude: CGFloat
    private let isReversed: Bool
    private let animationCycleDuration: TimeInterval = 2

    init(color: Color, amplitude: CGFloat, isReversed: Bool) {
        self.color = color
        self.amplitude = amplitude
        self.isReversed = isReversed
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                var context = context
                drawWave(in: &context, size: size, date: timeline.date)
            }
        }
    }

    private func drawWave(in context: inout GraphicsContext, size: CGSize, date: Date) {
        let cycleProgress = date.timeIntervalSinceReferenceDate.remainder(dividingBy: animationCycleDuration)
        let offset = cycleProgress * size.width
        let direction = isReversed ? -1.0 : 1.0
        let path = wavePath(size: size)

        context.translateBy(x: direction * offset, y: 0)
        context.fill(path, with: .color(color))

        context.translateBy(x: -size.width, y: 0)
        context.fill(path, with: .color(color))

        context.translateBy(x: size.width * 2, y: 0)
        context.fill(path, with: .color(color))
    }

    private func wavePath(size: CGSize) -> Path {
        Path { path in
            let midHeight = size.height / 2
            let width = size.width

            path.move(to: CGPoint(x: 0, y: midHeight))
            path.addCurve(
                to: CGPoint(x: width, y: midHeight),
                control1: CGPoint(x: width * 0.4, y: midHeight + amplitude),
                control2: CGPoint(x: width * 0.65, y: midHeight - amplitude)
            )
            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
        }
    }
}

struct WaveUI_Previews: PreviewProvider {
    static var previews: some View {
        WaveUI()
    }
}
