//
//  Util.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import Foundation
import SwiftUI
import AVFoundation


// FUNCTIONS THAT HAVE NOTHING TO DO WITH DOMAIN LOGIC


/* ----------------------------------------------------------------
 Helper functions
 ---------------------------------------------------------------- */

func identity<T>(t: T) -> T {
    return t
}

// can't quite get this to work...
//func ascending<T: Comparable & Identifiable>(x: T, y: T) -> Bool {
//    return x.id < y.id
//}

func replace<T: Identifiable>(ts: [T], t: T) -> [T] {
    var ts = ts
    ts.removeAll { $0.id == t.id }
    ts.append(t)
    return ts
}


/* ----------------------------------------------------------------
 Utility extensions
 ---------------------------------------------------------------- */

// TODO: Debug why this is failing

//extension Color: Codable {
//    enum CodingKeys: String, CodingKey {
//        case red, green, blue
//    }
//
//    public init(from decoder: Decoder) throws {
//        log("Color: Codable: decoder")
//
//        // this is causing problems
//
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        log("container: \(container)")
//
//        // ^^ we can get here, but not below
//
//        let r = try container.decode(Double.self, forKey: .red)
//        log("r: \(r)")
//
//        let g = try container.decode(Double.self, forKey: .green)
//        log("g: \(g)")
//
//        let b = try container.decode(Double.self, forKey: .blue)
//        log("b: \(b)")
//
//        log("r, g, b: \(r), \(g), \(b)")
//
//        self.init(red: r, green: g, blue: b)
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        log("Color: Codable: encoder")
//        guard let cgColor = self.cgColor,
//              let colorSpace = cgColor.colorSpace,
//              let components = cgColor.components else {
//
//            return
//        }
//
//        var container = encoder.container(keyedBy: CodingKeys.self)
//
//        let model = colorSpace.model
//
//        switch model {
//        case .rgb:
//            try container.encode(components[0], forKey: .red)
//            try container.encode(components[1], forKey: .green)
//            try container.encode(components[2], forKey: .blue)
//        default:
//            fatalError("Consider implementing other models")
//        }
//    }
//}


/* ----------------------------------------------------------------
 Logging
 ---------------------------------------------------------------- */

// For debug printing from within SwiftUI views
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}


/* ----------------------------------------------------------------
 Playing sounds
 ---------------------------------------------------------------- */

var audioPlayer: AVAudioPlayer?

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        } catch {
            log("Unable to play sound.")
        }
    }
}
