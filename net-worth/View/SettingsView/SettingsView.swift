//
//  SettingsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var isAuthenticationRequired: Bool
    
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
                Toggle("Require Face ID", isOn: $isAuthenticationRequired)
                    .onChange(of: isAuthenticationRequired) { newValue in
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
            }
            .navigationTitle("Settings")
            .listStyle(.inset)
        }
    }
    
    var defaultCurrencyPicker: some View {
        Picker("Default Currency", selection: $currenySelected) {
            SearchBar(text: $searchTerm, placeholder: "Search currency")
            ForEach(filterCurrencyList, id: \.self) { (data) in
                HStack {
                    Text(data.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(data.symbol + " " + data.code)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
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
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
