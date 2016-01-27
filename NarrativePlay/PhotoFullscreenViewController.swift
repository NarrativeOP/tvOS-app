import UIKit

class PhotoFullscreenViewController: UIViewController {
    
    // MARK: - Properties
    
    let photo: UIImage
    let backgroundImage: UIImage

    
    // MARK: - Initializer
    
    init(photo: UIImage, backgroundImage: UIImage, nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.photo = photo
        self.backgroundImage = backgroundImage
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(animated: Bool) { // viewDidAppear instead of viewDidLoad because of animation
        // Set Background
        self.view.backgroundColor = UIColor(patternImage: self.backgroundImage)
        
        // Create dark transparent overlay
        let overlayView = UIView(frame: super.view.frame)
        overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        
        // Create image view
        let imageView = UIImageView(frame: CGRectZero)
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        
        let height: CGFloat = 1060
        let width = self.photo.size.width / (self.photo.size.height / height)
        
        imageView.frame = CGRect(
            x: (1920.0 - width) / 2.0,
            y: (1080.0 - height) / 2.0,
            width: width,
            height: height
        )
        
        imageView.image = self.photo
        imageView.contentMode = .ScaleAspectFit
        
        // Add subviews
        self.view.addSubview(overlayView)
        self.view.addSubview(imageView)
        
        // Animate
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = NSNumber(float: 0.1)
        animation.toValue = NSNumber(float: 1.0)
        animation.duration = 0.2
        overlayView.layer.addAnimation(animation, forKey: "presentPhoto")
        imageView.layer.addAnimation(animation, forKey: "presentPhoto")
    }
    
    // MARK: - User interaction
    
    override func pressesBegan(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        // ignored
    }
    
    override func pressesEnded(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        for click in presses {
            if click.type == .Select {
                self.dismissViewControllerAnimated(false, completion: nil)
            }
        }
    }
    
    override func pressesChanged(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        // ignored
    }
    
    override func pressesCancelled(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        // ignored
    }
}
