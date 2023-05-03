//
//  AddTransactionHistoryView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 03/05/23.
//

import SwiftUI

struct AddTransactionHistoryView: View {
    private var accountController = AccountController()
    
    @State private var amount: Double = 0.0
    @State private var date = Date()
    
    @State var isPlus = true;
    
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var accountViewModel: AccountViewModel
    
    init(accountViewModel: AccountViewModel){
        self.accountViewModel = accountViewModel
    }
    
    var body: some View {
        NavigationView {
            Form {
                currentBalanceField()
                DatePicker("Payment on", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        var updatedAccount = accountViewModel.account
                        amount = isPlus ? amount : amount * -1
                        updatedAccount.currentBalance = amount
                        
                        accountController.addTransaction(accountID: accountViewModel.account.id!, account: updatedAccount, timestamp: date)
                        dismiss()
                    }, label: {
                        Text("Add")
                    })
                }
            }
            .navigationTitle(accountViewModel.account.accountName)
        }
    }
    
    private func currentBalanceField() -> HStack<TupleView<(Text, Spacer, Button<Label<Text, Image>>, Spacer, some View)>> {
        return HStack {
            Text("Amount")
            Spacer()
            Button(action: {
                if isPlus {
                    isPlus = false
                }else {
                    isPlus = true
                }
            }, label: {
                Label("", systemImage: isPlus ? "plus" : "minus")
            })
            Spacer()
            TextField("Amount", value: $amount, formatter: Double().formatter())
                .keyboardType(.decimalPad)
        }
    }
}
