import UIKit

private let AvenirMedium = "Avenir-Medium"
private let AvenirHeavy = "Avenir-Heavy"


extension UIFont {
    static func avenirMediumWithSize(size: CGFloat) -> UIFont {
        return UIFont(name: AvenirMedium, size: size)!
    }
    
    static func avenirHeavyWithSize(size: CGFloat) -> UIFont {
        return UIFont(name: AvenirHeavy, size: size)!
        
    }
}
