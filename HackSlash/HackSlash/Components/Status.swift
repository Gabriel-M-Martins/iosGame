//
//  Status.swift
//  HackSlash
//
//  Created by Pedro Mezacasa Muller on 15/05/23.
//

import Foundation
import SpriteKit

protocol Status {
    associatedtype T: SKSpriteNode
    var sprite: T{get set}
    var isBuffed: Bool {get set}
}
