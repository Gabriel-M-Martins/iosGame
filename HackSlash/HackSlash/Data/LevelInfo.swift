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
    case Tutorial, Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10
    
    func getInfo() -> LevelInfo {
        switch self {
        case .Tutorial:
            return LevelInfo(background: "MainScene", enemiesQtd: 1, mapFile: "map2", spawnRate: 2)
        case .Level1:
            return LevelInfo(background: "MainScene", enemiesQtd: 5, mapFile: "map1", spawnRate: 3)
        case .Level2:
            return LevelInfo(background: "MainScene", enemiesQtd: 7, mapFile: "map4", spawnRate: 2)
        case .Level3:
            return LevelInfo(background: "MainScene", enemiesQtd: 12, mapFile: "map1", spawnRate: 1)
        case .Level4:
            return LevelInfo(background: "MainScene", enemiesQtd: 15, mapFile: "map3", spawnRate: 0.90)
        case .Level5:
            return LevelInfo(background: "MainScene", enemiesQtd: 20, mapFile: "map5", spawnRate: 0.80)
        case .Level6:
            return LevelInfo(background: "MainScene", enemiesQtd: 22, mapFile: "map4", spawnRate: 0.75)
        case .Level7:
            return LevelInfo(background: "MainScene", enemiesQtd: 24, mapFile: "map6", spawnRate: 0.70)
        case .Level8:
            return LevelInfo(background: "MainScene", enemiesQtd: 20, mapFile: "map7", spawnRate: 0.50)
        case .Level9:
            return LevelInfo(background: "MainScene", enemiesQtd: 22, mapFile: "map3", spawnRate: 0.55)
        case .Level10:
            return LevelInfo(background: "MainScene", enemiesQtd: 24, mapFile: "map6", spawnRate: 0.60)
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
        case .Level5:
            return "Level 5"
        case .Level6:
            return "Level 6"
        case .Level7:
            return "Level 7"
        case .Level8:
            return "Level 8"
        case .Level9:
            return "Level 9"
        case .Level10:
            return "Level 10"
        }
    }
}
