//
//  ContactRow.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/21/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

//import SwiftUI
//
//struct ContactRow: View {
//    let contact: Contact
//    
//    var body: some View {
//        HStack {
//            Image(contact.imageName)
//                .resizable()
//                .clipShape(Circle())
//                .frame(width: 60, height: 60)
//                .clipped()
//            
//            VStack(alignment: .leading) {
//                Text("\(contact.firstName) \(contact.lastName)").font(.headline)
//                Text(contact.city).font(.subheadline)
//            }
//            
//            Spacer()
//            
//            if contact.isFavorite {
//                Image(systemName: "star.fill")
//                    .font(.headline)
//                    .foregroundColor(.yellow)
//            }
//        }
//    }
//}
