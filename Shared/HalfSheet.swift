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
        
        HSheet()
    }
}

@available(iOS 15.0, *)
struct HalfSheet_Previews: PreviewProvider {
    static var previews: some View {
        HalfSheet()
    }
}

@available(iOS 15.0, *)
struct HSheet: View {
    
    @State var showSheet: Bool = false
    
    var body: some View {
        
        NavigationView {
            Button {
                showSheet.toggle()
            } label: {
                
                Text("Present Sheet")
            }
            .navigationTitle("half Modal Sheet")
            .halfsheet(showSheet: $showSheet) {
                
                ZStack {
                    
                    Color.red
                    
                    VStack {
                        Text("hello iJustine")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Button {
                            showSheet.toggle()
                        } label: {
                            
                            Text("Close From Sheet")
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
                .ignoresSafeArea()
            } onEnd: {
                print("Dismissed")
            }
        }
    }
}

@available(iOS 15.0, *)
extension View {
    
    func halfsheet<SheetView: View>(showSheet: Binding<Bool>,@ViewBuilder sheetView: @escaping ()->SheetView, onEnd: @escaping ()->())->some View {
        
        return self
            .background(
                HalfSheetHelper(sheetView: sheetView(), showSheet: showSheet, onEnd: onEnd)
            )
    }
}

@available(iOS 15.0, *)
struct HalfSheetHelper<SheetView: View>: UIViewControllerRepresentable {
    
    var sheetView: SheetView
    @Binding var showSheet: Bool
    var onEnd: ()->()
    
    let controller = UIViewController()
    
    func makeCoordinator() -> Coordinator {
        
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        
        controller.view.backgroundColor = .clear
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
        if showSheet {
            
            let sheetController = CustomHostingController(rootView: sheetView)
            sheetController.presentationController?.delegate = context.coordinator
            uiViewController.present(sheetController, animated: true)
            
        }
        else {
            uiViewController.dismiss(animated: true)
        }
    }
    
    class Coordinator: NSObject,UISheetPresentationControllerDelegate {
        
        var parent: HalfSheetHelper
        
        init(parent: HalfSheetHelper) {
            self.parent = parent
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            
            parent.showSheet = false
            parent.onEnd()
        }
    }
}

@available(iOS 15.0, *)
class CustomHostingController<Content: View>: UIHostingController<Content> {
    
    override func viewDidLoad() {
        
        view.backgroundColor = .clear
        
        if let presentationController = presentationController as? UISheetPresentationController {
            
            presentationController.detents = [
                .medium(),
                .large()
            ]
            
            presentationController.prefersGrabberVisible = true
        }
    }
}
