//
//  PostCell.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var dp: UILabel!
    
    private var imageDataRequest: DataRequest?
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))

    override func awakeFromNib() {
        super.awakeFromNib()
        // Configure dp label as a rounded circle
        dp.layer.cornerRadius = dp.frame.size.width / 2
        dp.clipsToBounds = true
        dp.layer.borderWidth = 1 // Optional: if you want a border
        dp.layer.borderColor = UIColor.lightGray.cgColor // Optional: border color
    
        // Configure blur view
                blurView.frame = postImageView.bounds
                blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                blurView.isHidden = true // Start with the blur view hidden
                postImageView.addSubview(blurView)
    }

    func configure(with post: Post) {
        // TODO: Pt 1 - Configure Post Cell
        // Username
        if let user = post.user {
                    usernameLabel.text = user.username
            let initials = getInitials(from: user.username!)
                    dp.text = initials
                }
        
        // Combine Location and calculated Time Difference
                if let locationText = post.location, let createdAt = post.createdAt {
                    let timeDifference = calculateTimeDifference(from: createdAt)
                    location.text = "\(locationText) - \(timeDifference)"
                } else if let locationText = post.location {
                    location.text = locationText
                } else if let createdAt = post.createdAt {
                    location.text = calculateTimeDifference(from: createdAt)
                } else {
                    location.text = "Location and time not available"
                }
        
        
        
        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            
            // Use AlamofireImage helper to fetch remote image from URL
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    // Set image view image with fetched image
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                    break
                }
            }
        }

        // Caption
        captionLabel.text = post.caption

        // Date
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.postFormatter.string(from: date)
        }
        
        // TODO: Pt 2 - Show/hide blur view
        // A lot of the following returns optional values so we'll unwrap them all together in one big `if let`
        // Get the current user.
        if let currentUser = User.current,

            // Get the date the user last shared a post (cast to Date).
           let lastPostedDate = currentUser.lastPostedDate,

            // Get the date the given post was created.
           let postCreatedDate = post.createdAt,

            // Get the difference in hours between when the given post was created and the current user last posted.
           let diffHours = Calendar.current.dateComponents([.hour], from: postCreatedDate, to: lastPostedDate).hour {
            // Debugging Output
                    print("Current User Last Posted Date: \(lastPostedDate)")
                    print("Post Created Date: \(postCreatedDate)")
                    print("Difference in Hours: \(diffHours)")
            // Hide the blur view if the given post was created within 24 hours of the current user's last post. (before or after)
            blurView.isHidden = abs(diffHours) < 24
        } else {

            // Default to blur if we can't get or compute the date's above for some reason.
            blurView.isHidden = false
        }

    }

    // Calculate time difference from post's createdAt date to now
        func calculateTimeDifference(from date: Date) -> String {
            let timeInterval = Date().timeIntervalSince(date)

            let minutes = Int(timeInterval / 60)
            let hours = minutes / 60
            let days = hours / 24

            if days > 0 {
                return "\(days) day(s) ago"
            } else if hours > 0 {
                return "\(hours) hour(s) ago"
            } else if minutes > 0 {
                return "\(minutes) minute(s) ago"
            } else {
                return "Just now"
            }
        }
    
     func getInitials(from username: String) -> String {
        // Split the username into words by spaces
        let words = username.split(separator: " ")
        
        // Get the first letter of each word, limit to two initials
        let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }.joined()
        
        return initials.uppercased()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // TODO: P1 - Cancel image download
        // Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()
    }
}
