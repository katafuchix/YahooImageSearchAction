//
//  ImageItemCell.swift
//  YahooImageSearchAction
//
//  Created by cano on 2018/10/04.
//  Copyright © 2018年 developer. All rights reserved.
//

import UIKit
import AlamofireImage

class ImageItemCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!

    func configure(_ url: URL) {
        self.imageView.af_setImage(withURL: url)
    }
}
