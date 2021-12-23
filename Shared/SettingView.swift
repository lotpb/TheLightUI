//
//  Settings.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/24/21.
//

import SwiftUI

extension TextField {
    func settingTextStyle() -> some View {
        self
            .multilineTextAlignment(.trailing)
    }
}

struct SettingsUI {
    static let firstNameKey = "firstName"
    static let lastNameKey = "lastName"
    static let emailKey = "email"
    static let phoneKey = "phone"
    static let passwordKey = "password"
    static let usernameKey = "username"
    static let websiteKey = "website"
    
    static let isCompanyNameKey = "isCompanyName"
    static let isSubscribedKey = "isSubscriber"
    static let backend = "backend"
    static let isBackfetch = "isbackfetch"
    static let isAutolockKey = "isautolock"
    
    static let color = "color"
    
    static let isSpeakKey = "isSpeak"
    static let isMusicKey = "isMusic"
    
    static let latitudeKey = "latitude"
    static let longtitudeKey = "longtitude"
    
    static let eventKey = "event"
    static let durationKey = "duration"
    
    static let areacodeKey = "areacode"
    static let emailTitleKey = "emailtitle"
    static let emailMessageKey = "emailmessage"
    static let versionKey = "version"
}

struct SettingView: View {
    @AppStorage(SettingsUI.firstNameKey) var firstName = ""
    @AppStorage(SettingsUI.lastNameKey) var lastname = ""
    @AppStorage(SettingsUI.emailKey) var email = ""
    @AppStorage(SettingsUI.phoneKey) var phone = ""
    @AppStorage(SettingsUI.passwordKey) var password = ""
    @AppStorage(SettingsUI.usernameKey) var username = ""
    @AppStorage(SettingsUI.websiteKey) var website = ""
    
    @AppStorage(SettingsUI.isCompanyNameKey) var isCompanyName = ""
    @AppStorage(SettingsUI.isSubscribedKey) var isSubscriber = false
    
    @AppStorage(SettingsUI.backend) var backend = ""
    @AppStorage(SettingsUI.isBackfetch) var isbackfetch = false
    @AppStorage(SettingsUI.isAutolockKey) var isautolock = false
    
    @AppStorage(SettingsUI.color) var color = 0
    
    @AppStorage(SettingsUI.isSpeakKey) var isSpeak = false
    @AppStorage(SettingsUI.isMusicKey) var isMusic = false
    
    @AppStorage(SettingsUI.latitudeKey) var latitude = ""
    @AppStorage(SettingsUI.longtitudeKey) var longtitude = ""
    
    @AppStorage(SettingsUI.eventKey) var event = ""
    @AppStorage(SettingsUI.durationKey) var duration = ""
    
    @AppStorage(SettingsUI.areacodeKey) var areacode = ""
    @AppStorage(SettingsUI.emailTitleKey) var emailtitle = ""
    @AppStorage(SettingsUI.emailMessageKey) var emailmessage = ""
    @AppStorage(SettingsUI.versionKey) var version = ""
    
    @State private var pickPersonal = 0
    @State private var pickGeneral = 0
    
    
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("TheLight Settings")) {
                        Picker("Personal", selection: $pickPersonal) {
                            HStack {
                                Text("First Name")
                                Spacer()
                                TextField("First Name", text: $firstName).settingTextStyle()
                            }
                            HStack {
                                Text("Last Name")
                                Spacer()
                                TextField("Last Name", text: $lastname).settingTextStyle()
                            }
                            HStack {
                                Text("Email")
                                Spacer()
                                TextField("Email", text: $email).settingTextStyle()
                            }
                            HStack {
                                Text("Phone")
                                Spacer()
                                TextField("Phone", text: $phone).settingTextStyle()
                            }
                            HStack {
                                Text("Password")
                                Spacer()
                                TextField("Password", text: $password).settingTextStyle()
                            }
                            HStack {
                                Text("Username")
                                Spacer()
                                
                                TextField("Username", text: $username).settingTextStyle()
                            }
                            HStack {
                                Text("Website")
                                Spacer()
                                TextField("Website", text: $website).settingTextStyle()
                            }
                        }
                    }
                    
                    Section(header: Text("Member Status")) {
                        HStack {
                            Text("Company")
                            Spacer()
                            
                            TextField("Username", text: $isCompanyName).settingTextStyle()
                        }
                        Toggle("isSubscriber", isOn: $isSubscriber)
                        HStack {
                            Picker("Backend Data", selection: $backend) {
                                Text("Firebase").tag("Firebase")
                                Text("Parse").tag("Parse")
                            }
                        }
                        Toggle("Background Fetch", isOn: $isbackfetch)
                        Toggle("Prevent Auto-Lock", isOn: $isautolock)
                        DisclosureGroup("Show Terms") {
                            Text("Long terms and conditions here long terms and conditions here long terms and conditions here long terms and conditions here long terms and conditions here long terms and conditions here.")
                        }
                        .frame(width: 300)
                    }
                    
                    Section(header: Text("Theme")) {
                        Picker("Color Scheme", selection: $color) {
                            Text("Purple").tag(0)
                            Text("Orange").tag(1)
                        }
                    }
                    
                    Section(header: Text("Sounds")) {
                        Toggle("Speak", isOn: $isSpeak)
                        Toggle("Music", isOn: $isMusic)
                    }
                    
                    Section(header: Text("Map")) {
                        HStack {
                            Text("Latitude")
                            Spacer()
                            TextField("Latitude", text: $latitude).settingTextStyle()
                        }
                        HStack {
                            Text("Longtitude")
                            Spacer()
                            TextField("Longtitude", text: $longtitude).settingTextStyle()
                        }
                    }
                    
                    Section(header: Text("Calender")) {
                        HStack {
                            Text("Event")
                            Spacer()
                            TextField("Event", text: $event).settingTextStyle()
                        }
                        HStack {
                            Text("Duration")
                            Spacer()
                            TextField("Duration", text: $duration).settingTextStyle()
                        }
                    }
                    
                    Section(header: Text("General")) {
                        Picker("General", selection: $pickGeneral) {
                            HStack {
                                Text("Area Code")
                                Spacer()
                                TextField("Area Code", text: $areacode).settingTextStyle()
                                
                            }
                            HStack {
                                Text("Email Title")
                                Spacer()
                                TextField("Email Title", text: $emailtitle).settingTextStyle()
                                
                            }
                            HStack {
                                Text("Email Message")
                                Spacer()
                                TextField("Email Message", text: $emailmessage).settingTextStyle()
                            }
                            HStack {
                                Text("Version")
                                Spacer()
                                TextField("Version", text: $version).settingTextStyle()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
            .preferredColorScheme(.dark)
    }
}
