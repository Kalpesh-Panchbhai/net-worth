//
//  IncomeTypeController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import FirebaseFirestore

class IncomeTypeController {
    
    private func getIncomeTypeCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTypeCollectionName)
    }
    
    public func addIncomeType(type: IncomeType) async {
        do {
            let documentID = try getIncomeTypeCollection()
                .addDocument(from: type)
                .documentID
            
            print("New Income Type Added : " + documentID)
            
            if(type.isdefault) {
                await makeOtherIncomeTypeNonDefault(documentID: documentID)
            }
        } catch {
            print(error)
        }
    }
    
    public func addDefaultIncomeType() async {
        let count = await getIncomeTypeList().count
        if(count == 0) {
            let incomeType = IncomeType(name: ConstantUtils.noneAccountType, isdefault: false)
            await addIncomeType(type: incomeType)
        }
    }
    
    public func getIncomeTypeList() async -> [IncomeType] {
        var incomeTypeList = [IncomeType]()
        do {
            incomeTypeList = try await getIncomeTypeCollection()
                .order(by: ConstantUtils.incomeTypeKeyName)
                .getDocuments()
                .documents
                .map { doc in
                    return IncomeType(id: doc.documentID,
                                      name: doc[ConstantUtils.incomeTypeKeyName] as? String ?? "",
                                      isdefault: doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)
                }
        } catch {
            print(error)
        }
        return incomeTypeList
    }
    
    public func makeOtherIncomeTypeNonDefault(documentID: String) async {
        do {
            try await getIncomeTypeCollection()
                .getDocuments()
                .documents
                .forEach { doc in
                    if(!doc.documentID.elementsEqual(documentID) && (doc[ConstantUtils.incomeTypeKeyIsDefault] as? Bool ?? false)) {
                        let updatedIncomeType = IncomeType(id: doc.documentID,
                                                           name: doc[ConstantUtils.incomeTypeKeyName] as? String ?? "",
                                                           isdefault: false)
                        self.updateIncomeType(type: updatedIncomeType)
                    }
                }
        } catch {
            print(error)
        }
    }
    
    public func updateIncomeType(type: IncomeType) {
        do {
            try getIncomeTypeCollection()
                .document(type.id!)
                .setData(from: type, merge: true)
            
            print("Income Type : " + type.id! + " Updated")
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTypes() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTypeCollectionName))
    }
    
}
