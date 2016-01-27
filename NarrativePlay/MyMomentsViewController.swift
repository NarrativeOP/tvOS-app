import UIKit
import Alamofire

class MyMomentsViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        self.setupScreen()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Check if user is already logged in
        guard Authorization.checkIfLoggedIn() == true else {
            let loginViewController = LoginViewController()
            presentViewController(loginViewController, animated: false, completion: nil)
            
            return
        }
        
        if Authorization.newUserMyMoments == true {
            Authorization.newUserMyMoments = false
            for view in self.view.subviews {
                view.removeFromSuperview()
            }

            self.viewDidLoad()
            self.viewHasAppearedBefore = false
            self.viewDidAppear(false)
            
            // Delay sign out button focus, make collection view first responder.
            na_perform({ () -> Void in
                self.signOutButton.userInteractionEnabled = true
            }, afterDelay: 0.5)
        }
        
        // Dont download photos again if view has appeared before
        guard self.viewHasAppearedBefore == false else { return }
        
        self.animateLoadingLabel(self.loadingLabel)
        self.fetchMoments()
        self.viewHasAppearedBefore = true
        
        self.setNeedsFocusUpdate()
    }
    
    // MARK: - Properties
    
    // Change preferred focus view
    override weak var preferredFocusedView: UIView? {
        return self.myMomentscollectionView.cellForItemAtIndexPath(NSIndexPath(
            forRow: self.focusIndex,
            inSection: 0
            )
        )
    }
    
    var focusIndex: Int = 0
    var moments = [Moment?](count: 1, repeatedValue: nil)
    var sortedMomentsData = [AnyObject]()
    var viewHasAppearedBefore = false
    
    // MARK: - Methods
    
    func fetchMoments() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            // Fetch moments from server
            print("Trying to connect to Narrative servers...")
            Alamofire.request(.GET, PrivateMomentsURL,
                headers: Authorization.getAuthHeaders()).responseJSON
                {(response: Response<AnyObject, NSError>) -> Void in
                    
                    // Declare result from Narrative API
                    if let result = response.result.value as? [String: AnyObject] {
                        
                        // Check if user doesn't have any personal moments
                        if let momentCheck = result["count"] as? Int {
                            if momentCheck == 0 {
                                self.userHasNoMoments()
                                return
                            }
                        }
                        
                        // Create moment array
                        if let moments = result["results"] as? NSMutableArray {
                            
                            // Sort moments by creation date
                            self.sortedMomentsData = moments.sort({
                                $0["created"] as! String > $1["created"] as! String
                            })
                            
                            // Populate moments array
                            self.moments = [Moment?](count: self.sortedMomentsData.count, repeatedValue: nil)
                            
                            // Set number of cells in collection view
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.myMomentscollectionView.reloadData()
                                self.updateUserInfoBox()
                            })
                            
                            // Create first 20 moments (if more than 20)
                            var limit = 20
                            if self.moments.count < 20 {
                                limit = self.moments.count
                            }
                            
                            for i in 0..<limit {
                                self.createMoment(self.sortedMomentsData, index: i)
                                self.updateCollectionView(i)
                            }
                        }
                    }
            }
        }) // END BG
    }
    
    func createMoment(momentSource: NSArray, index: Int) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            // Get user
            let userName = momentSource[index]["user"]!!["full_name"] as! String
            let userCountry = momentSource[index]["user"]!!["full_country"] as! String
            let userAvatarURL = momentSource[index]["user"]!!["avatar"]!!["src"] as! String
            var avatar: UIImage!
            if let avatarData = NSData(contentsOfURL: NSURL(string: userAvatarURL)!), let avatarImage = UIImage(data: avatarData) {
                avatar = avatarImage
            } else {
                avatar = UIImage(named: "redBackground")!
            }
            
            let user = User(avatar: avatar, fullName: userName, country: userCountry)
            
            // Get main photo
            let mainPhotoURL = momentSource[index]["cover_photos"]!![0]["renders"]!!["g1.hd"]!!["url"] as! String
            let mainPhoto: UIImage = {
                if let mainPhotoData = NSData(contentsOfURL: NSURL(string: mainPhotoURL)!), let mainPhotoImage = UIImage(data: mainPhotoData) {
                    return mainPhotoImage
                } else {
                    return UIImage(named: "redBackground")!
                }
            }()
            
            // Get smallPhotoOne
            var smallPhotoOne = UIImage(named: "redBackground")!
            if momentSource[index]["cover_photos"]!!.count > 1 {
                let smallPhotoOneURL = momentSource[index]["cover_photos"]!![1]["renders"]!!["smartphone"]!!["url"] as! String
                smallPhotoOne = {
                    if let smallPhotoOneData = NSData(contentsOfURL: NSURL(string: smallPhotoOneURL)!), let smallPhotoOneImage = UIImage(data: smallPhotoOneData) {
                        return smallPhotoOneImage
                    } else {
                        return UIImage(named: "redBackground")!
                    }
                    }()
            }
            
            // Get smallPhotoTwo
            var smallPhotoTwo = UIImage(named: "redBackground")!
            if momentSource[index]["cover_photos"]!!.count > 2 {
                let smallPhotoTwoURL = momentSource[index]["cover_photos"]!![2]["renders"]!!["smartphone"]!!["url"] as! String
                smallPhotoTwo = {
                    if let smallPhotoTwoData = NSData(contentsOfURL: NSURL(string: smallPhotoTwoURL)!), let smallPhotoTwoImage = UIImage(data: smallPhotoTwoData) {
                        return smallPhotoTwoImage
                    } else {
                        return UIImage(named: "redBackground")!
                    }
                    }()
            }
            
            let photosURL = momentSource[index]["photos_url"] as! String
            
            // Get caption and moment info
            var caption = momentSource[index]["caption"] as! String
            if caption == "" {
                caption = "No caption"
            }
            let createdAtTime = Formatter.formatTime(momentSource[index]["created"] as! String)
            let city = momentSource[index]["address"]!!["city"] as! String
            let country = momentSource[index]["address"]!!["country"] as! String
            var timeAndPlace: String
            if country != "" {
                timeAndPlace = city + ", " + country + ". " + createdAtTime
            } else {
                timeAndPlace = createdAtTime
            }
            
            // Create moment
            let newMoment = Moment(
                user: user,
                numberOfLikes: 0,
                mainPhoto: mainPhoto,
                smallPhotoOne: smallPhotoOne,
                smallPhotoTwo: smallPhotoTwo,
                caption: caption,
                timeAndPlace: timeAndPlace,
                commentUser: "",
                commentText: "",
                photosURL: photosURL
            )
            
            self.moments[index] = newMoment
            print("Created moment \(index)")
            
        }) // END BG
    }
    
    func updateCollectionView(index: Int) {
        // This function updates the cells in the collection view
        let cell = self.myMomentscollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? MainCollectionViewCell
        
        // Try again if moment at index hasn't loaded
        if self.moments[index] == nil {
            na_perform({ () -> Void in
                self.updateCollectionView(index)
                }, afterDelay: 0.2)
        } else {
            
            // Dismiss loading view when first moment has loaded
            if index == 0 {
                self.dismissViewWithAnimation(self.loadingView)
            }
            
            // Update collection view cell
            cell?.hasAppeared = true
            self.myMomentscollectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            return
        }
    }
    
    func updateUserInfoBox () {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            Alamofire.request(.GET, "https://narrativeapp.com/api/v2/users/", headers: Authorization.getAuthHeaders()).responseJSON {(response: Response<AnyObject, NSError>) -> Void in
                if let user = response.result.value as? [String: AnyObject] {
                    if let results = user["results"] as? NSMutableArray {
                        let requestURL = results[0]["url"] as! String
                        Alamofire.request(.GET, requestURL, headers: Authorization.getAuthHeaders()).responseJSON {(response: Response<AnyObject, NSError>) -> Void in
                            if let userInfo = response.result.value as? [String: AnyObject] {
                                if let stats = userInfo["statistics"] {
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        if let moment_count = stats["moment_count"] {
                                            self.numberOfMomentsLabel.text       = "\(moment_count!)"
                                        }
                                        if let photo_count = stats["photo_count"] {
                                            self.numberOfPhotosLabel.text        = "\(photo_count!)"
                                            
                                            // Edit photo count label
                                            if self.numberOfPhotosLabel.text!.characters.count > 3 {
                                                self.numberOfPhotosLabel.text!.insert(
                                                    ",", atIndex: self.numberOfPhotosLabel.text!.endIndex.advancedBy(-3)
                                                )
                                            }
                                            
                                            if self.numberOfPhotosLabel.text!.characters.count > 7 {
                                                self.numberOfPhotosLabel.text!.insert(
                                                    ",", atIndex: self.numberOfPhotosLabel.text!.endIndex.advancedBy(-7)
                                                )
                                            }
                                        }
                                        if let starred_count = stats["starred_photo_count"] {
                                            self.numberOfStarredPhotosLabel.text = "\(starred_count!)"
                                        }
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }) // END BG
    }
    
    func userHasNoMoments() {
        self.dismissViewWithAnimation(self.loadingView)
        self.numberOfMomentsLabel.text = "0"
        self.numberOfPhotosLabel.text = "0"
        self.numberOfStarredPhotosLabel.text = "0"
        
        self.mainPhotoImageView.image = UIImage(named: "redBackground")
        self.smallPhotoOneImageView.image = UIImage(named: "redBackground")
        self.smallPhotoTwoImageView.image = UIImage(named: "redBackground")
        
        let noMomentsLabel = UILabel(frame: self.mainPhotoImageView.frame)
        noMomentsLabel.font = UIFont.avenirMediumWithSize(35.0)
        noMomentsLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
        noMomentsLabel.textAlignment = .Center
        noMomentsLabel.numberOfLines = 2
        noMomentsLabel.text = "You don't have any moments yet :-(\nSwipe up and navigate to 'Explore' to see public moments!"
        
        self.view.addSubview(noMomentsLabel)
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
        UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseInOut, animations: { () -> Void in
            view.alpha = 1.0
            view.backgroundColor = UIColor.whiteColor()
        }, completion: { (finished: Bool) -> Void in
            self.bgImageView.removeFromSuperview()
                
            UIView.animateWithDuration(1.0, delay: 0.2, options: .CurveEaseInOut, animations: { () -> Void in
                view.alpha = 0.0
            }, completion: nil)
        })
    }
    
    func updateScreen(index: Int) {
        guard self.moments[index] != nil else { return }
        self.avatarImageView.image = self.moments[index]!.user.avatar
        
        // Set photos
        self.mainPhotoImageView.image = self.moments[index]!.mainPhoto
        self.smallPhotoOneImageView.image = self.moments[index]!.smallPhotoOne
        self.smallPhotoOneImageView.image = self.moments[index]!.smallPhotoOne
        self.smallPhotoTwoImageView.image = self.moments[index]!.smallPhotoTwo
        
        // Set labels
        self.userNameLabel.text = self.moments[index]!.user.fullName
        self.userCountryLabel.text = self.moments[index]!.user.country
        
        if self.previousCaptionLabel != nil {
            self.previousCaptionLabel!.removeFromSuperview()
            self.previousCaptionLabel = nil
        }
        
        let currentCaptionLabel = UILabel(frame: CGRect(x: 30, y: 0, width: 1850, height: 75))
        currentCaptionLabel.font = UIFont.avenirMediumWithSize(35.0)
        currentCaptionLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.8)
        currentCaptionLabel.minimumScaleFactor = 17/35
        currentCaptionLabel.adjustsFontSizeToFitWidth = true
        self.captionLabelView.addSubview(currentCaptionLabel)
        
        // Animations
        currentCaptionLabel.alpha = 0.8
        
        if self.moments[index]!.caption != "No caption" {
            currentCaptionLabel.text = self.moments[index]!.caption
            
            UIView.animateWithDuration(1.0, delay: 2.5, options: .CurveEaseInOut, animations: { () -> Void in
                currentCaptionLabel.alpha = 0.0
            }, completion: { (finished: Bool) -> Void in
                    
                UIView.animateWithDuration(1.0, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                    currentCaptionLabel.alpha = 0.8
                    if let _ = self.moments[index]?.timeAndPlace {
                        currentCaptionLabel.text = self.moments[index]?.timeAndPlace
                    }
                }, completion: { (finished: Bool) -> Void in
                            
                    UIView.animateWithDuration(1.0, delay: 2.5, options: .CurveEaseInOut, animations: { () -> Void in
                        currentCaptionLabel.alpha = 0.0
                    }, completion: { (finished: Bool) -> Void in
                            
                        UIView.animateWithDuration(1.0, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                            currentCaptionLabel.alpha = 0.8
                            if let _ = self.moments[index]?.timeAndPlace {
                                currentCaptionLabel.text = self.moments[index]?.caption
                            }
                        }, completion: nil)
                    })
                })
            })
        } else {
            currentCaptionLabel.text = self.moments[index]!.timeAndPlace
        }
        
        self.previousCaptionLabel = currentCaptionLabel
    }
    
    // MARK: - User interaction
    
    func pressedSignOut(sender: UIButton) {
        // Delete token
        Authorization.deleteStoredToken()
        
        // Prepare for next user
        self.moments = [nil]
        self.myMomentscollectionView.reloadData()
        self.loadingView.alpha = 1.0
        self.loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        self.signOutButton.userInteractionEnabled = false // Makes collection view respons first
        
        Authorization.newUserMyMoments = true // Run viewDidLoad next time view controller appears
        Authorization.newUserFavorites = true // Run viewDidLoad next time favorites view controller appears
        
        // Show login page
        self.presentViewController(LoginViewController(), animated: false, completion: nil)
    }
    
    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Create one cell per moment
        return self.moments.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = myMomentscollectionView.dequeueReusableCellWithReuseIdentifier("mainCell", forIndexPath: indexPath) as! MainCollectionViewCell
        
        cell.imageView.adjustsImageWhenAncestorFocused = true
        
        guard self.moments[indexPath.row] != nil && self.moments.count > 1 else {
            cell.imageView.backgroundColor = UIColor.clearColor()
            return cell
        }
        
        cell.imageView.image = self.moments[indexPath.row]!.mainPhoto
        cell.hasAppeared = true
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        guard self.moments.count != 0 else { return }
        if let index = context.nextFocusedIndexPath?.row {
            self.updateScreen(index)
            self.focusIndex = index
            
            // Append new moment
            guard index + 20 < self.moments.count && self.moments[index + 20] == nil else { return }
            createMoment(self.sortedMomentsData, index: index + 20)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Create screenshot
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Change focus view
        weak var preferredFocusedView: UIView? {
            return self.myMomentscollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: 0))
        }
        
        // Create and present photosViewController
        let photosViewController = MomentViewController(
            typeOfMoment: .Private,
            photosURL: self.moments[indexPath.row]!.photosURL + "?limit=150",
            startIndex: 0,
            backgroundImage: backgroundImage,
            nibName: nil,
            bundle: nil
        )
        
        presentViewController(photosViewController, animated: false, completion: nil)
    }
    
    // MARK: - Views
    
    var previousCaptionLabel: UILabel?
    var myMomentscollectionView: UICollectionView!
    var signOutButton = UIButton(type: UIButtonType.System)
    
    lazy var avatarImageView: UIImageView = {
        let avatarImageView = UIImageView(frame: CGRect(x: 82, y: 25, width: 176, height: 176))
        avatarImageView.layer.cornerRadius = 8.0
        avatarImageView.clipsToBounds = true
        
        return avatarImageView
    }()
    
    lazy var captionLabelView: UIView = {
        let captionLabelView = UIView(frame: CGRect(x: 0, y: 785, width: 1920, height: 75))
        captionLabelView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
        
        return captionLabelView
    }()
    
    lazy var userInfoView: UIView = {
        let userInfoView = UIView(frame: CGRect(x: 25, y: 25, width: 340, height: 735))
        userInfoView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 226, width: 340, height: 40))
        titleLabel.font = UIFont.avenirHeavyWithSize(40.0)
        titleLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        titleLabel.textAlignment = .Center
        titleLabel.text = "Welcome!"
        
        let momentsLabel = UILabel(frame: CGRect(x: 0, y: 435, width: 340, height: 20))
        momentsLabel.font = UIFont.avenirMediumWithSize(20.0)
        momentsLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        momentsLabel.textAlignment = .Center
        momentsLabel.text = "MOMENTS"
        
        let photosLabel = UILabel(frame: CGRect(x: 0, y: 520, width: 340, height: 20))
        photosLabel.font = UIFont.avenirMediumWithSize(20.0)
        photosLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        photosLabel.textAlignment = .Center
        photosLabel.text = "PHOTOS"
        
        let starredPhotosLabel = UILabel(frame: CGRect(x: 0, y: 605, width: 340, height: 20))
        starredPhotosLabel.font = UIFont.avenirMediumWithSize(20.0)
        starredPhotosLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        starredPhotosLabel.textAlignment = .Center
        starredPhotosLabel.text = "STARRED PHOTOS"
        
        self.signOutButton.frame = CGRect(x: 30, y: 660, width: 280, height: 50)
        self.signOutButton.setTitle("Sign out", forState: .Normal)
        self.signOutButton.titleLabel?.font = UIFont.avenirHeavyWithSize(25.0)
        self.signOutButton.addTarget(self, action: "pressedSignOut:", forControlEvents: .AllEvents)
        
        userInfoView.addSubview(titleLabel)
        userInfoView.addSubview(momentsLabel)
        userInfoView.addSubview(photosLabel)
        userInfoView.addSubview(starredPhotosLabel)
        userInfoView.addSubview(self.signOutButton)
        
        return userInfoView
    }()
    
    lazy var userNameLabel: UILabel = {
        let userNameLabel = UILabel(frame: CGRect(x: 0, y: 290, width: 340, height: 27))
        userNameLabel.font = UIFont.avenirMediumWithSize(27.0)
        userNameLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        userNameLabel.textAlignment = .Center
        userNameLabel.minimumScaleFactor = 10/27
        userNameLabel.adjustsFontSizeToFitWidth = true
        
        return userNameLabel
    }()
    
    lazy var userCountryLabel: UILabel = {
        let userCountryLabel = UILabel(frame: CGRect(x: 0, y: 333, width: 340, height: 27))
        userCountryLabel.font = UIFont.avenirHeavyWithSize(27.0)
        userCountryLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        userCountryLabel.textAlignment = .Center
        userCountryLabel.minimumScaleFactor = 10/27
        userCountryLabel.adjustsFontSizeToFitWidth = true
        
        return userCountryLabel
    }()
    
    lazy var numberOfMomentsLabel: UILabel = {
        let numberOfMomentsLabel = UILabel(frame: CGRect(x: 0, y: 390, width: 340, height: 40))
        numberOfMomentsLabel.font = UIFont.avenirHeavyWithSize(40.0)
        numberOfMomentsLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        numberOfMomentsLabel.textAlignment = .Center
        
        return numberOfMomentsLabel
    }()
    
    lazy var numberOfPhotosLabel: UILabel = {
        let numberOfPhotosLabel = UILabel(frame: CGRect(x: 0, y: 475, width: 340, height: 40))
        numberOfPhotosLabel.font = UIFont.avenirHeavyWithSize(40.0)
        numberOfPhotosLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        numberOfPhotosLabel.textAlignment = .Center
        
        return numberOfPhotosLabel
    }()
    
    lazy var numberOfStarredPhotosLabel: UILabel = {
        let numberOfStarredPhotosLabel = UILabel(frame: CGRect(x: 0, y: 560, width: 340, height: 40))
        numberOfStarredPhotosLabel.font = UIFont.avenirHeavyWithSize(40.0)
        numberOfStarredPhotosLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        numberOfStarredPhotosLabel.textAlignment = .Center
        
        return numberOfStarredPhotosLabel
    }()
    
    lazy var mainPhotoImageView: UIImageView = {
        let mainPhotoImageView = UIImageView(frame: CGRect(x: 390, y: 25, width: 998, height: 735))
        mainPhotoImageView.backgroundColor = UIColor.blackColor()
        
        return mainPhotoImageView
    }()
    
    lazy var smallPhotoOneImageView: UIImageView = {
        let smallPhotoOneImageView = UIImageView(frame: CGRect(x: 1413, y: 405, width: 482, height: 355))
        smallPhotoOneImageView.backgroundColor = UIColor.blackColor()
        
        return smallPhotoOneImageView
    }()
    
    lazy var smallPhotoTwoImageView: UIImageView = {
        let smallPhotoTwoImageView = UIImageView(frame: CGRect(x: 1413, y: 25, width: 482, height: 355))
        smallPhotoTwoImageView.backgroundColor = UIColor.blackColor()
        
        return smallPhotoTwoImageView
    }()
    
    let loadingLabel = UILabel(frame: CGRect(x: 0, y: 440, width: 1920, height: 100))
    
    lazy var loadingView: UIView = {
        let loadingView = UIView(frame: self.view.frame)
        loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
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
    
    lazy var bgImageView: UIImageView = {
        let bgImageView = UIImageView(frame: self.view.frame)
        bgImageView.image = UIImage(named: "publicMomentsPlaceholder")
        
        return bgImageView
    }()
    
    // MARK: - Layout
    
    func setupScreen() {
        // Set background
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "redBackground")!)
        
        // Collection view and layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 30, left: 50, bottom: 50, right: 50)
        layout.minimumLineSpacing = 55
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSize(width: 120, height: 120)
        
        self.myMomentscollectionView = UICollectionView(frame: CGRect(x: 0, y: 860, width: 1920, height: 220), collectionViewLayout: layout)
        self.myMomentscollectionView.dataSource = self
        self.myMomentscollectionView.delegate = self
        self.myMomentscollectionView.registerClass(MainCollectionViewCell.self, forCellWithReuseIdentifier: "mainCell")
        self.myMomentscollectionView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        
        // Add subviews
        self.view.addSubview(self.userInfoView)
        self.view.addSubview(self.mainPhotoImageView)
        self.view.addSubview(self.smallPhotoTwoImageView)
        self.view.addSubview(self.smallPhotoOneImageView)
        self.view.addSubview(self.smallPhotoOneImageView)
        self.view.addSubview(self.myMomentscollectionView)
        self.view.addSubview(self.captionLabelView)
        self.view.addSubview(self.bgImageView)
        self.view.addSubview(self.loadingView)
        
        self.userInfoView.addSubview(self.avatarImageView)
        self.userInfoView.addSubview(self.userNameLabel)
        self.userInfoView.addSubview(self.userCountryLabel)
        self.userInfoView.addSubview(self.numberOfMomentsLabel)
        self.userInfoView.addSubview(self.numberOfPhotosLabel)
        self.userInfoView.addSubview(self.numberOfStarredPhotosLabel)
    }
}
