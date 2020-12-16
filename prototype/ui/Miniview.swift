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

// needs to always be placed somewhere
struct FloatingWindow<ContentView: View>: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let content: ContentView
    
    // first want a filled-white semi-opaque rectangle,
    // then overlay the `content`
    var body: some View {
        
        // base
        RoundedRectangle(cornerRadius: 16)
//            .fill(Color.white.opacity(0.9))
            .fill(Color.white.opacity(0.9))
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 4))
            .overlay(content)
            .frame(width: 275, height: 200) // better handling of size?
//            .frame(idealWidth: 275, idealHeight: 200)
            .zIndex(2.0)
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
    //                        log("FloatingWindow: onChanged")
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                        }
                        .onEnded {  _ in
                            // i.e. no anchoring for now
    //                        log("FloatingWindow: onEnded")
                            self.localPreviousPosition = self.localPosition
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .shadow(radius: 25)
        
    }
    
    
    var body3: some View {
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
//                        log("FloatingWindow: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
//                        log("FloatingWindow: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
        .shadow(radius: 5) // added
    }
}
