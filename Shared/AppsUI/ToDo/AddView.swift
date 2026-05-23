//
//  AddView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

struct AddView: View {
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listViewModel: ListViewModel
    @State private var textFieldText = ""
    @State private var alertTitle = ""
    @State private var showAlert = false
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack {
                TextField("text something here...", text: $textFieldText)
                    .padding(.horizontal)
                    .frame(height: 50, alignment: .center)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(7)
                    .padding(.bottom, 20)
                
                Button {
                    saveButtonClicked()
                } label: {
                    Text("save")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(width: 100, height: 40, alignment: .center)
                        .background(Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)))
                        .cornerRadius(10)
                }
                
            }
            .padding(20)
        }
        .navigationTitle("add an item ✎")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func saveButtonClicked() {
        if textIsAppropriate() {
            listViewModel.addItem(title: textFieldText)
            dismiss()
        }
    }
    
    private func textIsAppropriate() -> Bool {
        if textFieldText.count < 3 {
            alertTitle = "Need at least 3 characters🔒"
            showAlert = true
            return false
        }
        return true
    }
}

struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddView()
        }
        .environmentObject(ListViewModel())
    }
}
