//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import Firebase

struct SettingsView: View {
    
    @State private var isAuthenticationRequired: Bool
    @State private var logout =  false
    
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
                
                let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                Text("Version " + appVersion!)
                
                Button(action: {
                    logoutUser()
                }, label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                })
            }
            .navigationTitle("Settings")
            .listStyle(.grouped)
        }
        .fullScreenCover(isPresented: $logout, content: {
            LoginScreen()
        })
    }
    
    var defaultCurrencyPicker: some View {
        Picker("Default Currency", selection: $currenySelected) {
            SearchBar(text: $searchTerm, placeholder: "Search currency")
            ForEach(filterCurrencyList, id: \.self) { (data) in
                defaultCurrencyPickerRightVersionView(currency: data)
                .tag(data)
            }
        }
        .edgesIgnoringSafeArea(.all)
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
        logout = true
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
