//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct SettingsView: View {
    
    @State private var profilePhoto = UIImage()
    @State private var isAuthenticationRequired: Bool
    @State private var logout =  false
    @State private var isPresentingDataAndAccountDeletionConfirmation = false
    @State private var isPresentingLogoutConfirm = false
    
    @State private var currenySelected: Currency
    @State private var searchTerm: String = ""
    
    private var currencyList = CurrencyList().currencyList
    
    @State private var filterCurrencyList = CurrencyList().currencyList
    
    private var settingsController = SettingsController()
    private var notificationController = NotificationController()
    
    init() {
        isAuthenticationRequired = settingsController.isAuthenticationRequired()
        currenySelected = settingsController.getDefaultCurrency()
    }
    
    var body: some View {
        NavigationView(){
            List{
                Section() {
                    VStack() {
                        Image(uiImage: profilePhoto)
                            .clipShape(Circle())
                            .shadow(color: Color.navyBlue, radius: 3)
                            .frame(width: 100, height: 100)
                        
                        Text(Auth.auth().currentUser?.displayName ?? "")
                            .font(.system(size: 25))
                            .bold()
                            .foregroundColor(Color.lightBlue)
                        Text(Auth.auth().currentUser?.email ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(Color.lightBlue)
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 180)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                Toggle(isOn: $isAuthenticationRequired, label: {
                    Label("Require Face ID", systemImage: "faceid")
                }).onChange(of: isAuthenticationRequired) { newValue in
                    settingsController.setAuthentication(newValue: newValue)
                }
                .foregroundColor(Color.navyBlue)
                .listRowBackground(Color.white)
                
                NavigationLink(destination: {
                    NotificationsView()
                }, label: {
                    Label("Notifications", systemImage: "play.square")
                })
                .foregroundColor(Color.navyBlue)
                .listRowBackground(Color.white)
                
                defaultCurrencyPicker
                    .colorMultiply(Color.navyBlue)
                    .listRowBackground(Color.white)
                
                NavigationLink(destination: {
                    IncomeTypeView()
                }, label: {
                    Label("Income Type", systemImage: "tray.and.arrow.down")
                })
                .foregroundColor(Color.navyBlue)
                .listRowBackground(Color.white)
                
                NavigationLink(destination: {
                    IncomeTagView()
                }, label: {
                    Label("Income Tag", systemImage: "tag.square")
                })
                .foregroundColor(Color.navyBlue)
                .listRowBackground(Color.white)
                
                NavigationLink(destination: {
                    BackupView()
                }, label: {
                    Label("Backup", systemImage: "folder")
                })
                .foregroundColor(Color.navyBlue)
                .listRowBackground(Color.white)
                
                Button(action: {
                    isPresentingDataAndAccountDeletionConfirmation.toggle()
                }, label: {
                    Label("Delete Account & Data", systemImage: "xmark.bin")
                }).confirmationDialog("Are you sure?",
                                      isPresented: $isPresentingDataAndAccountDeletionConfirmation) {
                    Button("Delete all data and account?", role: .destructive) {
                        Task.init {
                            await deleteAccountAndData()
                        }
                    }
                }.foregroundColor(.red)
                    .listRowBackground(Color.white)
                
                Button(action: {
                    isPresentingLogoutConfirm.toggle()
                }, label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }).confirmationDialog("Are you sure?",
                                      isPresented: $isPresentingLogoutConfirm) {
                    Button("Logout?", role: .destructive) {
                        logoutUser()
                    }
                }
                                      .foregroundColor(Color.navyBlue)
                                      .listRowBackground(Color.white)
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
                Label("Version " + (appVersion ?? "") + " Build(" + (buildVersion ?? "Unknown Build Version)") + ")", systemImage: "gear.badge.checkmark")
                    .foregroundColor(Color.navyBlue)
                    .listRowBackground(Color.white)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
            .foregroundColor(Color.lightBlue)
        }
        .onAppear {
            Task.init {
                profilePhoto = await fetchProfilePhoto()
            }
        }
        .fullScreenCover(isPresented: $logout, content: {
            LoginScreen()
        })
    }
    
    func fetchProfilePhoto() async -> UIImage {
        do {
            let (data, _) = try await URLSession.shared.data(from: (Auth.auth().currentUser?.photoURL)!)
            if let image = UIImage(data: data) {
                return image
            }
        } catch {
            print(error)
        }
        return UIImage()
    }
    
    var defaultCurrencyPicker: some View {
        Picker(selection: $currenySelected, content: {
            SearchBar(text: $searchTerm, placeholder: "Search currency")
            ForEach(filterCurrencyList, id: \.self) { (data) in
                defaultCurrencyPickerRightVersionView(currency: data)
                    .tag(data)
            }
        }, label: {
            Label("", systemImage: "indianrupeesign.square")
        })
        .onChange(of: searchTerm) { (data) in
            if(!data.isEmpty) {
                filterCurrencyList = currencyList.filter({
                    $0.name.lowercased().contains(searchTerm.lowercased()) || $0.symbol.lowercased().contains(searchTerm.lowercased()) || $0.code.lowercased().contains(searchTerm.lowercased())
                })
            } else {
                filterCurrencyList = currencyList
            }
        }
        .onChange(of: currenySelected) { (data) in
            settingsController.setDefaultCurrency(newValue: data)
        }
        .pickerStyle(.navigationLink)
    }
    
    func logoutUser() {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        settingsController.setAuthentication(newValue: false)
    }
    
    func deleteAccountAndData() async {
        await UserController().deleteUser()
        logoutUser()
    }
}

struct defaultCurrencyPickerRightVersionView: View {
    
    var currency: Currency
    
    var body: some View {
        HStack {
            Text(currency.name)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(currency.symbol + " " + currency.code)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
