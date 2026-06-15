//
//  HalfSheet.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 7/10/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct HalfSheet: View {
    var body: some View {
        HalfSheetDemoView()
    }
}

@available(iOS 15.0, *)
struct HalfSheet_Previews: PreviewProvider {
    static var previews: some View {
        HalfSheet()
    }
}

@available(iOS 15.0, *)
private struct HalfSheetDemoView: View {
    @State private var showSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "rectangle.bottomthird.inset.filled")
                    .font(.system(size: 54))
                    .foregroundColor(.accentColor)

                Text("Present a UIKit-backed half sheet with medium and large detents.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Button {
                    showSheet = true
                } label: {
                    Text("Present Sheet")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Half Modal Sheet")
            .halfSheet(showSheet: $showSheet) {
                SheetSampleContent {
                    showSheet = false
                }
            } onDismiss: {
                showSheet = false
            }
        }
    }
}

@available(iOS 15.0, *)
private struct SheetSampleContent: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.red, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Text("Hello iJustine")
                    .font(.title.bold())
                    .foregroundColor(.white)

                Button {
                    onClose()
                } label: {
                    Text("Close Sheet")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
        }
        .ignoresSafeArea()
    }
}

@available(iOS 15.0, *)
extension View {
    func halfSheet<SheetView: View>(
        showSheet: Binding<Bool>,
        @ViewBuilder sheetView: @escaping () -> SheetView,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        background(
            HalfSheetPresenter(
                sheetView: sheetView(),
                showSheet: showSheet,
                onDismiss: onDismiss
            )
        )
    }
}

@available(iOS 15.0, *)
private struct HalfSheetPresenter<SheetView: View>: UIViewControllerRepresentable {
    let sheetView: SheetView
    @Binding var showSheet: Bool
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.parent = self

        if showSheet {
            if let sheetController = uiViewController.presentedViewController as? HalfSheetHostingController<SheetView> {
                sheetController.rootView = sheetView
                return
            }

            guard uiViewController.presentedViewController == nil else { return }

            let sheetController = HalfSheetHostingController(rootView: sheetView)
            sheetController.presentationController?.delegate = context.coordinator
            uiViewController.present(sheetController, animated: true)
        } else if uiViewController.presentedViewController != nil {
            uiViewController.dismiss(animated: true)
        }
    }

    final class Coordinator: NSObject, UISheetPresentationControllerDelegate {
        var parent: HalfSheetPresenter

        init(parent: HalfSheetPresenter) {
            self.parent = parent
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            parent.showSheet = false
            parent.onDismiss()
        }
    }
}

@available(iOS 15.0, *)
private final class HalfSheetHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        if let presentationController = presentationController as? UISheetPresentationController {
            presentationController.detents = [.medium(), .large()]
            presentationController.prefersGrabberVisible = true
            presentationController.preferredCornerRadius = 24
        }
    }
}
