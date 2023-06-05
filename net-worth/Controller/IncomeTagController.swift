//
//  IncomeTagController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 05/06/23.
//

import FirebaseFirestore

class IncomeTagController {
    
    private func getIncomeTagCollection() -> CollectionReference {
        return UserController()
            .getCurrentUserDocument()
            .collection(ConstantUtils.incomeTagCollectionName)
    }
    
    public func addIncomeTag(tag: IncomeTag) {
        do {
            let documentID = try getIncomeTagCollection()
                .addDocument(from: tag)
                .documentID
            
            print("New Income Tag Added : " + documentID)
            
            if(tag.isdefault) {
                makeOtherIncomeTagNonDefault(documentID: documentID)
            }
        } catch {
            print(error)
        }
    }
    
    public func addDefaultIncomeTag() async {
        let count = await getIncomeTagList().count
        if(count == 0) {
            let incomeTag = IncomeTag(name: "None", isdefault: false)
            addIncomeTag(tag: incomeTag)
        }
    }
    
    public func getIncomeTagList() async -> [IncomeTag] {
        var incomeTagList = [IncomeTag]()
        do {
            incomeTagList = try await getIncomeTagCollection()
                .order(by: ConstantUtils.incomeTagKeyName)
                .getDocuments()
                .documents
                .map { doc in
                    return IncomeTag(id: doc.documentID,
                                     name: doc[ConstantUtils.incomeTagKeyName] as? String ?? "",
                                     isdefault: doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)
                }
        } catch {
            print(error)
        }
        return incomeTagList
    }
    
    public func makeOtherIncomeTagNonDefault(documentID: String) {
        getIncomeTagCollection()
            .getDocuments { snapshot, error in
                if error  == nil {
                    if let snapshot = snapshot {
                        snapshot.documents.forEach { doc in
                            if(!doc.documentID.elementsEqual(documentID) && (doc[ConstantUtils.incomeTagKeyIsDefault] as? Bool ?? false)) {
                                let updatedIncomeTag = IncomeTag(id: doc.documentID,
                                                                 name: doc[ConstantUtils.incomeTagKeyName] as? String ?? "",
                                                                 isdefault: false)
                                self.updateIncomeTag(tag: updatedIncomeTag)
                            }
                        }
                    }
                }
            }
    }
    
    public func updateIncomeTag(tag: IncomeTag) {
        do {
            try getIncomeTagCollection()
                .document(tag.id!)
                .setData(from: tag, merge: true)
            
            print("Income Tag : " + tag.id! + " Updated")
        } catch {
            print(error)
        }
    }
    
    public func deleteIncomeTags() {
        CommonController.delete(collection: UserController().getCurrentUserDocument().collection(ConstantUtils.incomeTagCollectionName))
    }
    
}
