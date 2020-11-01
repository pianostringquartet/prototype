//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI

func coloredCircle(color: Color, radius: CGFloat) -> some View {
    LinearGradient(gradient: Gradient(colors: [.white, color]),
                   startPoint: .topLeading,
                   endPoint: .bottomTrailing)
        .frame(width: radius, height: radius)
        .clipShape(Circle())
}

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}
    
// A ball that stays where you drag it
struct DraggableBall: View {
    
    // how far displaced in given gesture
    @State private var position = CGSize.zero
    
    @State private var previousPosition = CGSize.zero
        
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: color, radius: radius)
            
            // move ball as we drag
            .offset(x: self.position.width, y: self.position.height)
            
            // alternatively: move ball only after we let go
//            .offset(x: self.previousPosition.width, y: self.previousPosition.height)
            
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            
            // give ball some bounce
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


// A ball that bounces back to its original position
struct BoomerangBall: View {
    
    @State private var position = CGSize.zero
    
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: .black, radius: 125)
        .offset(position)
        .gesture(DragGesture()
                    .onChanged { self.position = $0.translation }
                    .onEnded { _ in
                        withAnimation(.spring()) { self.position = .zero }
                    })
    }
}


struct ContentView: View {
    
    var body: some View {
        VStack {
            BoomerangBall(color: .black, radius: 125)
            DraggableBall(color: .red, radius: 100)
            DraggableBall(color: .blue, radius: 75)
            DraggableBall(color: .green, radius: 50)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
