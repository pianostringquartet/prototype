//
//  Miniview.swift
//  prototype
//
//  Created by cjc on 12/14/20.
//

import Foundation
import SwiftUI
import ReSwift


//// the Miniviewer itself (later: floating window)
//struct Miniview: View {
//
//    // better?: miniview receives a (single) view to show,
//    //    let display: some View
//
//    var body: some View {
//
//        // hardcoding as
//    }
//}

// text that, when touched, changes color
// ie dispatches action to
struct TouchableText: View {
    
    let text: String
    let color: Color
    
    // also pass in state?
    let dispatch: Dispatch
    
    // better?: because we can pass in the action we want to call etc.
//    let onTap: () -> Void
    
    var body: some View {
        log("TouchableText called")
        Text(text)
            .font(.largeTitle)
            .foregroundColor(color.opacity(0.8))
            // should be: green as long as held down...
            // so ie more like .onTapBegin and .onTapEnded
            .onTapGesture(count: 1) {
                log("TouchableText tapped")
                dispatch(TextTappedMiniviewAction())
            }
    }
}



