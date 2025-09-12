import Foundation

/// Lightweight parser for the embedded provisioning profile shipped with non-AppStore builds.
/// For App Store/TestFlight builds, the profile is stripped, so this returns nil.
struct MobileProvision {
    let name: String?
    let teamName: String?
    let creationDate: Date?
    let expirationDate: Date?
    let appIDName: String?
    let teamIdentifier: [String]?

    static func read() -> MobileProvision? {
        // Try multiple possible locations for the provisioning profile
        let possiblePaths = [
            Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
            Bundle.main.bundlePath + "/embedded.mobileprovision",
            Bundle.main.bundlePath + "/PlugIns/net-worth WatchKit Extension.appex/embedded.mobileprovision"
        ]
        
        var profileData: Data?
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path) {
                profileData = try? Data(contentsOf: URL(fileURLWithPath: path))
                if profileData != nil { break }
            }
        }
        
        guard let data = profileData else { 
            return nil 
        }
        
    
        // The mobileprovision file is a PKCS#7 signed data structure containing a plist
        // Since it's binary, we need to search for plist markers in the raw data
        
        // Approach 1: Look for XML plist markers in binary data
        let xmlStartMarker = "<?xml".data(using: .utf8)!
        let plistEndMarker = "</plist>".data(using: .utf8)!
        
        if let xmlStartRange = data.range(of: xmlStartMarker) {
            
            if let plistEndRange = data.range(of: plistEndMarker, in: xmlStartRange.upperBound..<data.endIndex) {
                
                let plistData = data[xmlStartRange.lowerBound..<plistEndRange.upperBound]
                
                do {
                    if let dict = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                        return createMobileProvision(from: dict)
                    } else {
                    }
                } catch {
                }
            }
        }
        
        // Approach 2: Look for binary plist markers
        let binaryPlistHeader = Data([0x62, 0x70, 0x6c, 0x69, 0x73, 0x74]) // "bplist"
        if let binaryRange = data.range(of: binaryPlistHeader) {
            let remainingData = data.suffix(from: binaryRange.lowerBound)
            if let dict = try? PropertyListSerialization.propertyList(from: remainingData, options: [], format: nil) as? [String: Any] {
                return createMobileProvision(from: dict)
            }
        }
        
        // Approach 3: More aggressive plist extraction
        let dataString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? ""
        
        // Look for the main dictionary containing our keys
        if let dictStartRange = dataString.range(of: "<dict>") {
            var dictLevel = 0
            var dictEndIndex = dictStartRange.upperBound
            
            // Find the matching </dict> by counting nested dict tags
            let remainingString = String(dataString[dictStartRange.upperBound...])
            var searchIndex = remainingString.startIndex
            
            while searchIndex < remainingString.endIndex {
                if let nextDictStart = remainingString.range(of: "<dict>", range: searchIndex..<remainingString.endIndex) {
                    if let nextDictEnd = remainingString.range(of: "</dict>", range: searchIndex..<remainingString.endIndex) {
                        if nextDictStart.lowerBound < nextDictEnd.lowerBound {
                            dictLevel += 1
                            searchIndex = nextDictStart.upperBound
                        } else {
                            if dictLevel == 0 {
                                dictEndIndex = dataString.index(dictStartRange.lowerBound, offsetBy: dataString.distance(from: dataString.startIndex, to: dictStartRange.lowerBound) + remainingString.distance(from: remainingString.startIndex, to: nextDictEnd.upperBound))
                                break
                            } else {
                                dictLevel -= 1
                                searchIndex = nextDictEnd.upperBound
                            }
                        }
                    } else {
                        break
                    }
                } else if let nextDictEnd = remainingString.range(of: "</dict>", range: searchIndex..<remainingString.endIndex) {
                    if dictLevel == 0 {
                        dictEndIndex = dataString.index(dictStartRange.lowerBound, offsetBy: dataString.distance(from: dataString.startIndex, to: dictStartRange.lowerBound) + remainingString.distance(from: remainingString.startIndex, to: nextDictEnd.upperBound))
                        break
                    } else {
                        dictLevel -= 1
                        searchIndex = nextDictEnd.upperBound
                    }
                } else {
                    break
                }
            }
            
            let dictString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n" + String(dataString[dictStartRange.lowerBound..<dictEndIndex]) + "\n</plist>"
            
            if let plistData = dictString.data(using: .utf8),
               let dict = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                return createMobileProvision(from: dict)
            }
        }
        
        // Approach 4: Try to extract individual values using regex-like patterns
        if dataString.contains("<key>ExpirationDate</key>") {
            var extractedDict: [String: Any] = [:]
            
            // Extract ExpirationDate
            if let expRange = dataString.range(of: "<key>ExpirationDate</key>") {
                let afterExp = String(dataString[expRange.upperBound...])
                if let dateStart = afterExp.range(of: "<date>"),
                   let dateEnd = afterExp.range(of: "</date>") {
                    let dateString = String(afterExp[dateStart.upperBound..<dateEnd.lowerBound])
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: dateString) {
                        extractedDict["ExpirationDate"] = date
                    }
                }
            }
            
            // Extract Name
            if let nameRange = dataString.range(of: "<key>Name</key>") {
                let afterName = String(dataString[nameRange.upperBound...])
                if let stringStart = afterName.range(of: "<string>"),
                   let stringEnd = afterName.range(of: "</string>") {
                    let name = String(afterName[stringStart.upperBound..<stringEnd.lowerBound])
                    extractedDict["Name"] = name
                }
            }
            
            // Extract TeamName
            if let teamRange = dataString.range(of: "<key>TeamName</key>") {
                let afterTeam = String(dataString[teamRange.upperBound...])
                if let stringStart = afterTeam.range(of: "<string>"),
                   let stringEnd = afterTeam.range(of: "</string>") {
                    let teamName = String(afterTeam[stringStart.upperBound..<stringEnd.lowerBound])
                    extractedDict["TeamName"] = teamName
                }
            }
            
            if !extractedDict.isEmpty {
                return createMobileProvision(from: extractedDict)
            }
        }
        return nil
    }
    
    private static func createMobileProvision(from dict: [String: Any]) -> MobileProvision {
        let name = dict["Name"] as? String
        let teamName = dict["TeamName"] as? String
        let creationDate = dict["CreationDate"] as? Date
        let expirationDate = dict["ExpirationDate"] as? Date
        let appIDName = dict["AppIDName"] as? String
        let teamIdentifier = dict["TeamIdentifier"] as? [String]        
        return MobileProvision(
            name: name,
            teamName: teamName,
            creationDate: creationDate,
            expirationDate: expirationDate,
            appIDName: appIDName,
            teamIdentifier: teamIdentifier
        )
    }
    
    /// Get app build info even when provisioning profile is not available
    static func getBuildInfo() -> (version: String, build: String, bundleId: String) {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        return (version, build, bundleId)
    }
    
    /// Alternative approach: Calculate expiration based on free developer provisioning
    /// Free Apple Developer accounts create profiles that expire 7 days from creation
    static func estimateExpirationForFreeDeveloper() -> Date? {
        // Try multiple approaches to get the actual build/installation time
        
        // Approach 1: Check the main executable's creation date
        if let executablePath = Bundle.main.executablePath,
           let attributes = try? FileManager.default.attributesOfItem(atPath: executablePath),
           let creationDate = attributes[.creationDate] as? Date {
            return Calendar.current.date(byAdding: .day, value: 7, to: creationDate)
        }
        
        // Approach 2: Check Info.plist modification date
        if let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let attributes = try? FileManager.default.attributesOfItem(atPath: infoPlistPath),
           let modificationDate = attributes[.modificationDate] as? Date {
            return Calendar.current.date(byAdding: .day, value: 7, to: modificationDate)
        }
        
        // Approach 3: Check bundle creation date
        let bundlePath = Bundle.main.bundlePath
        if let attributes = try? FileManager.default.attributesOfItem(atPath: bundlePath),
           let creationDate = attributes[.creationDate] as? Date {
            return Calendar.current.date(byAdding: .day, value: 7, to: creationDate)
        }
        
        // Approach 4: Parse build date from app version or build number if available
        if let buildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
           let buildNumber = Int(buildString) {
            // If build number looks like a timestamp (Unix timestamp or similar)
            if buildNumber > 1000000000 { // Rough check for Unix timestamp
                let buildDate = Date(timeIntervalSince1970: TimeInterval(buildNumber))
                if buildDate > Date(timeIntervalSince1970: 0) && buildDate < Date() {
                    return Calendar.current.date(byAdding: .day, value: 7, to: buildDate)
                }
            }
        }
        
        // Fallback: Return nil so the UI shows "Not available" instead of incorrect time
        return nil
    }
}
