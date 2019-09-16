import Foundation
import UIKit

protocol CellIdentifier {
    static var cellIdentifier: String { get }
}

class WordTableViewCell: UITableViewCell {
    @IBOutlet var wordLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        wordLabel.text = nil
    }
    
    func setWord(fromText text: String?) {
        wordLabel.text = text
    }
}

extension WordTableViewCell: CellIdentifier {
    static var cellIdentifier: String {
        return "WordTableViewCellIdentifier"
    }
}
