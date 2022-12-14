//
//  IncomeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 14/11/22.
//

import SwiftUI
import CoreData

struct IncomeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Income.creditedon, ascending: false)],
        animation: .default)
    private var incomes: FetchedResults<Income>
    
    @State var isOpen: Bool = false
    
    private var incomeController = IncomeController()
    
    @State private var showingSelectDefaultCurrencyAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(incomes) { income in
                    ChildIncomeView(income: income)
                }
                .onDelete(perform: deleteIncome)
            }
            .halfSheet(showSheet: $isOpen) {
                NewIncomeView()
            }
            .listStyle(.grouped)
            .toolbar {
                if !incomes.isEmpty {
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
                    .alert("Please select the default currency in the settings tab to add an account.", isPresented: $showingSelectDefaultCurrencyAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
                ToolbarItem(placement: .bottomBar){
                    let balance = incomeController.getTotalBalance()
                    HStack {
                        Text("Total Income: \(SettingsController().getDefaultCurrency().code) \(balance.withCommas(decimalPlace: 2))")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
            }
            .navigationTitle("Income")
        }
    }
    
    private func deleteIncome(offsets: IndexSet) {
        withAnimation {
            offsets.map { incomes[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
}

struct ChildIncomeView: View {
    
    @ObservedObject var income: Income
    
    var body: some View {
        HStack{
            VStack {
                Text(income.incometype!)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(income.creditedon!.getDateAndFormat()).font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.gray)
            }
            Text("\(income.currency!) " + income.amount.withCommas(decimalPlace: 2))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct IncomeView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeView()
    }
}
