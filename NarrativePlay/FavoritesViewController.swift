import UIKit
import Alamofire

class FavoritesViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    var favCollectionView: UICollectionView!
    var favoritePhotosURL = [String]()
    var favoriteThumbImages = [UIImage?]()
    
    var numberOfPhotosToShow = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        self.setupScreen()
        
        // Fetch meta data
        Alamofire.request(.GET, FavoritesURL+"&limit=200", headers: Authorization.getAuthHeaders()).responseJSON { (response: Response<AnyObject, NSError>) -> Void in
            if let result = response.result.value as? [String: AnyObject] {
                let photos = result["results"] as! NSArray
                self.numberOfPhotosToShow = photos.count
                
                // Fill thumbs array
                for _ in 0..<self.numberOfPhotosToShow {
                    self.favoriteThumbImages.append(nil)
                }
                
                self.updateThumb(photos, index: 0)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check if new user logged in
        if Authorization.newUserFavorites == true {
            Authorization.newUserFavorites = false
            
            self.favoritePhotosURL = [String]()
            self.favoriteThumbImages = [UIImage?]()
            self.favCollectionView.reloadData()
            self.loadingView.alpha = 1.0
            self.loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
            self.numberOfPhotosToShow = 0
            self.viewDidLoad()
            self.viewDidAppear(false)
        }
        
        for view in self.view.subviews {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                view.alpha = 1
            })
        }
        
        self.animateLoadingLabel(self.loadingLabel)
    }
    
    override func viewDidDisappear(animated: Bool) {
        for view in self.view.subviews {
            view.alpha = 0
        }
    }
    
    // MARK: - Views
    
    let loadingLabel = UILabel(frame: CGRect(x: 0, y: 440, width: 1920, height: 100))
    
    lazy var loadingView: UIView = {
        let loadingView = UIView(frame: self.view.frame)
        loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        self.loadingLabel.font = UIFont.avenirMediumWithSize(40.0)
        self.loadingLabel.text = "Loading photos"
        self.loadingLabel.textColor = UIColor.whiteColor()
        self.loadingLabel.textAlignment = .Center
        
        let dotsLabel = UILabel(frame: CGRect(x: 0, y: 480, width: 1920, height: 100))
        dotsLabel.font = UIFont.avenirMediumWithSize(40.0)
        dotsLabel.textColor = UIColor.whiteColor()
        dotsLabel.textAlignment = .Center
        
        loadingView.addSubview(self.loadingLabel)
        loadingView.addSubview(dotsLabel)
        
        self.animateTextDots(textLabel: dotsLabel)
        
        return loadingView
    }()
    
    // MARK: - Methods
    
    func updateThumb(photos: NSArray, index: Int) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            if index == 0 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.favCollectionView.reloadData()
                })
            }
            
            let photoURL = photos[index]["renders"]!!["g1_hd"]!!["url"] as! String
            
            if let data = NSData(contentsOfURL: NSURL(string: photoURL)!) {
                if let image = UIImage(data: data) {
                    self.favoriteThumbImages[index] = image
                }
            }
            
            if index == 0 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.favCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
                })
            }
            
            if index == 6 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.dismissViewWithAnimation(self.loadingView)
                })
            }
            
            for i in 1..<self.numberOfPhotosToShow {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let cell = self.favCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as? FavoritesCollectionViewCell {
                        
                        if cell.hasAppeared == false {
                            self.favCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: i, inSection: 0)])
                        }
                    }
                })
            }
        }) // END BACKGROUND
        
        guard index + 1 < self.numberOfPhotosToShow else { return }
        
        na_perform({ () -> Void in
            self.updateThumb(photos, index: index + 1)
        }, afterDelay: 0.05)
    }
    
    // MARK: - Animations
    
    func animateLoadingLabel(label: UILabel) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = NSNumber(float: 0.9)
        animation.toValue = NSNumber(float: 0.2)
        animation.duration = 0.9
        animation.repeatCount = 100.0
        animation.autoreverses = true
        label.layer.addAnimation(animation, forKey: "currentlyLoading")
    }
    
    func animateTextDots(textLabel textLabel: UILabel) {
        var newText = "."
        
        if let text = textLabel.text {
            if text != "...." {
                newText = text + "."
            }
        }
        
        textLabel.text = newText
        na_perform({ [weak self] () -> Void in
            if let strongSelf = self {
                strongSelf.animateTextDots(textLabel: textLabel)
            }
        }, afterDelay: 1.0)
    }
    
    func dismissViewWithAnimation(view: UIView) {
            UIView.animateWithDuration(1.0, delay: 0.2, options: .CurveEaseInOut, animations: { () -> Void in
                view.alpha = 0.0
            }, completion: { (finished: Bool) -> Void in
                view.removeFromSuperview()
            })
    }
    
    // MARK: - Layout
    
    func setupScreen() {
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "redBackground")!)
        
        // Collection view and layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        layout.minimumLineSpacing = 55
        layout.minimumInteritemSpacing = 55
        layout.scrollDirection = .Vertical
        layout.itemSize = CGSize(width: 550, height: 412)
        
        self.favCollectionView = UICollectionView(frame: super.view.frame, collectionViewLayout: layout)
        self.favCollectionView.dataSource = self
        self.favCollectionView.delegate = self
        self.favCollectionView.registerClass(FavoritesCollectionViewCell.self, forCellWithReuseIdentifier: "favCell")
        
        self.view.addSubview(self.favCollectionView)
        self.view.addSubview(self.loadingView)
    }

    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.numberOfPhotosToShow
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("favCell", forIndexPath: indexPath) as! FavoritesCollectionViewCell
        
        cell.backgroundColor = UIColor.clearColor()
        
        if self.favoriteThumbImages[indexPath.row] != nil {
            cell.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
            cell.imageView.adjustsImageWhenAncestorFocused = true
            cell.imageView.image = self.favoriteThumbImages[indexPath.row]
            cell.imageView.contentMode = .ScaleAspectFit
            cell.hasAppeared = true
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Create screenshot
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Create and present photosViewController
        let photosViewController = PhotoFullscreenViewController(
            photo: self.favoriteThumbImages[indexPath.row]!,
            backgroundImage: backgroundImage,
            nibName: nil,
            bundle: nil
        )
        
        presentViewController(photosViewController, animated: false, completion: nil)
        
    }
}
