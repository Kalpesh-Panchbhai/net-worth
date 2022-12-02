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
    
    @State var sortOrder: SortOrder = .forward
    
    @State private var reset : Bool = false
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Account.accountname, order: .forward)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    private var accountController = AccountController()
    
    private var financeController = FinanceController()
    
    @StateObject var financeListVM = FinanceListViewModel()
    
    @State var searchKeyWord: String = ""
    
    @State var isOpen: Bool = false
    
    @State var isAllSelected: Bool = false
    
    var searchResults: [Account] {
        accounts.filter { account in
            if(searchKeyWord.isEmpty) {
                return true
            } else {
                return account.accountname!.lowercased().contains(searchKeyWord.lowercased()) || account.accounttype!.lowercased().contains(searchKeyWord.lowercased())
            }
        }
    }
    
    @State var selection = Set<Account>()
    
    @State var editMode = EditMode.inactive
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(searchResults, id: \.self) { account in
                    NavigationLink(destination: AccountDetailsNavigationLinkView(uuid: account.sysid!), label: {
                        HStack{
                            VStack {
                                Text(account.accountname!)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(account.accounttype!).font(.system(size: 10))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            Spacer()
                            AccountFinanceView(account: account)
                        }
                        .padding()
                    })
                    .swipeActions {
                        Button{
                            accountController.deleteAccount(account: account)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .refreshable {
                Task.init {
                    await financeListVM.getTotalBalance()
                }
            }
            .environment(\.editMode, self.$editMode)
            .listStyle(.inset)
            .toolbar {
                if !accounts.isEmpty {
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if(editMode == .inactive) {
                        Menu(content: {
                            Menu {
                                Button(action: {
                                    toggleAlphabetSortOrder()
                                }) {
                                    Text("Alphabet")
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
                                        toggleAccountTypeFilter(accountType: "Equity")
                                    }) {
                                        Text("Equity")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Fund")
                                    }) {
                                        Text("Mutual Fund")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Cryptocurrency")
                                    }) {
                                        Text("Cryptocurrency")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "Future")
                                    }) {
                                        Text("Future")
                                    }
                                    Button(action: {
                                        toggleAccountTypeFilter(accountType: "ETF")
                                    }) {
                                        Text("ETF")
                                    }
                                } label: {
                                    Label("Symbol", systemImage: "")
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    if(editMode == .inactive) {
                        Button(action: {
                            self.isOpen.toggle()
                        }, label: {
                            Label("Add Account", systemImage: "plus")
                        }).sheet(isPresented: $isOpen, content: {
                            NewAccountView()
                        })
                    }
                    else {
                        Button(action: {
                            for accountSelected in selection {
                                accountController.deleteAccount(account: accountSelected)
                            }
                            editMode = .inactive
                        }, label: {
                            Label("delete Account", systemImage: "trash")
                        }).disabled(selection.count == 0)
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    if(editMode == .inactive) {
                        let balance = financeListVM.totalBalance
                        HStack {
                            Text("Total Balance: \(SettingsController().getDefaultCurrency().code) \(balance.withCommas(decimalPlace: 2))")
                                .foregroundColor(.blue)
                                .font(.title2)
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
                Text("ETF").searchCompletion("ETF")
            }
        }
        .onAppear {
            Task.init {
                await financeListVM.getTotalBalance()
            }
        }
    }
    
    private func toggleAlphabetSortOrder() {
        sortOrder = sortOrder == .reverse ? .forward : .reverse
        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: sortOrder)]
        reset = true
    }
    
    private func toggleResetFilter() {
        sortOrder = .forward
        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: .forward)]
        accounts.nsPredicate = NSPredicate(
            format: "true = true"
        )
    }
    
    private func toggleAccountTypeFilter(accountType: String) {
        accounts.sortDescriptors = [SortDescriptor(\Account.accountname, order: sortOrder)]
        accounts.nsPredicate = NSPredicate(
            format: "accounttype = %@", accountType
        )
        reset = true
    }
}

struct AccountFinanceView: View {
    
    var account: Account
    
    @StateObject private var financeListViewModel = FinanceListViewModel()
    
    var body: some View {
        VStack {
            if(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan") {
                Text("\(account.currentbalance.withCommas(decimalPlace: 2))")
            } else {
                let currentRate = financeListViewModel.financeDetailModel.regularMarketPrice ?? 0.0
                let oneDayChange = financeListViewModel.financeDetailModel.oneDayChange ?? 0.0
                Text((financeListViewModel.financeDetailModel.currency ?? "") + " \((account.totalshare * currentRate).withCommas(decimalPlace: 2))")
                    .frame(maxWidth: .infinity, alignment: .trailing)
                if(oneDayChange > 0.0) {
                    Text("+\((account.totalshare * oneDayChange).withCommas(decimalPlace: 2))").font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.green)
                } else if(oneDayChange < 0.0){
                    Text("\((account.totalshare * oneDayChange).withCommas(decimalPlace: 2))").font(.system(size: 15))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.red)
                }
            }
        }
        .task {
            if(!(account.accounttype == "Saving" || account.accounttype == "Credit Card" || account.accounttype == "Loan")) {
                await financeListViewModel.getSymbolDetails(symbol: account.symbol!)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}
