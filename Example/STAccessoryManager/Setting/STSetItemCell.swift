//
//  STSetItemCell.swift
//  STAccessoryManager_Beta
//
//  Created by zengsong on 2024/12/22.
//

import UIKit

class STSetItemCell: UITableViewCell {

    @IBOutlet weak var leftIcon: UIImageView!

    @IBOutlet weak var titLb: UILabel!

    @IBOutlet weak var rightIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        titLb.textColor = .black
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
