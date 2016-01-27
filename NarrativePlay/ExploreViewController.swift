import UIKit
import Alamofire

class ExploreViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        self.setupScreen()
        self.fetchMoments()
        self.tabBarController?.tabBar.hidden = true
    }
    
    // MARK: - Properties
    
    // Change preferred focus view
    override weak var preferredFocusedView: UIView? {
        return self.collectionView.cellForItemAtIndexPath(NSIndexPath(
            forRow: self.focusIndex,
            inSection: 0
            )
        )
    }
    
    var focusIndex: Int = 0
    var moments = [Moment?]()
    var sortedMomentsData = [AnyObject]()
    
    // MARK: - Methods
    
    func fetchMoments() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            // Fetch moments from server
            print("Trying to connect to Narrative servers...")
            Alamofire.request(.GET, PublicMomentsURL,
                headers: Authorization.getAuthHeaders()).responseJSON
                {(response: Response<AnyObject, NSError>) -> Void in
                    
                if let result = response.result.value as? [String: AnyObject],
                    let moments = result["results"] as? NSMutableArray {
                        
                    // Sort moments by creation date
                    self.sortedMomentsData = moments.sort({
                            $0["created"] as! String > $1["created"] as! String
                    })
                        
                    // Populate moments array
                    self.moments = [Moment?](count: self.sortedMomentsData.count, repeatedValue: nil)
                    // Set number of cells in collection view
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.collectionView.reloadData()
                    })
                        
                    // Create first 20 moments
                    for i in 0..<20 {
                        self.createMoment(self.sortedMomentsData, index: i)
                        self.updateCollectionView(i)
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
        
        // Get likes
        let numberOfLikes = momentSource[index]["likes"]!!["count"] as! Int
        
        // Get latest comment
        let commentCount = momentSource[index]["comments"]!!["count"] as! Int
        var commentUser: String?
        var commentText: String?
        
        if commentCount > 0 {
            commentUser = momentSource[index]["comments"]!!["latest"]!![0]["user"]!!["full_name"] as? String
            commentText = momentSource[index]["comments"]!!["latest"]!![0]["text"] as? String
        }
        
        // Get main photo
        let mainPhotoURL = momentSource[index]["cover_photos"]!![0]["renders"]!!["smartphone"]!!["url"] as! String
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
            let smallPhotoOneURL = momentSource[index]["cover_photos"]!![1]["renders"]!!["g1_thumb_square"]!!["url"] as! String
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
            let smallPhotoTwoURL = momentSource[index]["cover_photos"]!![2]["renders"]!!["g1_thumb_square"]!!["url"] as! String
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
            numberOfLikes: numberOfLikes,
            mainPhoto: mainPhoto,
            smallPhotoOne: smallPhotoOne,
            smallPhotoTwo: smallPhotoTwo,
            caption: caption,
            timeAndPlace: timeAndPlace,
            commentUser: commentUser,
            commentText: commentText,
            photosURL: photosURL
        )
            
        self.moments[index] = newMoment
        print("Created moment \(index)")
            
        }) // END BG
    }
    
    func updateCollectionView(index: Int) {
        // This function updates the cells in the collection view
        let cell = self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? MainCollectionViewCell
        
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
            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
            return
        }
    }
    
    func updateCommentFont() {
        guard commentsTextView.text.isEmpty == false else { return }
        guard CGSizeEqualToSize(commentsTextView.bounds.size, CGSizeZero) == false else { return }
        
        let fixedWidth = commentsTextView.frame.size.width
        let expectSize = commentsTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        
        var expectFont = commentsTextView.font
        if expectSize.height > commentsTextView.frame.size.height {
            while (commentsTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max)).height > commentsTextView.frame.size.height) {
                expectFont = commentsTextView.font!.fontWithSize(commentsTextView.font!.pointSize - 1)
                commentsTextView.font = expectFont
            }
        } else {
            commentsTextView.font = UIFont.avenirMediumWithSize(25.0)
        }
    }
    
    func updateScreen(index: Int) {
        guard self.moments.count > index else { return }
        
        self.avatarImageView.image = self.moments[index]!.user.avatar
        self.momentInfoView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        // Set likes
        let textEnding = self.moments[index]!.numberOflikes == 1 ? " like" : " likes"
        self.likeLabel.text = "\(self.moments[index]!.numberOflikes)" + textEnding
        
        // Set comment
        if self.moments[index]!.commentText != nil {
            self.commentsTextView.text = self.moments[index]!.commentUser! + ":\n" + self.moments[index]!.commentText!
            self.updateCommentFont()
        } else {
            self.commentsTextView.text = "This moment has no comments yet!"
        }
        
        // Set photos
        self.mainPhotoImageView.image = self.moments[index]!.mainPhoto
        self.smallPhotoOneImageView.image = self.moments[index]!.smallPhotoOne
        self.smallPhotoTwoImageView.image = self.moments[index]!.smallPhotoTwo
        
        // Set labels
        self.userInfoTitleLabel.text = Formatter.greetingForCountry(self.moments[index]!.user.country)
        self.userNameLabel.text = "I'm " + self.moments[index]!.user.fullName
        self.userCountryLabel.text = "from " + self.moments[index]!.user.country
        
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
                    currentCaptionLabel.text = self.moments[index]!.timeAndPlace
                }, completion: { (finished: Bool) -> Void in
                            
                    UIView.animateWithDuration(1.0, delay: 2.5, options: .CurveEaseInOut, animations: { () -> Void in
                        currentCaptionLabel.alpha = 0.0
                    }, completion: { (finished: Bool) -> Void in
                                    
                        UIView.animateWithDuration(1.0, delay: 0.0, options: .CurveEaseInOut, animations: { () -> Void in
                            currentCaptionLabel.alpha = 0.8
                            currentCaptionLabel.text = self.moments[index]!.caption
                        }, completion: nil)
                    })
                })
            })
        } else {
            currentCaptionLabel.text = self.moments[index]!.timeAndPlace
        }
        
        self.previousCaptionLabel = currentCaptionLabel
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
            }, completion: { (finished: Bool) -> Void in
                view.removeFromSuperview()
            })
        })
    }
    
    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Create one cell per moment
        return self.moments.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("mainCell", forIndexPath: indexPath) as! MainCollectionViewCell
        
        cell.imageView.adjustsImageWhenAncestorFocused = true
        
        guard self.moments[indexPath.row] != nil else {
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
            if moments[index] != nil {
                self.updateScreen(index)
            } else {
                print("To fast!")
                return
            }
            
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
        
        // Create and present photosViewController
        let photosViewController = MomentViewController(
            typeOfMoment: .Public,
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
    var collectionView: UICollectionView!
    
    let avatarImageView = UIImageView(frame: CGRect(x: 25, y: 25, width: 175, height: 175))
    let commentsView = UIView(frame: CGRect(x: 25, y: 150, width: 460, height: 350))
    
    lazy var captionLabelView: UIView = {
        let captionLabelView = UIView(frame: CGRect(x: 0, y: 785, width: 1920, height: 75))
        captionLabelView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
        
        return captionLabelView
    }()
    
    lazy var userInfoView: UIView = {
        let userInfoView = UIView(frame: CGRect(x: 25, y: 25, width: 485, height: 225))
        userInfoView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        return userInfoView
    }()
    
    lazy var userInfoTitleLabel: UILabel = {
        let userInfoTitleLabel = UILabel(frame: CGRect(x: 225, y: 40, width: 260, height: 50))
        userInfoTitleLabel.font = UIFont.avenirHeavyWithSize(40.0)
        userInfoTitleLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
        
        return userInfoTitleLabel
    }()
    
    lazy var userNameLabel: UILabel = {
        let userNameLabel = UILabel(frame: CGRect(x: 225, y: 125, width: 240, height: 27))
        userNameLabel.font = UIFont.avenirMediumWithSize(27.0)
        userNameLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        userNameLabel.minimumScaleFactor = 10/27
        userNameLabel.adjustsFontSizeToFitWidth = true
        
        return userNameLabel
    }()
    
    lazy var userCountryLabel: UILabel = {
        let userCountryLabel = UILabel(frame: CGRect(x: 225, y: 170, width: 240, height: 27))
        userCountryLabel.font = UIFont.avenirMediumWithSize(27.0)
        userCountryLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        userCountryLabel.minimumScaleFactor = 10/27
        userCountryLabel.adjustsFontSizeToFitWidth = true
        
        return userCountryLabel
    }()
    
    lazy var momentInfoView: UIView = {
        let momentInfoTitleLabel = UILabel(frame: CGRect(x: 25, y: 25, width: 400, height: 35))
        momentInfoTitleLabel.font = UIFont.avenirMediumWithSize(35.0)
        momentInfoTitleLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        momentInfoTitleLabel.text = "Social"
        
        let likeImageView = UIImageView(frame: CGRect(x: 27, y: 85, width: 32, height: 27))
        likeImageView.image = UIImage(named: "likeHeart")
        
        let momentInfoView = UIView(frame: CGRect(x: 25, y: 275, width: 485, height: 485))
        momentInfoView.backgroundColor = UIColor.blackColor()
        momentInfoView.addSubview(momentInfoTitleLabel)
        momentInfoView.addSubview(likeImageView)
        
        return momentInfoView
    }()
    
    lazy var likeLabel: UILabel = {
        let likeLabel = UILabel(frame: CGRect(x: 82, y: 85, width: 200, height: 27))
        likeLabel.font = UIFont.avenirMediumWithSize(27.0)
        likeLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        
        return likeLabel
    }()
    
    lazy var commentsTitleLabel: UILabel = {
        let commentsTitleLabel = UILabel(frame: CGRect(x: -25, y: 0, width: 485, height: 50))
        commentsTitleLabel.font = UIFont.avenirMediumWithSize(30.0)
        commentsTitleLabel.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        commentsTitleLabel.text = "   Latest comment"
        commentsTitleLabel.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        
        return commentsTitleLabel
    }()
    
    lazy var commentsTextView: UITextView = {
        let commentsTextView = UITextView(frame: CGRect(x: 0, y: 65, width: 435, height: 250))
        commentsTextView.font = UIFont.avenirMediumWithSize(25.0)
        commentsTextView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        commentsTextView.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.7)
        
        return commentsTextView
    }()
    
    lazy var mainPhotoImageView: UIImageView = {
        let mainPhotoImageView = UIImageView(frame: CGRect(x: 535, y: 25, width: 980, height: 735))
        mainPhotoImageView.backgroundColor = UIColor.blackColor()
        
        return mainPhotoImageView
    }()
    
    lazy var smallPhotoOneImageView: UIImageView = {
        let smallPhotoOneImageView = UIImageView(frame: CGRect(x: 1540, y: 25, width: 355, height: 355))
        smallPhotoOneImageView.backgroundColor = UIColor.blackColor()
        
        return smallPhotoOneImageView
    }()
    
    lazy var smallPhotoTwoImageView: UIImageView = {
        let smallPhotoTwoImageView = UIImageView(frame: CGRect(x: 1540, y: 405, width: 355, height: 355))
        smallPhotoTwoImageView.backgroundColor = UIColor.blackColor()
        
        return smallPhotoTwoImageView
    }()
    
    lazy var loadingView: UIView = {
        let loadingView = UIView(frame: self.view.frame)
        loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
        let loadingLabel = UILabel(frame: CGRect(x: 0, y: 440, width: 1920, height: 100))
        loadingLabel.font = UIFont.avenirMediumWithSize(40.0)
        loadingLabel.text = "Loading photos"
        loadingLabel.textColor = UIColor.whiteColor()
        loadingLabel.textAlignment = .Center
        
        let dotsLabel = UILabel(frame: CGRect(x: 0, y: 480, width: 1920, height: 100))
        dotsLabel.font = UIFont.avenirMediumWithSize(40.0)
        dotsLabel.textColor = UIColor.whiteColor()
        dotsLabel.textAlignment = .Center
        
        loadingView.addSubview(loadingLabel)
        loadingView.addSubview(dotsLabel)
        
        self.animateLoadingLabel(loadingLabel)
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
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "redBackground")!)
        self.tabBarController?.tabBar.hidden = true
        
        // Change preferred focus view
        weak var preferredFocusedView: UIView? {
            
            return self.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
        }
        
        // Collection view and layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 30, left: 50, bottom: 50, right: 50)
        layout.minimumLineSpacing = 55
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSize(width: 120, height: 120)
        
        self.collectionView = UICollectionView(frame: CGRect(x: 0, y: 860, width: 1920, height: 220), collectionViewLayout: layout)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.registerClass(MainCollectionViewCell.self, forCellWithReuseIdentifier: "mainCell")
        self.collectionView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        
        // Add subviews
        self.view.addSubview(self.userInfoView)
        self.view.addSubview(self.momentInfoView)
        self.view.addSubview(self.mainPhotoImageView)
        self.view.addSubview(self.smallPhotoOneImageView)
        self.view.addSubview(self.smallPhotoTwoImageView)
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.captionLabelView)
        self.view.addSubview(self.bgImageView)
        self.view.addSubview(self.loadingView)
        
        self.userInfoView.addSubview(self.avatarImageView)
        self.userInfoView.addSubview(self.userNameLabel)
        self.userInfoView.addSubview(self.userCountryLabel)
        self.userInfoView.addSubview(self.userInfoTitleLabel)
        
        self.momentInfoView.addSubview(self.likeLabel)
        self.momentInfoView.addSubview(self.commentsView)
        self.commentsView.addSubview(self.commentsTitleLabel)
        self.commentsView.addSubview(self.commentsTextView)
    }
}
