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
    
    @ObservedObject private var financeListViewModel = FinanceListViewModel()
    
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
                    field(labelName: "Current rate of a unit", value: (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0).withCommas(decimalPlace: 4))
                    field(labelName: "Total Value", value: (account.totalshare * (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0)).withCommas(decimalPlace: 4))
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
        .onAppear {
            Task {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol!)
            }
        }
        .refreshable {
            Task {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol!)
            }
        }
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
