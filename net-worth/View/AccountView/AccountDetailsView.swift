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
    
    @ObservedObject private var financeListViewModel: FinanceListViewModel
    
    @ObservedObject private var accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel, financeListViewModel: FinanceListViewModel) {
        self.accountViewModel = accountViewModel
        self.financeListViewModel = financeListViewModel
        if(self.accountViewModel.account.accountType == "Saving" || self.accountViewModel.account.accountType == "Credit Card" || self.accountViewModel.account.accountType == "Loan") {
            self.currentRate = 0.0
            self.totalValue = 0.0
        }
    }
    var body: some View {
        Form {
            Section(accountViewModel.account.accountType + " Account detail") {
                if(accountViewModel.account.accountType == "Saving") {
                    field(labelName: "Account Name", value: accountViewModel.account.accountName)
                    field(labelName: "Current Balance", value: "\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: accountViewModel.account.currency)
                }
                else if(accountViewModel.account.accountType == "Credit Card") {
                    field(labelName: "Credit Card Name", value: accountViewModel.account.accountName)
                    field(labelName: "Current Balance", value: "\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: accountViewModel.account.currency)
                    if(accountViewModel.account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(accountViewModel.account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(accountViewModel.account.accountType == "Loan") {
                    field(labelName: "Loan Name", value: accountViewModel.account.accountName)
                    field(labelName: "Current Balance", value: "\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: accountViewModel.account.currency)
                    if(accountViewModel.account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(accountViewModel.account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(accountViewModel.account.accountType == "Other") {
                    field(labelName: "Account Name", value: accountViewModel.account.accountName)
                    field(labelName: "Current Balance", value: "\(accountViewModel.account.currentBalance.withCommas(decimalPlace: 4))")
                    field(labelName: "Currency", value: accountViewModel.account.currency)
                    if(accountViewModel.account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(accountViewModel.account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else {
                    field(labelName: "Symbol Name", value: accountViewModel.account.accountName)
                    field(labelName: "Total Units", value: "\(accountViewModel.account.totalShares.withCommas(decimalPlace: 4))")
                    field(labelName: "Current rate of a unit", value: (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0).withCommas(decimalPlace: 4))
                    field(labelName: "Total Value", value: (accountViewModel.account.totalShares * (financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0)).withCommas(decimalPlace: 4))
                    field(labelName: "Currency", value: accountViewModel.account.currency)
                    if(accountViewModel.account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(accountViewModel.account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
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
