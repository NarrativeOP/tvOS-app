import UIKit

class MomentCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 5, width: 100, height: 95))
    let overlayView = UIView(frame: CGRect(x: 0, y: 5, width: 100, height: 95))
    var hasAppeared = false
    var isInFocus = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.overlayView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
        
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.overlayView)
    }
}
