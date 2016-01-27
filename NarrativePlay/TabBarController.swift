import UIKit

class TabBarController: UITabBarController {
    override weak var preferredFocusedView: UIView? {
        return self.selectedViewController?.preferredFocusedView
    }
}
