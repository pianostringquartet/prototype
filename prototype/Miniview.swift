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


//struct FloatingWindow: View {
struct FloatingWindow<ContentView: View>: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let content: ContentView
    
    var body: some View {
        ZStack {
            content
        }
        .frame(minWidth: 275, minHeight: 200)
//        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 4)
        )
        .zIndex(2.0)
        .background(Color.white.opacity(0.9))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("FloatingWindow: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("FloatingWindow: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


// text that, when touched, changes color
// ie dispatches action to
//struct TouchableText: View {
//
//    let text: String
//    let color: Color
//
//    // also pass in state?
//    let dispatch: Dispatch
//
//    // better?: because we can pass in the action we want to call etc.
////    let onTap: () -> Void
//
//    var body: some View {
//        log("TouchableText called")
//        Text(text)
//            .font(.largeTitle)
//            .foregroundColor(color.opacity(0.8))
//            // should be: green as long as held down...
//            // so ie more like .onTapBegin and .onTapEnded
//            .onTapGesture(count: 1) {
//                log("TouchableText tapped")
//                dispatch(TextTappedMiniviewAction())
//            }
//    }
//}
//


