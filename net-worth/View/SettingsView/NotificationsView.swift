//
//  NotificationsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 24/11/22.
//

import SwiftUI

struct NotificationsView: View {
    
    @State private var mutualFundNotification: Bool = false
    @State private var equityNotification: Bool = false
    @State private var etfNotification: Bool = false
    @State private var cryptoCurrencyNotification: Bool = false
    @State private var futureNotification: Bool = false
    @State private var optionNotification: Bool = false
    @State private var creditCardNotification: Bool = false
    @State private var loanNotification: Bool = false
    @State private var otherNotification: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    private var notificationController = NotificationController()
//    init() {
//        mutualFundNotification = notificationController.isNotificationEnabled(accountType: "MUTUALFUND")
//        equityNotification = notificationController.isNotificationEnabled(accountType: "EQUITY")
//        etfNotification = notificationController.isNotificationEnabled(accountType: "ETF")
//        cryptoCurrencyNotification = notificationController.isNotificationEnabled(accountType: "CRYPTOCURRENCY")
//        futureNotification = notificationController.isNotificationEnabled(accountType: "FUTURE")
//        optionNotification = notificationController.isNotificationEnabled(accountType: "OPTION")
//        creditCardNotification = notificationController.isNotificationEnabled(accountType: "Credit Card")
//        loanNotification = notificationController.isNotificationEnabled(accountType: "Loan")
//        otherNotification = notificationController.isNotificationEnabled(accountType: "Other")
//    }
    
    var body: some View {
        VStack {
            List {
                Section("Mutual Fund Notifications") {
                    Toggle("Show Notifications", isOn: $mutualFundNotification)
                        .onChange(of: mutualFundNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "MUTUALFUND")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Equity Notifications") {
                    Toggle("Show Notifications", isOn: $equityNotification)
                        .onChange(of: equityNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("ETF Notifications") {
                    Toggle("Show Notifications", isOn: $etfNotification)
                        .onChange(of: etfNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "ETF")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Cryptocurrency Notifications") {
                    Toggle("Show Notifications", isOn: $cryptoCurrencyNotification)
                        .onChange(of: cryptoCurrencyNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Futures Notifications") {
                    Toggle("Show Notifications", isOn: $futureNotification)
                        .onChange(of: futureNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Options Notifications") {
                    Toggle("Show Notifications", isOn: $optionNotification)
                        .onChange(of: optionNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "OPTION")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Credit Card Notifications") {
                    Toggle("Show Notifications", isOn: $creditCardNotification)
                        .onChange(of: creditCardNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Credit Card")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Loan Notifications") {
                    Toggle("Show Notifications", isOn: $loanNotification)
                        .onChange(of: loanNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Loan")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
                
                Section("Other Notifications") {
                    Toggle("Show Notifications", isOn: $otherNotification)
                        .onChange(of: otherNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Other")
                        }
                        .foregroundColor(Color.navyBlue)
                }
                .listRowBackground(Color.white)
                .foregroundColor(Color.lightBlue)
            }
            .navigationTitle("Notifications")
            .listStyle(.insetGrouped)
            .background(Color.navyBlue)
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.lightBlue)
                        .bold()
                }
                    .font(.system(size: 14).bold())
            )
        }
    }
}
