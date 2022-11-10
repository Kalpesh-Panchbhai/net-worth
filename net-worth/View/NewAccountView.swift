//
//  NewAccountView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct NewAccountView: View {
    
    @State var accountType: String = "None"
    @State var accountName: String = ""
    @State var currentBalance: String = ""
    @State var paymentReminder = false
    
    @State private var paymentDate = 1
    @State var dates = Array(1...31)
    
    var accountTypes =  ["None", "Saving", "Credit Card", "Loan", "Stock", "Mutual Fund"]
    
    private var accountController = AccountController()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Account detail") {
                    Picker(selection: $accountType, label: Text("Account Type")) {
                        ForEach(accountTypes, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .onChange(of: accountType) { _ in
                        accountName=""
                        currentBalance=""
                        paymentDate = 1
                        paymentReminder = false
                    }
                    HStack {
                        Text("Account Name")
                        Spacer()
                        TextField("Account Name", text: $accountName)
                    }
                    HStack {
                        Text("Current Balance")
                        Spacer()
                        TextField("Current Balance", text: $currentBalance).keyboardType(.decimalPad)
                    }
                    if accountType == "Loan" || accountType == "Credit Card" {
                        Toggle("Enable Payment Reminder", isOn: $paymentReminder)
                    }
                    if paymentReminder {
                        Picker("Select a payment date", selection: $paymentDate) {
                            ForEach(dates, id: \.self) {
                                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        accountController.addAccount(accountType: accountType, accountName: accountName, currentBalance: currentBalance, paymentReminder: paymentReminder, paymentDate: paymentDate)
                        dismiss()
                    }, label: {
                        Label("Add Account", systemImage: "checkmark")
                    }).disabled(false)
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct NewAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NewAccountView()
    }
}
