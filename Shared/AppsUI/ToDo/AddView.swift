//
//  AddView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

struct AddView: View {
    
    @Environment(\.presentationMode) var presentatitonMode
    @EnvironmentObject var listViewModel : ListViewModel
    @State var textFieldText : String = ""
    @State var alertTitle : String = ""
    @State var showalert : Bool = false
    
    var body: some View {
        ScrollView(showsIndicators: true) {
            VStack {
                TextField("text something here...", text: $textFieldText)
                    .padding(.horizontal)
                    .frame(height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(7)
                    .padding(.bottom, 20)
                
                Button(action: saveButtonClicked, label: {
                    Text("save")
                        .foregroundColor(.white)
                            .font(.headline)
                        .frame(width: 100, height: 40, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .background(Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)))
                        .cornerRadius(10)
                })
                
            }.padding(20)
        }.navigationTitle("add an item ✎")
        .alert(isPresented: $showalert, content:getAlert)
    }
    
    func saveButtonClicked(){
        
        if textIsAppropriate(){
            listViewModel.addItem(title: textFieldText)
            presentatitonMode.wrappedValue.dismiss()
        }
    }
    
    func textIsAppropriate() -> Bool  {
        if textFieldText.count < 3  {
            alertTitle = "Need at least 3 characters🔒"
            showalert.toggle()
            return false
        }
        return true
    }
    func getAlert() -> Alert {
        return Alert(title: Text(alertTitle))
    }
}

struct AddView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddView()
        }.environmentObject(ListViewModel())
    }
}
