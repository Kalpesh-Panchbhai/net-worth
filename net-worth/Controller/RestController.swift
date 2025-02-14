//
//  RestController.swift
//  net-worth
//
//  Created by Kalpesh Panchbhai on 28/04/24.
//

import Foundation

class RestController {
    
    public func executeAPI<T>(entity: String, httpMethod: String, body: Data = Data(), pathParam: [Any] = [], forClass: T.Type) async -> T where T : Codable {
        let url = URL(string: getURL(entity: entity, pathParam: pathParam))
        
        let request = getURLRequest(url: url!, httpMethod: httpMethod, body: body)
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try! decoder.decode(forClass, from: data)
        } catch {
            print(error)
        }
        
        return try! T(from: EmptyResponse() as! Decoder)
    }
    
    private func getURL(entity: String, pathParam: [Any]) -> String {
        var baseURL = ConstantUtils.baseRESTURL + entity
        var pathParams = ""
        for param in pathParam {
            if ((param as? String) != nil) {
                if !pathParams.isEmpty {
                    pathParams = pathParams + "/"
                }
                pathParams = pathParams + (param as! String)
            } else if ((param as? Int) != nil) {
                if !pathParams.isEmpty {
                    pathParams = pathParams + "/"
                }
                pathParams = pathParams + (param as! Int != 0 ? ("/" + String(param as! Int)) : "")
            }
        }
        return baseURL + pathParams
    }
    
    private func getURLRequest(url: URL, httpMethod: String, body: Data) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if(!httpMethod.elementsEqual(ConstantUtils.HTTP_METHOD.GET.rawValue)) {
            request.httpBody = body
        }
        
        return request
    }
}
