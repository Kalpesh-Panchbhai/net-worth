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
                            .shadow(color: .white, radius: 3)
                            .frame(width: 100, height: 100)
                        
                        Text(Auth.auth().currentUser?.displayName ?? "")
                            .font(.system(size: 25))
                            .bold()
                        Text(Auth.auth().currentUser?.email ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(Color.gray)
                        
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
                NavigationLink(destination: {
                    NotificationsView()
                }, label: {
                    Label("Notifications", systemImage: "play.square")
                })
                
                defaultCurrencyPicker
                
                NavigationLink(destination: {
                    IncomeTypeView()
                }, label: {
                    Label("Income Type", systemImage: "tray.and.arrow.down")
                })
                
                NavigationLink(destination: {
                    IncomeTagView()
                }, label: {
                    Label("Income Tag", systemImage: "tag.square")
                })
                
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
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                Label("Version " + (appVersion ?? ""), systemImage: "gear.badge.checkmark")
            }
            .navigationTitle("Settings")
            .listStyle(.insetGrouped)
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
        Picker("Default Currency", selection: $currenySelected) {
            SearchBar(text: $searchTerm, placeholder: "Search currency")
            ForEach(filterCurrencyList, id: \.self) { (data) in
                defaultCurrencyPickerRightVersionView(currency: data)
                    .tag(data)
            }
        }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
