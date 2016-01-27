import UIKit

class MainCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 120, height: 120))
    var hasAppeared = false

    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.imageView)
    }
}
