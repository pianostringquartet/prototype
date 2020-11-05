//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation

/* ----------------------------------------------------------------
 UTILS
 ---------------------------------------------------------------- */

// For debug printing from simulator
func log(_ log: String) -> EmptyView {
    print("** \(log)")
    return EmptyView()
}

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


/* ----------------------------------------------------------------
 PREFERENCE DATA: passing data up from children to parent view
 ---------------------------------------------------------------- */

// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
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
 DOMAIN TYPES: representations of domain concepts
 ---------------------------------------------------------------- */

struct Connection: Identifiable, Equatable {
    let id: UUID = UUID()
    let from: Int
    let to: Int
    
    static func ==(lhs: Connection, rhs: Connection) -> Bool {
        // Edgeless connection:
        return lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from
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

// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}

struct Ball: View {
    @State private var position = CGSize.zero
    @State private var previousPosition = CGSize.zero
    @State private var isAnchored: Bool = true // true just iff ball has NEVER 'been moved enough'
        
    @Binding public var connections: [Connection]
    @Binding public var nodeCount: Int
    @Binding public var connectingNode: Int?
    
    // Node info
    @State private var info: UUID = UUID()
    @State private var showPopover: Bool = false
    
    let nodeNumber: Int
    let radius: CGFloat
    
    init(nodeNumber: Int, radius: CGFloat, connections: Binding<[Connection]>, nodeCount: Binding<Int>, connectingNode: Binding<Int?>) {
        self.nodeNumber = nodeNumber
        self.radius = radius
        self._connections = connections
        self._nodeCount = nodeCount
        self._connectingNode = connectingNode
    }
     
    private func determineColor() -> Color {
        if connectingNode == nodeNumber {
            return Color.pink
        }
        else if !isAnchored {
            return Color.blue
        }
        else {
            return
                position == CGSize.zero ?
                    Color.white.opacity(0) :
                    Color.blue.opacity(0 + Double((abs(position.height) + abs(position.width)) / 99))
        }
    }
    
    var body: some View {
        Circle().stroke(Color.black)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack (spacing: 20) {
                    Text("Node Number: \(nodeNumber)")
                    Text("Node ID: \(info)")
                }
                .padding()
            }
            .background(Image(systemName: "plus"))
            .overlay(LinearGradient(gradient: Gradient(colors: [
                                                        // white of opacity 0 means: 'invisible'
                                                        position == CGSize.zero ? Color.white.opacity(0) : Color.white,
                                                           determineColor()]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                ))
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
            .frame(width: radius, height: radius)
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: { [BallPreferenceData(viewIdx: self.nodeNumber, center: $0)] })
            .offset(x: self.position.width, y: self.position.height)
            .gesture(DragGesture()
                        .onChanged { self.position = updatePosition(value: $0, position: self.previousPosition) }
                        .onEnded { (value: DragGesture.Value) in
                            if isAnchored {
                                let minDistance: CGFloat = CGFloat(90)
                                // Did we move the node enough for it to become a free, de-anchored node?
                                let movedEnough: Bool =
                                    abs(value.translation.width) > minDistance ||
                                    abs(value.translation.height) > minDistance
                                if movedEnough {
                                    self.isAnchored.toggle()
                                    self.previousPosition = self.position
                                    self.nodeCount += 1
                                    playSound(sound: "positive_ping", type: "mp3")
                                }
                                else {
                                    withAnimation(.spring()) { self.position = .zero }
                                }
                            }
                            else {
                                self.previousPosition = self.position
                            }
                        })
        
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .onTapGesture(count: 2, perform: {
                if !isAnchored {
                    self.showPopover.toggle()
                }
            })
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                if !isAnchored {
                    let existsConnectingNode: Bool = connectingNode != nil
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode == nodeNumber
                    
                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
                        self.connectingNode = self.nodeNumber
                    }
                    else { // ie there is an connecting node:
                        let edge: Connection = Connection(from: connectingNode!, to: self.nodeNumber)
                        let edgeAlreadyExists: Bool = connections.contains(edge)
                        
                        // if exist connecting node and I am the connecting node, cancel ie set connecting node=nil
                        if isConnectingNode {
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
                            self.connections = connections.filter { $0 != edge }
                            self.connectingNode = nil
                            playSound(sound: "connection_removed", type: "mp3")
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            self.connections.append(edge)
                            self.connectingNode = nil
                            playSound(sound: "connection_added", type: "mp3")
                        }
                    }
                }
            })
    }
}


/* ----------------------------------------------------------------
 CONTENT VIEW
 ---------------------------------------------------------------- */

struct ContentView: View {
    @State private var nodeCount: Int = 1 // start with one node
    
    // all existings edges
    @State public var connections: [Connection] = []

    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil

    var body: some View {
        VStack { // HACK: bottom right corner alignment
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    ForEach(1 ..< nodeCount + 1, id: \.self) { nodeNumber -> Ball in
                        Ball(nodeNumber: nodeNumber,
                            radius: 60,
                            connections: $connections,
                            nodeCount: $nodeCount,
                            connectingNode: $connectingNode)
                        
                    }.padding(.trailing, 30).padding(.bottom, 30)
                }
            }
        }
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && nodeCount >= 2 {
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        // Note: we must convert the node number to an index position
                        let toPref: BallPreferenceData = preferences[connection.to - 1]
                        let fromPref: BallPreferenceData = preferences[connection.from - 1]
                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
                        
                    })
                }
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

