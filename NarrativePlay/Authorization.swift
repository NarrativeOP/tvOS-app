import Foundation
import UIKit
import Alamofire

public class Authorization {
    
    // MARK: - Properties
    
    static internal var userDefaults = NSUserDefaults.standardUserDefaults()
    static var newUserMyMoments = false
    static var newUserFavorites = false
    
    // MARK: - Methods
    
    static func checkIfLoggedIn() -> Bool {
        if let token = self.userDefaults.stringForKey("token") {
            if (token == "No token") {
                return false
            } else {
                return true
            }
        } else {
            print("Couldn't check login status")
            
            return false
        }
    }
    
    static func setAccessToken(accessToken: String) {
        self.userDefaults.setValue(accessToken, forKey: "token")
    }
    
    static func deleteStoredToken() {
        self.userDefaults.setValue("No token", forKey: "token")
        self.userDefaults.synchronize()
        print("Token removed")
    }
    
    static func getAuthHeaders () -> [String:String]? {
        if let accessToken = self.userDefaults.stringForKey("token") {
            
            return ["Authorization": "Bearer \(accessToken)"]
        }
        
        return nil
    }
    
}
