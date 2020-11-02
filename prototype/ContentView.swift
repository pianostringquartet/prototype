import SwiftUI

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
    let isEnabled: Bool
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

func line(from: CGPoint, to: CGPoint) -> some View {
    Line(from: from, to: to).stroke().animation(.default)
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
    
    @State private var isEnabled: Bool = true
    
    let idx: Int
    let color: Color
    let radius: CGFloat
    
    var body: some View {
        coloredCircle(color: isEnabled ? color : Color.gray,
                      radius: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.idx,
                                                               center: $0,
                                                               isEnabled: isEnabled )] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { _ in self.previousPosition = self.position })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .onTapGesture(count: 2, perform: {
                self.isEnabled.toggle()
            })
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */
 
struct ContentView: View {
    
    @State private var ballCount = 3
    
    var body: some View {
        VStack (spacing: CGFloat(25)) {
            ForEach(0 ..< ballCount, id: \.self) { count -> EdgeBall in
                EdgeBall(idx: count, color: .red, radius: 25)
            }
            Button(action: {
                self.ballCount += 1
            }) {
                Text("Create node")
            }
            Button(action: {
                self.ballCount -= 1
            }) {
                Text("Remove node")
            }
            
        }.backgroundPreferenceValue(BallPreferenceKey.self) { preferences in
             GeometryReader { geometry in
                ForEach(preferences, content: { (pref: BallPreferenceData) in
                    // Only draw edge if at least two nodes and node is enabled
                    if preferences.count >= 2 && pref.isEnabled {
                        let currentPreference = preferences[pref.viewIdx]
                        ForEach(preferences, content: { (pref2: BallPreferenceData) in
                            let additionalPreference = preferences[pref2.viewIdx]
                            // Only draw edge is both nodes enabled
                            if additionalPreference.isEnabled && currentPreference.isEnabled {
                                line(from: geometry[currentPreference.center],
                                     to: geometry[additionalPreference.center])
                            }
                        } )
                    }
                })
            }}
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
