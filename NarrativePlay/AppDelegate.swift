import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.setupTabBar()
        window!.makeKeyAndVisible()
        
        return true
    }
    
    func setupTabBar() {
        let tabBarController = TabBarController()
        tabBarController.tabBar.barTintColor = UIColor(red: 75/255, green: 0/255, blue: 0/255, alpha: 0.9)
        tabBarController.tabBar.tintColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        
        let exploreViewController = ExploreViewController()
        exploreViewController.title = "Explore"
        exploreViewController.tabBarItem.image = UIImage(named: "Explore")
        
        let myMomentsViewController = MyMomentsViewController()
        myMomentsViewController.title = "My moments"
        myMomentsViewController.tabBarItem.image = UIImage(named: "Home")
        
        let favoritesViewController = FavoritesViewController()
        favoritesViewController.title = "Favorites"
        favoritesViewController.tabBarItem.image = UIImage(named: "Favorites")
        
        tabBarController.addChildViewController(myMomentsViewController)
        tabBarController.addChildViewController(exploreViewController)
        tabBarController.addChildViewController(favoritesViewController)
        
        window!.rootViewController = tabBarController
    }
}
