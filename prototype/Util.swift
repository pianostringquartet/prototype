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

//func ascending(x: Identifiable, y: Identifiable) -> Bool {
//    x.id < y.id
//}

func replace<T: Identifiable>(ts: [T], t: T) -> [T] {
    var ts = ts
    
//    log("replace: ts was: \(ts)")
    
    ts.removeAll { $0.id == t.id }
    ts.append(t)
    
//    log("replace: ts is now: \(ts)")
    
    return ts
}


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
