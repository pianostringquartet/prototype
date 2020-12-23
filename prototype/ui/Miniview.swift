//
//  Miniview.swift
//  prototype
//
//  Created by cjc on 12/14/20.
//

import Foundation
import SwiftUI
import ReSwift

struct FloatingWindow<ContentView: View>: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let content: ContentView
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(floatingWindowColor)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 4))
            .overlay(content)
            .frame(width: 275, height: 200) // better handling of size?
            .zIndex(2.0)
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                        }
                        .onEnded {  _ in
                            self.localPreviousPosition = self.localPosition
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .shadow(radius: 25)
        
    }
}
