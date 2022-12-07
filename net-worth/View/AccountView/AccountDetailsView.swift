//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/11/22.
//

import SwiftUI

struct AccountDetailsView: View {
    
    private var currentRate: Double = 0.0
    
    private var totalValue: Double = 0.0
    
    @State private var paymentDate = 0
    @State var dates = Array(1...28)
    
    @State private var isTransactionOpen: Bool = false
    @State private var isDatePickerOpen: Bool = false
    
    @ObservedObject private var financeListVM = FinanceListViewModel()
    
    var account: Account
    init(account: Account) {
        self.account = account
        if(self.account.accounttype == "Saving" || self.account.accounttype == "Credit Card" || self.account.accounttype == "Loan") {
            self.currentRate = 0.0
            self.totalValue = 0.0
        }
    }
    var body: some View {
        Form {
            Section(account.accounttype! + " Account detail") {
                if(account.accounttype == "Saving") {
                    field(labelName: "Account Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: account.currency!)
                }
                else if(account.accounttype == "Credit Card") {
                    field(labelName: "Credit Card Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: account.currency!)
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Loan") {
                    field(labelName: "Loan Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: account.currency!)
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Other") {
                    field(labelName: "Account Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: account.currency!)
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else {
                    field(labelName: "Symbol Name", value: account.accountname!)
                    field(labelName: "Total Units", value: "\(account.totalshare.withCommas(decimalPlace: 4))")
                    field(labelName: "Current rate of a unit", value: (financeListVM.financeDetailModel.regularMarketPrice ?? 0.0).withCommas(decimalPlace: 4))
                    field(labelName: "Total Value", value: (account.totalshare * (financeListVM.financeDetailModel.regularMarketPrice ?? 0.0)).withCommas(decimalPlace: 4))
                    field(labelName: "Currency", value: account.currency!)
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
            }
        }
        .refreshable {
            Task {
                await financeListVM.getSymbolDetails(symbol: account.symbol!)
            }
        }
        .onAppear {
            Task {
                await financeListVM.getSymbolDetails(symbol: account.symbol!)
            }
        }
        .task {
            await financeListVM.getSymbolDetails(symbol: account.symbol!)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        self.isTransactionOpen.toggle()
                    }, label: {
                        Label("Update Balance", systemImage: "square.and.pencil")
                    })
                    if(self.account.accounttype != "Saving") {
                        if(!account.paymentreminder) {
                            Picker(selection: $paymentDate, content: {
                                Text("Select a date").tag(0)
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Enable Notification", systemImage: "speaker.wave.1.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                account.paymentreminder = true
                                account.paymentdate = Int16(paymentDate)
                                AccountController().updateAccount()
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                        } else {
                            Button(action: {
                                account.paymentreminder = false
                                account.paymentdate = 0
                                AccountController().updateAccount()
                                NotificationController().removeNotification(id: account.sysid!)
                                paymentDate = 0
                            }, label: {
                                Label("Disable Notification", systemImage: "speaker.slash.fill")
                            })
                            Picker(selection: $paymentDate, content: {
                                ForEach(dates, id: \.self) {
                                    Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                                }
                            }, label: {
                                Label("Change Payment date", systemImage: "calendar.circle.fill")
                            })
                            .onChange(of: paymentDate) { _ in
                                account.paymentdate = Int16(paymentDate)
                                AccountController().updateAccount()
                                NotificationController().removeNotification(id: account.sysid!)
                                NotificationController().enableNotification(account: account)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                        }
                    }
                    Button(action: {
                        AccountController().deleteAccount(account: account)
                    }, label: {
                        Label("Delete", systemImage: "trash")
                    })
                }
            label: {
                Label("", systemImage: "ellipsis.circle")
            }
            }
        }
        .sheet(isPresented: $isTransactionOpen, content: {
            AddTransactionAccountView(account: self.account)
        })
    }
    
    private func field(labelName: String, value: String) -> HStack<TupleView<(Text, Spacer, Text)>> {
        return HStack {
            Text(labelName)
            Spacer()
            Text(value)
        }
    }
    
}

struct AccountDetailsView_Previews: PreviewProvider {
    
    static var previews: some View {
        AccountDetailsView(account: Account())
    }
}
