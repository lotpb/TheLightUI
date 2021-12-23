//
//  MainMenuUI.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/10/21.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

@available(iOS 16.0, *)
@MainActor
struct MainMenuUI: View {
    
    @AppStorage("color") var color: Int?
    
    private var menuItems1 = ["Snapshot","Statistics"]
    //private var menuItems3 = ["Geotify","Search Places","Music","YouTube","Contacts","Spot Beacon","Transmit Beacon", "Show Detail"]
    
    ///logout
    @State var isUserCurrentlyLoggedOut = false
    @State var showingLogOut = false
    
    ///fullSheet
    @State private var isshowStacks = false
    @State private var isshowPlaces = false
    @State private var isshowWeather = false
    @State private var isshowYouTube = false
    @State private var isshowContacts = false
    
    ///actionSheet
    enum SheetContent {
        case first, second, third, forth, fifth
    }
    @State private var isShowActionsheet = false
    @State private var actionSheetContent: SheetContent = .first
    @State private var showActionSheet = false
    
    @State var showEmailComposer = false
    
    
    var body: some View {
        NavigationView {
            VStack {
                
                MainTopView().padding(.top, 25)
                
                List {
                    Section(header: Text("Incoming").foregroundColor(self.color == 0 ? Color.purple : Color.orange)) {
                        ForEach(menuItems1, id: \.self) { message in
                            Label(message, systemImage: "message").badge("NEW ITEMS!")
                                .listItemTint(self.color == 0 ? Color.purple : Color.orange)
                        }
                    }
                    
                    Section(header: Text("Data").foregroundColor(self.color == 0 ? Color.purple : Color.orange)) {
                        NavigationLink("Leads", destination: CustomerUI(viewModel: CustomerData()))
                        NavigationLink("Customers", destination: CustomerUI(viewModel: CustomerData())).navigationTitle("")
                        NavigationLink("Vendors", destination: CustomerUI(viewModel: CustomerData()))
                        NavigationLink("Employee", destination: CustomerUI(viewModel: CustomerData()))
                        NavigationLink("To Do", destination: ListView())
                    }
                    
                    Section(header: Text("Outgoing").foregroundColor(self.color == 0 ? Color.purple : Color.orange)) {
                        
                        Button("Geotify") {
                            isshowStacks = true
                        }
                        Button("Search Places") {
                            isshowPlaces = true
                        }
                        Button("Weather") {
                            isshowWeather = true
                        }
                        Button("Stacks") {
                            isshowYouTube = true
                        }
                        Button("Contacts") {
                            isshowContacts = true
                        }
                    }
                    .foregroundColor(.primary)
                }
                .listStyle(.insetGrouped)
                .fullScreenCover(isPresented: $isshowStacks, onDismiss: nil) {
                    MapUI(travelTime: 0.00, distance: 0.00)
                }
                .fullScreenCover(isPresented: $isshowPlaces, onDismiss: nil) {
                    PlaceSearch( index: 1)
                }
                .fullScreenCover(isPresented: $isshowWeather, onDismiss: nil) {
                    WeatherUI()
                }
                .fullScreenCover(isPresented: $isshowYouTube, onDismiss: nil) {
                    StacksView()
                }
                .fullScreenCover(isPresented: $isshowContacts, onDismiss: nil) {
                    ChartView()
                }
                .onAppear() {
                    
                }
            }
            .navigationTitle("Main Menu")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowActionsheet.toggle()
                    }) {
                        Label("Action", systemImage: "square.and.arrow.up")
                    }
                    .actionSheet(isPresented: $isShowActionsheet, content: {
                        let action1 = ActionSheet.Button.default(Text("Email Support")) {
                            actionSheetContent = .first; showEmailComposer = true //showActionSheet = true
                        }
                        let action2 = ActionSheet.Button.default(Text("Settings")) {
                            actionSheetContent = .second; showActionSheet = true
                        }
                        let action3 = ActionSheet.Button.default(Text("Directions")) {
                            actionSheetContent = .third; showActionSheet = true
                        }
                        let action4 = ActionSheet.Button.default(Text("Users")) {
                            actionSheetContent = .forth; showActionSheet = true
                        }
                        let action5 = ActionSheet.Button.default(Text("Membership Card")) {
                            actionSheetContent = .fifth; showActionSheet = true
                        }
                        let action6 = Alert.Button
                            .cancel()
                        
                        return ActionSheet(title: Text("Pick a menu item"), buttons: [action1, action2, action3, action4, action5, action6])
                    })
                    .sheet(isPresented: $showActionSheet, onDismiss: nil) {
                        switch actionSheetContent {
                        case .first: SettingView()
                        case .second: SettingView()
                        case .third: DirectionsUI()
                        case .forth: UserFormUI()
                        case .fifth: MembershipUI()
                        }
                    }
                    .sheet(isPresented: $showEmailComposer) {
                                MailView(
                                    subject: "Email support",
                                    message: "Message",
                                    attachment: nil,
                                    onResult: { _ in
                                         // Handle the result if needed.
                                         self.showEmailComposer = false
                                    }
                                )
                            }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingLogOut.toggle()
                    } label: {
                        Text("Sign Out").fontWeight(.bold)
                            .font(.footnote)
                    }
                }
            }
            .actionSheet(isPresented: $showingLogOut) {
                .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                    .destructive(Text("Sign Out"), action: {
                        print("handle sign out")
                        handleSignOut()
                    }),
                    .cancel()
                ])
            }
            .fullScreenCover(isPresented: $isUserCurrentlyLoggedOut, onDismiss: nil) {
                LoginView(didCompleteLoginProcess: {
                    self.isUserCurrentlyLoggedOut = false
                })
            }
            
        }
        .accentColor(self.color == 0 ? Color.purple : Color.orange)
    }
    
    func openSetting() {
        //SettingsUI()
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        HapticManager.notification(type: .success)
        //try? FirebaseManager.shared.auth.signOut()
    }
}

@available(iOS 16.0, *)
struct MainMenuUI_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainMenuUI().preferredColorScheme(.dark)
        }
    }
}

struct MainTopView: View {
    @AppStorage("color") var color: Int?
    @AppStorage(SettingsUI.isCompanyNameKey) var companyName: String = "Main Menu"
    @AppStorage(SettingsUI.backend) var backEnd: String = "None"
    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text(companyName).font(.system(size: 32, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .padding(.top, 15)
                    .padding(.leading, 15)
            }
            
            Divider()
            
            HStack {
                Text("Backend:")
                Spacer()
                Text(backEnd)
                Image(systemName: "circle.hexagongrid.fill")
                    .font(.callout).imageScale(.large)
            }
            .font(.footnote.bold())
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                Text("Weather:")
                Spacer()
                    
                Text("Cloudy")
                    //.baselineOffset(-6)
                Image(systemName: "cloud.sun.fill")
                    .font(.callout).imageScale(.large)
            }
            .font(.footnote.bold())
            .padding(.horizontal).padding(.bottom, 15)
        }
        .symbolRenderingMode(.multicolor)
        .foregroundColor(Color.white)
        .background(self.color == 0 ? Color.purple : Color.orange).cornerRadius(10)
        .frame(height: 115, alignment: .leading)
        .padding()
    }
}

