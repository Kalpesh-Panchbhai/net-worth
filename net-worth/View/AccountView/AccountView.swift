//
//  ContentView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 09/11/22.
//

import SwiftUI
import CoreData

struct AccountView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var reset : Bool = false
    
    private var accountController = AccountController()
    
    private var financeController = FinanceController()
    
    @StateObject var financeListViewModel = FinanceListViewModel()
    
    @State var searchKeyWord: String = ""
    
    @State var isOpen: Bool = false
    
    @State var isAllSelected: Bool = false
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    @StateObject var accountViewModel = AccountViewModel()
    
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
            List(selection: $selection) {
                ForEach(searchResults, id: \.self) { account in
                    NavigationLink(destination: AccountDetailsNavigationLinkView(account: account, accountViewModel: accountViewModel), label: {
                        HStack{
                            VStack {
                                Text(account.accountName)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(account.accountType.uppercased()).font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            AccountFinanceView(account: account)
                        }
                        .foregroundColor(Color.blue)
                        .padding()
                    })
                    .swipeActions {
                        Button{
                            accountController.deleteAccount(account: account)
                            accountViewModel.getAccountList()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .halfSheet(showSheet: $isOpen) {
                NewAccountView(accountViewModel: accountViewModel)
            }
            .refreshable {
                accountViewModel.getAccountList()
                Task.init {
                    await financeListViewModel.getTotalBalance()
                }
            }
            .environment(\.editMode, self.$editMode)
            .listStyle(InsetGroupedListStyle())
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
                                        toggleNameSortOrder()
                                    }) {
                                        Text("Name")
                                    }
                                    Button(action: {
                                        toggleDateAddedSortOrder()
                                    }) {
                                        Text("Date Added")
                                    }
                                }
                            label: {
                                Label("Sort By", systemImage: "arrow.up.arrow.down")
                            }
                                
                                Menu {
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Saving")
                                    }) {
                                        Text("Saving")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Credit Card")
                                    }) {
                                        Text("Credit Card")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Loan")
                                    }) {
                                        Text("Loan")
                                    }
                                    Menu {
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "EQUITY")
                                        }) {
                                            Text("Equity")
                                        }
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "MUTUALFUND")
                                        }) {
                                            Text("Mutual Fund")
                                        }
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "CRYPTOCURRENCY")
                                        }) {
                                            Text("Cryptocurrency")
                                        }
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "FUTURE")
                                        }) {
                                            Text("Future")
                                        }
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "OPTION")
                                        }) {
                                            Text("Option")
                                        }
                                        Button(action: {
                                            toggleAccountTypeFilter(accountType: "ETF")
                                        }) {
                                            Text("ETF")
                                        }
                                    } label: {
                                        Label("Symbol", systemImage: "")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Other")
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
                            accountViewModel.getAccountList()
                        }, label: {
                            Label("delete Account", systemImage: "trash")
                        }).disabled(selection.count == 0)
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    if(editMode == .inactive) {
                        let balance = financeListViewModel.totalBalance
                        VStack {
                            Text("Total Balance: \(SettingsController().getDefaultCurrency().code) \(balance.totalChange.withCommas(decimalPlace: 2))")
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
            accountViewModel.getAccountList()
            Task.init {
                await financeListViewModel.getTotalBalance()
            }
        }
    }
    
    private func toggleNameSortOrder() {
//        sortOrder = sortOrder == .reverse ? .forward : .reverse
//        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: sortOrder)]
        reset = true
    }
    
    private func toggleDateAddedSortOrder() {
//        sortOrder = sortOrder == .reverse ? .forward : .reverse
//        accounts.sortDescriptors = [SortDescriptor(\Account.timestamp, order: sortOrder)]
        reset = true
    }
    
    private func toggleResetFilter() {
//        sortOrder = .forward
//        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: .forward)]
//        accounts.nsPredicate = NSPredicate(
//            format: "true = true"
//        )
    }
    
    private func toggleAccountTypeFilter(accountType: String) {
//        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: sortOrder)]
//        accounts.nsPredicate = NSPredicate(
//            format: "accounttype = %@", accountType
//        )
        reset = true
    }
}

struct AccountFinanceView: View {
    
    var account: Account
    
    @StateObject private var financeListViewModel = FinanceListViewModel()
    
    var body: some View {
        VStack {
            if(account.accountType == "Saving" || account.accountType == "Credit Card" || account.accountType == "Loan" || account.accountType == "Other") {
                HStack {
                    Text((account.currency ?? "") + " \(account.currentBalance.withCommas(decimalPlace: 2))")
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
