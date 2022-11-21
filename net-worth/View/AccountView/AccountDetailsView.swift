//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/11/22.
//

import SwiftUI

struct AccountDetailsView: View {
    
    var account: Account
    init(account: Account) {
        self.account = account
    }
    var body: some View {
        Form {
            Section(account.accounttype! + " Account detail") {
                if(account.accounttype == "Saving") {
                    field(labelName: "Account Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance)")
                }
                else if(account.accounttype == "Credit Card") {
                    field(labelName: "Credit Card Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance)")
                    if(account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Loan") {
                    field(labelName: "Loan Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance)")
                    if(account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentDate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Stock") {
                    field(labelName: "Stock Name", value: account.accountname!)
                    field(labelName: "Total Shares", value: "\(account.totalShares)")
                    field(labelName: "Current rate of a share", value: "\(account.currentRateShare)")
                    field(labelName: "Total Value", value: "\(account.currentbalance)")
                }
                else if(account.accounttype == "Mutual Fund") {
                    field(labelName: "Mutual Fund Name", value: account.accountname!)
                    field(labelName: "Total Units", value: "\(account.totalShares)")
                    field(labelName: "Current rate of a unit", value: "\(account.currentRateShare)")
                    field(labelName: "Total Value", value: "\(account.currentbalance)")
                    if(account.paymentReminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentDate)")
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

struct AccountDetailsView_Previews: PreviewProvider {
    
    static var previews: some View {
        AccountDetailsView(account: Account())
    }
}
