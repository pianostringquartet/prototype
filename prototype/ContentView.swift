//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI

/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData {
    let viewIdx: Int
    let center: Anchor<CGPoint>
}

// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]
    
    static var defaultValue: [BallPreferenceData] = []
    
    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
    
}


/* ----------------------------------------------------------------
 UI ELEMENTS: draggable balls, etc.
 ---------------------------------------------------------------- */

struct Line: Shape {
    let from, to: CGPoint
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: self.from)
            p.addLine(to: self.to)
        }
    }
}

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
 
struct EdgeBall: View {
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    
    let idx: Int
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: color, radius: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.idx, center: $0)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

struct ContentView: View {
    let spacing: CGFloat = 100
    var body: some View {
        VStack (spacing: spacing) {
            EdgeBall(idx: 0, color: .purple, radius: 75)
            HStack (spacing: spacing) {
                EdgeBall(idx: 1, color: .pink, radius: 50)
                EdgeBall(idx: 2, color: .green, radius: 75)
            }
            EdgeBall(idx: 3, color: .blue, radius: 50)
        }
        
        // parent uses preference data to know about balls' relative centers
        .backgroundPreferenceValue(BallPreferenceKey.self) { preferences in
            
            // use GeometryReader to get absolute center of ball
            GeometryReader { geometry in
                // TODO: cleaner, programmatic construction of edges
                let point0 = geometry[preferences[0].center]
                let point1 = geometry[preferences[1].center]
                let point2 = geometry[preferences[2].center]
                let point3 = geometry[preferences[3].center]
                
                // Create any arbitrary connection:
                Line(from: point0, to: point1).stroke().animation(.default)
                Line(from: point1, to: point2).stroke().animation(.default)
                Line(from: point2, to: point3).stroke().animation(.default)
                Line(from: point0, to: point3).stroke().animation(.default)
                Line(from: point1, to: point3).stroke().animation(.default)
            }
        }
    }
}


/* ----------------------------------------------------------------
 PREVIEW
 ---------------------------------------------------------------- */

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
