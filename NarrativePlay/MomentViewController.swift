import UIKit
import Alamofire

class MomentViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    // Change preferred focus view
    override weak var preferredFocusedView: UIView? {
        
        return self.momentCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: self.focusIndex, inSection: 0))
    }
    
    // MARK: - Properties
    
    var momentCollectionView: UICollectionView!

    var typeOfMoment: TypeOfMoment
    var photosURL: String
    let backgroundImage: UIImage
    
    var totalNumberOfPhotos = 1
    var photoLoadIndex = 0
    var momentImageURLs = [String]()
    var momentImages = [UIImage?]()
    
    var doneLoading = false
    var loadFirstImages = true
    var firstIteration = true
    
    // MARK: - Initializer
    
    init(typeOfMoment: TypeOfMoment, photosURL: String, startIndex: Int, backgroundImage: UIImage, nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.typeOfMoment = typeOfMoment
        self.photosURL = photosURL
        self.backgroundImage = backgroundImage
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        self.setupScreen()
        self.fetchPhotoURLs(self.photosURL)
        print(Authorization.getAuthHeaders())
    }
    
    override func viewDidAppear(animated: Bool) {
        self.animateLoadingLabel(self.loadingLabel)
    }
    
    // MARK: - Methods
    func fetchPhotoURLs(requestURL: String) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            // Fetch moments from server
            print("REQUEST")
            print(requestURL)
            
            Alamofire.request(.GET, requestURL, headers: Authorization.getAuthHeaders()).responseJSON { (response: Response<AnyObject, NSError>) -> Void in
                
                print("Trying to connect to Narrative servers...")
                
                if let result = response.result.value as? [String: AnyObject], let photos = result["results"] as? NSMutableArray, let photoCount = result["count"] as? Int {
                    
                    // Dismiss view controller if there are no photos
                    if photoCount == 0 {
                        self.dismissViewControllerAnimated(false, completion: nil)
                    }
                    
                    // Populate URL and image arrays
                    if self.firstIteration == true {
                        self.momentImages = [UIImage?](count: photoCount, repeatedValue: nil)
                        self.momentImageURLs = [String](count: photoCount, repeatedValue: "nil")
                        self.firstIteration = false
                    }

                    // Load photo URLs and check if there are more photo pages
                    if let nextURL = result["next"] as? String {
                        for photo in photos {
                            let photoRenderURL = photo["renders"]!!["g1_hd"]!!["url"] as! String
                            self.momentImageURLs[self.photoLoadIndex] = photoRenderURL
                            self.photoLoadIndex++
                        }
                        
                        if self.loadFirstImages == true {
                            self.loadFirstImages = false
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.momentCollectionView.reloadData()
                                var limit: Int
                                if self.momentImages.count < 30 {
                                    limit = self.momentImages.count
                                } else {
                                    limit = 29
                                }
                                
                                for i in 0...limit {
                                    self.getMomentImage(self.momentImageURLs, index: i)
                                }
                            })
                        }
                        
                        // Load next page
                        self.fetchPhotoURLs(nextURL)
                        
                    } else {
                        // Load last (or only) page
                        for photo in photos {
                            let photoRenderURL = photo["renders"]!!["g1_hd"]!!["url"] as! String
                            self.momentImageURLs[self.photoLoadIndex] = photoRenderURL
                            self.photoLoadIndex++
                        }
                        
                        if self.loadFirstImages == true {
                            self.loadFirstImages = false
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.momentCollectionView.reloadData()
                                var limit: Int
                                if self.momentImages.count < 30 {
                                    limit = self.momentImages.count - 1
                                } else {
                                    limit = 29
                                }
                                
                                for i in 0...limit {
                                    self.getMomentImage(self.momentImageURLs, index: i)
                                }
                            })
                        }
                        
                        print("Images count: \(self.momentImages.count)")
                    }
                }
            }
        })
    }
    
    func getMomentImage(imageURLs: [String], index: Int) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            // Get photo URL
            let photoURL = imageURLs[index]
            
            // Get photo data
            if let photoData = NSData(contentsOfURL: NSURL(string: photoURL)!) {
                if let photoImage = UIImage(data: photoData) {
                    guard self.momentImages.count != 0 else { return }
                    
                    // Add photo to moment images
                    self.momentImages[index] = photoImage
                    
                    // Update layout in main queue
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateCollectionViewCellAtIndex(index)
                        if self.doneLoading == false {
                            
                            // Show first image
                            if index < 2 {
                                self.updateImageView(0)
                                if let cell = self.momentCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? MomentCollectionViewCell {
                                    cell.overlayView.backgroundColor = UIColor.clearColor()
                                    cell.backgroundColor = UIColor.whiteColor()
                                }
                            }
                            
                            // Dismiss loading view when 29 first images (or half of the images if total is less than 29) has appeared.
                            if index == 29 || index == self.momentImages.count / 2 {
                                self.momentCollectionView.userInteractionEnabled = true
                                self.dismissViewWithAnimation(self.loadingView)
                                self.doneLoading = true
                            }
                        }
                    }) // END MAIN
                }
            }
        }) // END BG
    }
    
    func updateCollectionViewCellAtIndex(index: Int) {
        if let _ = momentCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as? MomentCollectionViewCell {
            self.momentCollectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)])
        }
    }
    
    func updateImageView(index: Int) {
        if let image = self.momentImages[index] {
            let height: CGFloat = self.momentIsCurrentlyPlaying == true ? 1040 : 960
            let width           = image.size.width / (image.size.height / height)
            let xPos            = (1920.0 - width) / 2.0
            let yPos            = (1080.0 - height) / 2.0
            
            self.mainPhotoImageView.frame = CGRect(
                x: xPos,
                y: self.momentIsCurrentlyPlaying == true ? yPos : (yPos - 50),
                width: width,
                height: height
            )
            
            self.mainPhotoImageView.image = image
            self.mainPhotoImageView.contentMode = .ScaleAspectFit
        }
    }
    
    // MARK: - Views
    
    let loadingLabel = UILabel(frame: CGRect(x: 0, y: 440, width: 1920, height: 100))
    
    lazy var loadingView: UIView = {
        let loadingView = UIView(frame: self.view.frame)
        loadingView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        self.loadingLabel.font = UIFont.avenirMediumWithSize(40.0)
        self.loadingLabel.text = "Just a sec"
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
    
    lazy var mainPhotoImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRectZero)
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        
        return imageView
    }()
    
    lazy var photoCountLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 1595, y: 950, width: 300, height: 20))
        label.font = UIFont.avenirHeavyWithSize(18.0)
        label.textColor = UIColor.whiteColor().colorWithAlphaComponent(0.6)
        label.textAlignment = .Right
        
        return label
    }()
    
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
    
    // MARK: - User Interaction: Press "Play"
    
    var focusIndex = 0
    var momentIsCurrentlyPlaying = false
    
    override func pressesBegan(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        for item in presses {
            
            // Identify that user press "Play" button
            if item.type == .PlayPause {
                
                // Stop playing moment if it's currently playing when pressing Play
                guard self.momentIsCurrentlyPlaying == false else {
                    self.stopPlayback()
                    
                    return
                }
                
                // Find currently focused index
                for index in 0..<self.momentImages.count {
                    if let cell = self.momentCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) {
                        if cell.focused == true {
                            
                            // Hide collection view and photo count label
                            self.momentCollectionView.alpha = 0.1
                            self.photoCountLabel.hidden = true
                            
                            // Moment is now playing
                            self.momentIsCurrentlyPlaying = true
                            
                            // Perform update
                            self.pressedPlay(index + 1)
                        }
                    }
                }
            }
        }
    }

    // TODO: - Make new images load even if collection view is hidden
    func pressedPlay(index: Int) {
        
        // Return if moment it's not playing anymore and if index has reached end of moment
        guard self.momentIsCurrentlyPlaying == true && self.focusIndex < self.momentImages.count - 1 else { self.stopPlayback(); return }
        
        // Update screen
        self.focusIndex = index
        self.setNeedsFocusUpdate()
        
        // Show next image
        na_perform({ () -> Void in
            self.pressedPlay(index + 1)
        }, afterDelay: 0.5)
    }
    
    func stopPlayback() {
        
        // Show collection view photo count label
        self.momentCollectionView.alpha = 1.0
        self.photoCountLabel.hidden = false
        
        // Moment is not playing anymore
        self.momentIsCurrentlyPlaying = false
        
        // Update screen to set current image to correct size
        self.updateImageView(self.focusIndex)
    }
    
    override func pressesEnded(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        for item in presses {
            if item.type == .Select {
                // Nathink
            }
        }
    }
    
    override func pressesChanged(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        // ignored
    }
    
    override func pressesCancelled(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        for item in presses {
            if item.type == .Select {
                // Nathink
            }
        }
    }
    
    // MARK: - Collection View
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.momentImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        // Declare cell and index
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("favCell", forIndexPath: indexPath) as! MomentCollectionViewCell
        let index = indexPath.row

        // Initial setup for cells
        guard cell.hasAppeared == false else { return cell }

        if let imageAtIndex = self.momentImages[index] {
            cell.imageView.image = imageAtIndex
            cell.hasAppeared = true
        } else {
            cell.imageView.backgroundColor = UIColor.clearColor()
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // Dismiss view controller
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Handle focus updates
    func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
        
        // Early return if moment hasn't finished loading
        guard self.doneLoading == true else { return }
    
        // Set index
        if let index = context.nextFocusedIndexPath?.row {
            self.focusIndex = index
            
            // Early return if image array is empty
            guard self.momentImages.count != 0 else { return }
            
            // Update main image view
            self.updateImageView(self.focusIndex)
            
            // Load new image
            if self.focusIndex + 29 < self.momentImages.count {
                if self.momentImages[focusIndex + 29] == nil {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                        self.getMomentImage(self.momentImageURLs, index: self.focusIndex + 29)
                    })
                }
            }
            
            // Update photo count label
            self.photoCountLabel.text = "Showing photo \(focusIndex + 1) of \(self.momentImages.count)"
            
            // TODO: - Code below is a workaround. Change when possible
            
            // Set focus range
            var low = self.focusIndex - 15
            var high = self.focusIndex + 15
            
            if low < 0 { low = 0 }
            if high > self.momentImages.count - 1 { high = self.momentImages.count - 1 }
            
            // Update cell views
            for i in low...high {
                
                // Declare cell and cell index
                if let cell = self.momentCollectionView.cellForItemAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as? MomentCollectionViewCell {
                    if let cellIndex = self.momentCollectionView.indexPathForCell(cell)?.row {
                        
                        // Update focused cell
                        if cell.focused {
                            cell.overlayView.backgroundColor = UIColor.clearColor()
                            cell.backgroundColor = UIColor.whiteColor()
                            cell.imageView.image = self.momentImages[cellIndex]
                            
                        // Update unfocused cells
                        } else {
                            cell.backgroundColor = UIColor.clearColor()
                            cell.overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
                            cell.imageView.image = self.momentImages[cellIndex]
                        }
                    }
                }
            }
            
            // Clear faulty focused thumbs
            na_perform({ () -> Void in
                for cell in self.momentCollectionView.visibleCells() {
                    if let currentCell = cell as? MomentCollectionViewCell {
                        if currentCell.focused == false {
                            currentCell.backgroundColor = UIColor.clearColor()
                            currentCell.overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
                        }
                    }
                }
            }, afterDelay: 0.2)
        }
    }

    // MARK: - Layout
    
    func setupScreen() {
        let darkView = UIView()
        darkView.frame = super.view.frame
        darkView.backgroundColor = UIColor(patternImage: UIImage(named: "redBackground")!).colorWithAlphaComponent(0.9)
        
        self.view.backgroundColor = UIColor(patternImage: self.backgroundImage)
        
        // Collection view and layout
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .Horizontal
        layout.itemSize = CGSize(width: 100, height: 100)
        
        self.momentCollectionView = UICollectionView(frame: CGRect(x: 0, y: 980, width: 1920, height: 100), collectionViewLayout: layout)
        self.momentCollectionView.dataSource = self
        self.momentCollectionView.delegate = self
        self.momentCollectionView.registerClass(MomentCollectionViewCell.self, forCellWithReuseIdentifier: "favCell")
        self.momentCollectionView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.25)
        self.momentCollectionView.userInteractionEnabled = false
        
        self.view.addSubview(darkView)
        self.view.addSubview(self.momentCollectionView)
        self.view.addSubview(self.mainPhotoImageView)
        self.view.addSubview(self.photoCountLabel)
        self.view.addSubview(self.loadingView)
    }
}
