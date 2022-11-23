//
//  AccountDetailsView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/11/22.
//

import SwiftUI

struct AccountDetailsView: View {
    
    private var mutualFundController = MutualFundController()
    
    private var currentRate: String
    
    private var totalValue: Double
    
    var account: Account
    init(account: Account) {
        self.account = account
        if(self.account.accounttype == "Mutual Fund") {
            self.currentRate = mutualFundController.getMutualFund(name: self.account.accountname!).rate!
            self.totalValue = currentRate.toDouble()! * account.totalShares
        }else {
            self.currentRate = "0.0"
            self.totalValue = 0.0
        }
    }
    var body: some View {
        Form {
            Section(account.accounttype! + " Account detail") {
                if(account.accounttype == "Saving") {
                    field(labelName: "Account Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas())")
                }
                else if(account.accounttype == "Credit Card") {
                    field(labelName: "Credit Card Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas())")
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Loan") {
                    field(labelName: "Loan Name", value: account.accountname!)
                    field(labelName: "Current Balance", value: "\(account.currentbalance.withCommas())")
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
                    }else {
                        field(labelName: "Payment Reminder", value: "Off")
                    }
                }
                else if(account.accounttype == "Stock") {
                    field(labelName: "Stock Name", value: account.accountname!)
                    field(labelName: "Total Shares", value: "\(account.totalShares.withCommas())")
                    field(labelName: "Current rate of a share", value: "\(currentRate.toDouble()!.withCommas())")
                    field(labelName: "Total Value", value: "\(account.currentbalance.withCommas())")
                }
                else if(account.accounttype == "Mutual Fund") {
                    field(labelName: "Mutual Fund Name", value: account.accountname!)
                    field(labelName: "Total Units", value: "\(account.totalShares.withCommas())")
                    field(labelName: "Current rate of a unit", value: "\(currentRate.toDouble()!.withCommas())")
                    field(labelName: "Total Value", value: "\(totalValue.withCommas())")
                    if(account.paymentreminder) {
                        field(labelName: "Payment Reminder", value: "On")
                        field(labelName: "Payment Date", value: "\(account.paymentdate)")
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
