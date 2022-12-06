//
//  ARObjectListCell.swift
//  Augmented-Reality -Decorateor
//
//  Created by Technobrains on 06/12/22.
//

import UIKit

class ARObjectListCell: UICollectionViewCell {
    @IBOutlet var imgARObject:UIImageView!{
        didSet{
            imgARObject.layer.cornerRadius = 10
            imgARObject.clipsToBounds = true
        }
    }
}

