//
//  LevelInfo.swift
//  HackSlash
//
//  Created by Gabriel Medeiros Martins on 18/05/23.
//

import Foundation

struct LevelInfo {
    let background: String
    let enemiesQtd: Int
    let mapFile: String
    let spawnRate: Double
}

enum Levels: CaseIterable {
    case Tutorial, Level1, Level2, Level3, Level4
    
    func getInfo() -> LevelInfo {
        switch self {
        case .Tutorial:
            return LevelInfo(background: "MainScene", enemiesQtd: 1, mapFile: "map2", spawnRate: 2)
        case .Level1:
            return LevelInfo(background: "MainScene", enemiesQtd: 5, mapFile: "map1", spawnRate: 3)
        case .Level2:
            return LevelInfo(background: "MainScene", enemiesQtd: 10, mapFile: "map1", spawnRate: 2)
        case .Level3:
            return LevelInfo(background: "MainScene", enemiesQtd: 15, mapFile: "map1", spawnRate: 1)
        case .Level4:
            return LevelInfo(background: "MainScene", enemiesQtd: 20, mapFile: "map1", spawnRate: 0.75)
        }
    }
    
    func name() -> String {
        switch self {
        case .Tutorial:
            return "Tutorial"
        case .Level1:
            return "Level 1"
        case .Level2:
            return "Level 2"
        case .Level3:
            return "Level 3"
        case .Level4:
            return "Level 4"
        }
    }
}
