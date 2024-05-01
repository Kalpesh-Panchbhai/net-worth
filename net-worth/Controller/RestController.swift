//
//  RestController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

class RestController {
    
    public func executeAPI<T>(entity: String, httpMethod: String, body: Data = Data(), pathParam: String = "", forClass: T.Type) async -> T where T : Codable {
        let url = URL(string: getURL(entity: entity, pathParam: pathParam))
        
        let request = getURLRequest(url: url!, httpMethod: httpMethod, body: body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try! decoder.decode(forClass, from: data)
        } catch {
            print(error)
        }
        
        return try! T(from: EmptyResponse() as! Decoder)
    }
    
    private func getURL(entity: String, pathParam: String) -> String {
        return ConstantUtils.baseRESTURL + entity + (pathParam != "" ? ("/" + pathParam) : "")
    }
    
    private func getCredential() -> String {
        let username = "admin"
        let password = "x2Ts4KX$"
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        return base64LoginString
    }
    
    private func getURLRequest(url: URL, httpMethod: String, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("Basic \(getCredential())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if(!httpMethod.elementsEqual(ConstantUtils.HTTP_METHOD.GET.rawValue)) {
            request.httpBody = body
        }
        
        return request
    }
}
