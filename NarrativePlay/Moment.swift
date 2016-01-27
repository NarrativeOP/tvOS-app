import UIKit
import Foundation

public class Moment {
    
    let user: User!
    
    let numberOflikes: Int
    
    let mainPhoto: UIImage!
    let smallPhotoOne: UIImage!
    let smallPhotoTwo: UIImage!
    
    let caption: String
    let timeAndPlace: String
    let commentUser: String?
    let commentText: String?
    let photosURL: String
    
    
    init(
        user: User,
        numberOfLikes: Int,
        mainPhoto: UIImage,
        smallPhotoOne: UIImage,
        smallPhotoTwo: UIImage,
        caption: String,
        timeAndPlace: String,
        commentUser: String?,
        commentText: String?,
        photosURL: String
        )
    {
        self.user = user
        self.numberOflikes = numberOfLikes
        self.mainPhoto = mainPhoto
        self.smallPhotoOne = smallPhotoOne
        self.smallPhotoTwo = smallPhotoTwo
        self.caption = caption
        self.timeAndPlace = timeAndPlace
        self.commentUser = commentUser
        self.commentText = commentText
        self.photosURL = photosURL
    }
}
