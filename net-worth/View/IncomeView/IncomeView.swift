//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import CoreData

struct IncomeView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    @State var isOpen: Bool = false
    
    private var incomeController = IncomeController()
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomeViewModel.incomeList, id: \.self) { income in
                    ChildIncomeView(income: income)
                }
                .onDelete(perform: deleteIncome)
            }
            .refreshable {
                incomeViewModel.getIncomeList()
                Task.init {
                    await incomeViewModel.getTotalBalance()
                }
            }
            .halfSheet(showSheet: $isOpen) {
                NewIncomeView(incomeViewModel: incomeViewModel)
            }
            .listStyle(.grouped)
            .toolbar {
                if !incomeViewModel.incomeList.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
                ToolbarItem {
                    Button(action: {
                        if(SettingsController().getDefaultCurrency().name == "") {
                            showingSelectDefaultCurrencyAlert = true
                        } else {
                            self.isOpen.toggle()
                        }
                    }, label: {
                        Label("Add Income", systemImage: "plus")
                    })
                    .alert("Please select the default currency in the settings tab to add an Income.", isPresented: $showingSelectDefaultCurrencyAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    let balance = incomeViewModel.incomeTotalAmount
                    HStack {
                        Text("Total Income: \(SettingsController().getDefaultCurrency().code) \(balance.withCommas(decimalPlace: 2))")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Income")
        }
        .onAppear {
            incomeViewModel.getIncomeList()
            Task.init {
                await incomeViewModel.getTotalBalance()
            }
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        var id = ""
        withAnimation {
            offsets.map {
                id = incomeViewModel.incomeList[$0].id ?? ""
            }.forEach {
                incomeViewModel.getIncomeList()
                Task.init {
                    await incomeViewModel.deleteIncome(income: id)
                    await incomeViewModel.getTotalBalance()
                }
            }
        }
    }
    
}

struct ChildIncomeView: View {
    
    var income: Income
    
    var body: some View {
        HStack{
            VStack {
                Text(income.incometype)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(income.creditedon.getDateAndFormat()).font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
            }
            Text("\(income.currency) " + income.amount.withCommas(decimalPlace: 2))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
