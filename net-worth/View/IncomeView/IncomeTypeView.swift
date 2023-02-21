//
//  IncomeTypeView.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 21/02/23.
//

import SwiftUI

struct IncomeTypeView: View {
    
    @ObservedObject var incomeViewModel = IncomeViewModel()
    
    private var incomeController = IncomeController()
    
    var body: some View {
        List {
            ForEach(incomeViewModel.incomeTypeList, id: \.self) { item in
                VStack(alignment: .leading) {
                    Text(item.name)
                    Text(item.isdefault ? "DEFAULT" : "")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .contextMenu {
                    if(!item.isdefault) {
                        Button(action: {
                            incomeController.makeOtherIncomeTypeNonDefault(documentID: item.id!)
                            var updatedIncomeType = item
                            updatedIncomeType.isdefault = true
                            incomeController.updateIncomeType(type: updatedIncomeType)
                            Task.init {
                                incomeViewModel.incomeTypeList = [IncomeType]()
                                await incomeViewModel.getIncomeTypeList()
                            }
                        }, label: {
                            Text("Make default")
                        })
                    }
                }
            }
        }
        .onAppear {
            Task.init {
                await incomeViewModel.getIncomeTypeList()
            }
        }
    }
}
