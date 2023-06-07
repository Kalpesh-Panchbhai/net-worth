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
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.theme.background)
//                .foregroundColor(Color.lightBlue)
                
                Section("Equity Notifications") {
                    Toggle("Show Notifications", isOn: $equityNotification)
                        .onChange(of: equityNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "EQUITY")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("ETF Notifications") {
                    Toggle("Show Notifications", isOn: $etfNotification)
                        .onChange(of: etfNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "ETF")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Cryptocurrency Notifications") {
                    Toggle("Show Notifications", isOn: $cryptoCurrencyNotification)
                        .onChange(of: cryptoCurrencyNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "CRYPTOCURRENCY")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Futures Notifications") {
                    Toggle("Show Notifications", isOn: $futureNotification)
                        .onChange(of: futureNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "FUTURE")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Options Notifications") {
                    Toggle("Show Notifications", isOn: $optionNotification)
                        .onChange(of: optionNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "OPTION")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Credit Card Notifications") {
                    Toggle("Show Notifications", isOn: $creditCardNotification)
                        .onChange(of: creditCardNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Credit Card")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Loan Notifications") {
                    Toggle("Show Notifications", isOn: $loanNotification)
                        .onChange(of: loanNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Loan")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
                
                Section("Other Notifications") {
                    Toggle("Show Notifications", isOn: $otherNotification)
                        .onChange(of: otherNotification) { newValue in
                            notificationController.setNotification(newValue: newValue, accountType: "Other")
                        }
//                        .foregroundColor(Color.navyBlue)
                }
//                .listRowBackground(Color.white)
//                .foregroundColor(Color.lightBlue)
            }
            .shadow(color: Color.theme.text.opacity(0.3),radius: 10, x: 0, y: 5)
            .listRowBackground(Color.theme.background)
            .foregroundColor(Color.theme.text)
            .navigationTitle("Notifications")
            .listStyle(.insetGrouped)
            .background(Color.theme.background)
            .scrollContentBackground(.hidden)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.theme.text)
                        .bold()
                }
                    .font(.system(size: 14).bold())
            )
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
        }
    }
}
