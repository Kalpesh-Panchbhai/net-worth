//
//  IncomeDetailView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 25/04/23.
//

import SwiftUI

struct IncomeDetailView: View {
    
    @State var income: IncomeCalculation
    
    @State var modifyViewOpen = false
    
    @ObservedObject var incomeViewModel: IncomeViewModel
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section("Income detail") {
                HStack {
                    Text("Income Tag")
                    Spacer()
                    Text(income.tag)
                }
                
                HStack {
                    Text("Income Type")
                    Spacer()
                    Text(income.type)
                }
                
                HStack {
                    Text("Amount")
                    Spacer()
                    Text(income.currency + " \(income.amount.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Tax Paid")
                    Spacer()
                    Text(income.currency + " \(income.taxpaid.withCommas(decimalPlace: 2))")
                }
                
                HStack {
                    Text("Credited On")
                    Spacer()
                    Text(income.creditedOn.getDateAndFormat())
                }
                
            }
            .listRowBackground(Color.theme.foreground)
            .foregroundColor(Color.theme.primaryText)
        }
        .toolbar {
            ToolbarItem(content: {
                Button(action: {
                    self.modifyViewOpen = true
                }, label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color.theme.primaryText)
                })
                .font(.system(size: 14).bold())
            })
        }
        .background(Color.theme.background)
        .scrollContentBackground(.hidden)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(Color.theme.primaryText)
            })
            .font(.system(size: 14).bold())
        )
        .sheet(isPresented: $modifyViewOpen, onDismiss: {
            if(incomeViewModel.groupView) {
                incomeViewModel.incomeListByGroup.forEach {
                    let filterIncome = $0.value.filter { data in
                        data.id!.elementsEqual(income.id!)
                    }.first ?? IncomeCalculation(amount: 0.0, taxpaid: 0.0, creditedOn: Date(), currency: "", type: "", tag: "", avgAmount: 0.0, avgTaxPaid: 0.0, cumulativeAmount: 0.0, cumulativeTaxPaid: 0.0)
                    if(!filterIncome.currency.isEmpty) {
                        self.income = filterIncome
                    }
                }
            } else {
                self.income = incomeViewModel.incomeList.filter { data in
                    data.id!.elementsEqual(income.id!)
                }.first!
            }
        }, content: {
            UpdateIncomeView(income: income, incomeViewModel: incomeViewModel)
        })
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTypeList()
                await incomeViewModel.getIncomeTagList()
            }
        }
    }
}
