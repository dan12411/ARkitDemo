//
//  CollisionCategory.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/14.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import Foundation

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let bottom = CollisionCategory(rawValue: 1 << 0)
    static let cube = CollisionCategory(rawValue: 1 << 1)
}
