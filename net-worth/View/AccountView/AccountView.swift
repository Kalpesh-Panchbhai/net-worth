//
//  ContentView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI

struct AccountView: View {
    
    @State private var reset : Bool = false
    
    @State private var groupBy : Bool = false
    
    @State private var sortedKey: String = ""
    
    private var accountController = AccountController()
    
    private var financeController = FinanceController()
    
    @State var searchKeyWord: String = ""
    
    @State var isOpen: Bool = false
    
    @State var isAllSelected: Bool = false
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
    @ObservedObject var financeListViewModel = FinanceListViewModel()
    
    var searchResults: [Account] {
        accountViewModel.accountList.filter { account in
            if(searchKeyWord.isEmpty) {
                return true
            } else {
                return account.accountName.lowercased().contains(searchKeyWord.lowercased()) || account.accountType.lowercased().contains(searchKeyWord.lowercased())
            }
        }
    }
    
    @State var selection = Set<Account>()
    
    @State var editMode = EditMode.inactive
    
    var body: some View {
        NavigationView {
            VStack {
                if groupBy {
                    AccountGroupedView(accountViewModel: accountViewModel, financeListViewModel: financeListViewModel, selection: $selection, searchKeyWord: $searchKeyWord)
                } else {
                    AccountUngroupedView(accountViewModel: accountViewModel, financeListViewModel: financeListViewModel, selection: $selection, searchKeyWord: $searchKeyWord)
                }
            }
            .halfSheet(showSheet: $isOpen) {
                NewAccountView(accountViewModel: accountViewModel)
            }
            .refreshable {
                Task.init {
                    await accountViewModel.getAccountList()
                    await accountViewModel.getTotalBalance()
                }
            }
            .environment(\.editMode, self.$editMode)
            .listStyle(SidebarListStyle())
            .toolbar {
                if !accountViewModel.accountList.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if(editMode == .inactive) {
                            Button(action: {
                                self.editMode = .active
                                self.selection = Set<Account>()
                            }) {
                                Text("Edit")
                            }
                        }
                        else {
                            Button(action: {
                                self.editMode = .inactive
                                self.selection = Set<Account>()
                                isAllSelected =  false
                            }) {
                                Text("Done")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(reset) {
                        Button(action: {
                            toggleResetFilter()
                            self.reset.toggle()
                        }, label: {
                            Text("Reset")
                        })
                    }
                }
                if !accountViewModel.accountList.isEmpty {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if(editMode == .inactive) {
                            Menu(content: {
                                Menu {
                                    Button(action: {
                                        sortList(key: ConstantUtils.accountKeyAccountName)
                                    }) {
                                        Text("Name")
                                    }
                                    Button(action: {
                                        sortList(key: ConstantUtils.accountKeyCurrentBalance)
                                    }) {
                                        Text("Current Balance")
                                    }
                                }
                            label: {
                                Label("Sort By", systemImage: "arrow.up.arrow.down")
                            }
                                
                                Menu {
                                    Button(action: {
                                        groupBy = true
                                        reset = true
                                        accountViewModel.grouping = .accountType
                                    }) {
                                        Text("Account Type")
                                    }
                                    Button(action: {
                                        groupBy = true
                                        reset = true
                                        accountViewModel.grouping = .currency
                                    }) {
                                        Text("Currency")
                                    }
                                }
                            label: {
                                Label("Group By", systemImage: "arrow.up.arrow.down")
                            }
                                
                                Menu {
                                    Button(action: {
                                        accountTypeFilter(accountType: "Saving")
                                    }) {
                                        Text("Saving")
                                    }
                                    Button(action: {
                                        accountTypeFilter(accountType: "Credit Card")
                                    }) {
                                        Text("Credit Card")
                                    }
                                    Button(action: {
                                        accountTypeFilter(accountType: "Loan")
                                    }) {
                                        Text("Loan")
                                    }
                                    Menu {
                                        Button(action: {
                                            accountTypeFilter(accountType: "EQUITY")
                                        }) {
                                            Text("Equity")
                                        }
                                        Button(action: {
                                            accountTypeFilter(accountType: "MUTUALFUND")
                                        }) {
                                            Text("Mutual Fund")
                                        }
                                        Button(action: {
                                            accountTypeFilter(accountType: "CRYPTOCURRENCY")
                                        }) {
                                            Text("Cryptocurrency")
                                        }
                                        Button(action: {
                                            accountTypeFilter(accountType: "FUTURE")
                                        }) {
                                            Text("Future")
                                        }
                                        Button(action: {
                                            accountTypeFilter(accountType: "OPTION")
                                        }) {
                                            Text("Option")
                                        }
                                        Button(action: {
                                            accountTypeFilter(accountType: "ETF")
                                        }) {
                                            Text("ETF")
                                        }
                                    } label: {
                                        Label("Symbol", systemImage: "")
                                    }
                                    Button(action: {
                                        accountTypeFilter(accountType: "Other")
                                    }) {
                                        Text("Other")
                                    }
                                }
                            label: {
                                Label("Filter By", systemImage: "")
                            }
                            }, label: {
                                Label("", systemImage: "ellipsis.circle")
                            })
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(editMode == .inactive) {
                        Button(action: {
                            if(SettingsController().getDefaultCurrency().name == "") {
                                showingSelectDefaultCurrencyAlert = true
                            } else {
                                self.isOpen.toggle()
                            }
                        }, label: {
                            Label("Add Account", systemImage: "plus")
                        })
                        .alert("Please select the default currency in the settings tab to add an account.", isPresented: $showingSelectDefaultCurrencyAlert) {
                            Button("OK", role: .cancel) { }
                        }
                    }
                    else {
                        Button(action: {
                            for accountSelected in selection {
                                accountController.deleteAccount(account: accountSelected)
                            }
                            editMode = .inactive
                            Task.init {
                                await accountViewModel.getAccountList()
                                await accountViewModel.getTotalBalance()
                            }
                        }, label: {
                            Label("delete Account", systemImage: "trash")
                        }).disabled(selection.count == 0)
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    if(editMode == .inactive) {
                        let balance = accountViewModel.totalBalance
                        VStack {
                            Text("Total Balance: \(SettingsController().getDefaultCurrency().code) \(balance.currentValue.withCommas(decimalPlace: 2))")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            if(balance.oneDayChange >= 0) {
                                Text("\(balance.oneDayChange.withCommas(decimalPlace: 2))")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                Text("\(balance.oneDayChange.withCommas(decimalPlace: 2))")
                                    .foregroundColor(.red)
                                    .font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }else {
                        if(!isAllSelected && searchResults.count != selection.count) {
                            Button("Select all", action: {
                                searchResults.forEach { (acc) in
                                    self.selection.insert(acc)
                                }
                                isAllSelected = true
                            })
                        }else {
                            Button("Deselect all", action: {
                                self.selection.removeAll()
                                isAllSelected = false
                            })
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .searchable(text: $searchKeyWord, placement: .navigationBarDrawer(displayMode: .always))
            .searchSuggestions {
                Text("Saving").searchCompletion("Saving")
                Text("Credit Card").searchCompletion("Credit Card")
                Text("Loan").searchCompletion("Loan")
                Text("Equity").searchCompletion("Equity")
                Text("Mutual Fund").searchCompletion("Fund")
                Text("Cryptocurrency").searchCompletion("Cryptocurrency")
                Text("Future").searchCompletion("Future")
                Text("Option").searchCompletion("Option")
                Text("ETF").searchCompletion("ETF")
                Text("Other").searchCompletion("Other")
            }
        }
        .onAppear {
            Task.init {
                await accountViewModel.getAccountList()
                await accountViewModel.getTotalBalance()
            }
        }
    }
    
    private func sortList(key: String) {
        accountViewModel.sortAccountList(orderBy: key)
        reset = true
        sortedKey = key
    }
    
    private func toggleResetFilter() {
        accountViewModel.resetAccountList()
        groupBy = false
    }
    
    private func accountTypeFilter(accountType: String) {
        accountViewModel.filterAccountList(filter: accountType)
        if(sortedKey.count > 0) {
            accountViewModel.sortAccountList(orderBy: sortedKey)
        }
        reset = true
    }
}

struct AccountFinanceView: View {
    
    var account: Account
    
    @ObservedObject var financeListViewModel : FinanceListViewModel
    
    var body: some View {
        VStack {
            if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
                HStack {
                    Text((account.currency) + " \(account.currentBalance.withCommas(decimalPlace: 2))")
                    if(account.paymentReminder && account.accountType != "Saving") {
                        Image(systemName: "speaker.wave.1.fill")
                    } else if(account.accountType != "Saving") {
                        Image(systemName: "speaker.slash.fill")
                    }
                }
            } else {
                let currentRate = financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0
                let oneDayChange = financeListViewModel.financeDetailModel.oneDayChange ?? 0.0
                HStack{
                    VStack {
                        Text((financeListViewModel.financeDetailModel.currency ?? "") + " \((account.totalShares * currentRate).withCommas(decimalPlace: 2))")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        if(oneDayChange > 0.0) {
                            Text("+\((account.totalShares * oneDayChange).withCommas(decimalPlace: 2))").font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.green)
                        } else if(oneDayChange < 0.0){
                            Text("\((account.totalShares * oneDayChange).withCommas(decimalPlace: 2))").font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.red)
                        }
                    }
                    if(account.paymentReminder) {
                        Image(systemName: "speaker.wave.1.fill")
                    } else {
                        Image(systemName: "speaker.slash.fill")
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
