//
//  FeedViewController.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit

// TODO: Import Parse Swift
import ParseSwift

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    //private let refreshControl=UIRefreshControl()
    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
       // tableView.refreshControl=refreshControl
        // refreshControl?.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        queryPosts()
    }

    private func queryPosts() {
        // TODO: Pt 1 - Query Posts
        //https://github.com/parse-community/Parse-Swift/blob/3d4bb13acd7496a49b259e541928ad493219d363/ParseSwift.playground/Pages/2%20-%20Finding%20Objects.xcplaygroundpage/Contents.swift#L66

        // 1. Create a query to fetch Posts
        // 2. Any properties that are Parse objects are stored by reference in Parse DB and as such need to explicitly use `include_:)` to be included in query results.
        // 3. Sort the posts by descending order based on the created at date
        let query = Post.query()
            .include("user","comments","comments.user")
            .order([.descending("createdAt")])
            //.where("createdAt">=yesterdayDate)
            //.limit(10)

        // Fetch objects (posts) defined in query (async)
        query.find { [weak self] result in
            switch result {
            case .success(let posts):
                // Update local posts property with fetched posts
                self?.posts = posts
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
            //completion?()
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

//    @objc private func onPullToRefresh(){
//        refreshControl?.beginRefreshing()
//        queryPosts{[weak self] in self?.refreshControl?.endRefreshing()}
//    }
    
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let post = posts[section]
            let comments = post.comments ?? []
            return comments.count + 2 // Post + Comments + 1 Add Comment cell
        }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
            }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = post.comments ?? []
        
        // First row should display the post
        if indexPath.row == 0 {
            guard let postCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell
            else {
                return UITableViewCell()
            }
            
            postCell.configure(with: post)
            return postCell
        } else if indexPath.row == 1 {
            // Add Comment cell
            guard let addCommentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell else {
                return UITableViewCell()
            }
            
            // Clear existing labels
            addCommentCell.nameLabel.text = nil
            addCommentCell.commentLabel.text = nil
            
            // Remove any existing addCommentLabel
            addCommentCell.contentView.viewWithTag(1001)?.removeFromSuperview()
            
            // Create and configure the add comment label
            let addCommentLabel = UILabel()
            addCommentLabel.text = "Add a comment..."
            addCommentLabel.textColor = .systemBlue
            addCommentLabel.isUserInteractionEnabled = true
            addCommentLabel.translatesAutoresizingMaskIntoConstraints = false
            addCommentLabel.tag = 1001 // Tag to identify the label
            addCommentCell.contentView.addSubview(addCommentLabel)
            
            // Add constraints to position the label within the cell
            NSLayoutConstraint.activate([
                addCommentLabel.leadingAnchor.constraint(equalTo: addCommentCell.contentView.leadingAnchor, constant: 16),
                addCommentLabel.trailingAnchor.constraint(equalTo: addCommentCell.contentView.trailingAnchor, constant: -16),
                addCommentLabel.topAnchor.constraint(equalTo: addCommentCell.contentView.topAnchor, constant: 8),
                addCommentLabel.bottomAnchor.constraint(equalTo: addCommentCell.contentView.bottomAnchor, constant: -8)
            ])
            
            // Add tap gesture recognizer to the label
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addCommentLabelTapped(_:)))
            addCommentLabel.addGestureRecognizer(tapGesture)
            
            return addCommentCell
        } else {
            // Comment cells
            guard let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? CommentCell
            else {
                return UITableViewCell()
            }

            let comment = comments[indexPath.row - 2]
            commentCell.nameLabel.text = comment.user?.username ?? "Unknown User"
            commentCell.commentLabel.text = comment.text ?? ""
            
            // Remove any "Add a comment" label if it exists
            commentCell.contentView.viewWithTag(1001)?.removeFromSuperview()
            
            return commentCell
        }
    }

    
    @objc private func addCommentLabelTapped(_ sender: UITapGestureRecognizer) {
        guard let label = sender.view as? UILabel,
              let cell = label.superview?.superview as? CommentCell,
              let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let post = posts[indexPath.section]
        showCommentInputAlert(for: post, at: indexPath.section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the selected row (visual effect)
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the post for the selected section
        let post = posts[indexPath.section]
        let comments = post.comments ?? []
        
        // Check if the tapped row is the "Add Comment" cell
        if indexPath.row == comments.count + 1 {
            // Show the input alert for adding a new comment
            showCommentInputAlert(for: post, at: indexPath.section)
        } else {
            // Handle selection of other cells (post or comment cell)
            print("Selected row: \(indexPath.row) in section: \(indexPath.section)")
        }
    }
    
    private func showCommentInputAlert(for post: Post, at index: Int) {
        // Create an alert controller with a text field
        let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .alert)
        
        // Add a text field to the alert for entering the comment
        alertController.addTextField { textField in
            textField.placeholder = "Enter your comment"
        }
        
        // Cancel action to dismiss the alert
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Submit action for when the user submits the comment
        // Submit action for when the user submits the comment
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let commentText = alertController.textFields?.first?.text, !commentText.isEmpty else {
                return
            }
            
            // Call saveComment method to save the new comment
            self?.saveComment(text: commentText, for: post, at: index)
        }
        
        // Add the submit action to the alert
        alertController.addAction(submitAction)
        
        // Present the alert to the user
        present(alertController, animated: true, completion: nil)
        
    }
    
    private func saveComment(text: String, for post: Post, at index: Int) {
            // Create a new comment
            var comment = Comments()
            comment.text = text
            comment.post = post
            comment.user = User.current

            // Save the comment
            comment.save { [weak self] result in
                switch result {
                case .success(let savedComment):
                    print("Comment saved successfully: \(savedComment)")
                    
                    // Update the post with the new comment
                    var updatedPost = post
                    if updatedPost.comments == nil {
                        updatedPost.comments = []
                    }
                    updatedPost.comments?.append(savedComment)
                    
                    updatedPost.save { [weak self] result in
                        switch result {
                        case .success(let savedPost):
                            print("Post updated with new comment: \(savedPost)")
                            
                            // Update local posts array and reload section
                            DispatchQueue.main.async {
                                self?.posts[index] = savedPost
                                self?.tableView.reloadSections(IndexSet(integer: index), with: .automatic)
                            }
                            
                        case .failure(let error):
                            print("Error saving post with comment: \(error)")
                        }
                    }
                    
                case .failure(let error):
                    assertionFailure("Error saving comment: \(error)")
                }
            }
        }
    }


extension FeedViewController: UITableViewDelegate { }
