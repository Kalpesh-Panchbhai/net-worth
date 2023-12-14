//
//  NotificationsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 24/11/22.
//

import SwiftUI

struct NotificationsView: View {
    
    var notificationController = NotificationController()
    
    @State var mutualFundNotification: Bool = false
    @State var equityNotification: Bool = false
    @State var etfNotification: Bool = false
    @State var cryptoCurrencyNotification: Bool = false
    @State var futureNotification: Bool = false
    @State var optionNotification: Bool = false
    @State var creditCardNotification: Bool = false
    @State var loanNotification: Bool = false
    @State var otherNotification: Bool = false
    
    @Environment(\.presentationMode) var presentationMode
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
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Equity Notifications") {
                    Toggle("Show Notifications", isOn: $equityNotification)
                        .onChange(of: equityNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("ETF Notifications") {
                    Toggle("Show Notifications", isOn: $etfNotification)
                        .onChange(of: etfNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "ETF")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Cryptocurrency Notifications") {
                    Toggle("Show Notifications", isOn: $cryptoCurrencyNotification)
                        .onChange(of: cryptoCurrencyNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Futures Notifications") {
                    Toggle("Show Notifications", isOn: $futureNotification)
                        .onChange(of: futureNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Options Notifications") {
                    Toggle("Show Notifications", isOn: $optionNotification)
                        .onChange(of: optionNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "OPTION")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Credit Card Notifications") {
                    Toggle("Show Notifications", isOn: $creditCardNotification)
                        .onChange(of: creditCardNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Credit Card")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Loan Notifications") {
                    Toggle("Show Notifications", isOn: $loanNotification)
                        .onChange(of: loanNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Loan")
                        }
                }
                .listRowBackground(Color.theme.foreground)
                
                Section("Other Notifications") {
                    Toggle("Show Notifications", isOn: $otherNotification)
                        .onChange(of: otherNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Other")
                        }
                }
                .listRowBackground(Color.theme.foreground)
            }
            
            .foregroundColor(Color.theme.primaryText)
            .navigationTitle("Notifications")
            .listStyle(.insetGrouped)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: ConstantUtils.backbuttonImageName)
                        .foregroundColor(Color.theme.primaryText)
                        .bold()
                }
                    .font(.system(size: 14).bold())
            )
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
        }
    }
}
