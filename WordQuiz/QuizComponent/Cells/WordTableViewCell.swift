import Foundation
import UIKit

protocol CellIdentifier {
    static var cellIdentifier: String { get }
}

class WordTableViewCell: UITableViewCell {
    @IBOutlet var wordLabel: UILabel!
    
    func setWord(fromText text: String) {
        wordLabel.text = text
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension WordTableViewCell: CellIdentifier {
    static var cellIdentifier: String {
        get {
            return "WordTableViewCellIdentifier"
        }
    }
}
