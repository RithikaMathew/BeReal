//
//  Post.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/29/22.
//

import Foundation

// TODO: Pt 1 - Import Parse Swift
import ParseSwift

// TODO: Pt 1 - Create Post Parse Object model
//https://github.com/parse-community/Parse-Swift/blob/3d4bb13acd7496a49b259e541928ad493219d363/ParseSwift.playground/Pages/1%20-%20Your%20first%20Object.xcplaygroundpage/Contents.swift#L33


struct Post: ParseObject {
    // These are required by ParseObject
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Your own custom properties.
    var caption: String?
    var user: User?
    var imageFile: ParseFile?
    var location: String?
    var timeDifference: String? // Add this line

    mutating func setPublicReadACL() {
           self.ACL = ParseACL()
           self.ACL?.publicRead = true // Allow all users to read
       }
    //array of pointer to comments
    var comments: [Comments]?
    
    // Method to add a comment
        mutating func addComment(_ comment: Comments) {
            if comments == nil {
                comments = [Comments]()
            }
            comments?.append(comment)
        }
}
