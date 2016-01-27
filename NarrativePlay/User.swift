import Foundation
import UIKit

public class User {

    let avatar: UIImage!
    let fullName: String!
    let country: String!
    
    init(avatar: UIImage, fullName: String, country: String) {
        self.avatar = avatar
        self.fullName = fullName
        self.country = country
    }
}
