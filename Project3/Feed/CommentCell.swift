import UIKit
import ParseSwift

class CommentCell: UITableViewCell{
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated:Bool){
        super.setSelected(selected, animated: animated)
    }
}
