//
//  ExpendableButton.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 10/02/23.
//

import SwiftUI

struct AccountDetailExpendableButton: View {
    
    @Binding var show: Bool
    @ObservedObject var accountViewModel: AccountViewModel
    @ObservedObject var financeListViewModel: FinanceListViewModel
    
    var dates = Array(1...28)
    var accountController = AccountController()
    
    @Environment(\.presentationMode) var presentationMode
    
    var account: Account
    
    @State var isNewTransactionViewOpen = false
    @State var paymentDate = 0
    
    var body: some View {
        VStack(spacing: 20) {
            
            if self.show {
                Button(action: {
                    self.isNewTransactionViewOpen.toggle()
                    self.show.toggle()
                }){
                    Image(systemName: "square.and.pencil")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(18)
                }
                .background(.black)
                .foregroundColor(.blue)
                .clipShape(Circle())
                
                Button(action: {
                    accountController.deleteAccount(account: account)
                    self.presentationMode.wrappedValue.dismiss()
                    self.show.toggle()
                }) {
                    Image(systemName: "trash.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(18)
                }
                .background(.black)
                .foregroundColor(.red)
                .clipShape(Circle())
                
                if(accountViewModel.account.accountType != "Saving") {
                    if(!accountViewModel.account.paymentReminder) {
                        Picker(selection: $paymentDate, content: {
                            Image(systemName: "speaker.wave.1.fill")
                                .resizable()
                                .frame(width: 35, height: 25)
                                .padding(18)
                                .tag(0)
                            ForEach(dates, id: \.self) {
                                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                            }
                        }) {
                            Image(systemName: "speaker.wave.1.fill")
                                .resizable()
                                .frame(width: 35, height: 25)
                                .padding(18)
                                .tag(0)
                        }
                        .background(.black)
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        .onChange(of: paymentDate) { _ in
                            accountViewModel.account.paymentReminder = true
                            accountViewModel.account.paymentDate = paymentDate
                            accountController.updateAccount(account: accountViewModel.account)
                            NotificationController().enableNotification(account: accountViewModel.account)
                            self.show.toggle()
                        }
                        .pickerStyle(MenuPickerStyle())
                    } else {
                        Button(action: {
                            accountViewModel.account.paymentReminder = false
                            accountViewModel.account.paymentDate = 0
                            accountController.updateAccount(account: accountViewModel.account)
                            NotificationController().removeNotification(id: accountViewModel.account.id!)
                            paymentDate = 0
                            self.show.toggle()
                        }) {
                            Image(systemName: "speaker.slash.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding(18)
                        }
                        .background(.black)
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        
                        Picker(selection: $paymentDate, content: {
                            ForEach(dates, id: \.self) {
                                Text("\($0.formatted(.number.grouping(.never)))").tag($0)
                            }
                        }){
                            Image(systemName: "calendar.circle.fill")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding(18)
                        }
                        .background(.black)
                        .foregroundColor(.blue)
                        .clipShape(Circle())
                        .onChange(of: paymentDate) { _ in
                            accountViewModel.account.paymentDate = paymentDate
                            accountController.updateAccount(account: accountViewModel.account)
                            NotificationController().removeNotification(id: accountViewModel.account.id!)
                            NotificationController().enableNotification(account: accountViewModel.account)
                            self.show.toggle()
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            
            Button(action: {
                self.show.toggle()
                paymentDate = accountViewModel.account.paymentDate
            }) {
                Image(systemName: "chevron.up")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .padding(18)
            }
            .background(.blue)
            .foregroundColor(.white)
            .clipShape(Circle())
            .rotationEffect(self.show ? Angle(degrees: 180) : Angle(degrees: 0))
        }
        .sheet(isPresented: $isNewTransactionViewOpen, onDismiss: {
            Task.init {
                await accountViewModel.getAccount(id: accountViewModel.account.id!)
                await accountViewModel.getAccountTransactionList(id: accountViewModel.account.id!)
                await accountViewModel.getLastTwoAccountTransactionList(id: accountViewModel.account.id!)
                await financeListViewModel.getSymbolDetails(symbol: accountViewModel.account.symbol)
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance(accountList: accountViewModel.accountList)
            }
        }, content: {
            UpdateBalanceAccountView(accountViewModel: accountViewModel)
        })
        .animation(.spring(), value: show)
    }
}
