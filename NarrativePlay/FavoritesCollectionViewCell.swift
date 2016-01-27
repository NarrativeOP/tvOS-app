import UIKit

class FavoritesCollectionViewCell: UICollectionViewCell {
    
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 550, height: 412))
    var hasAppeared = false
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.imageView)
    }
}
