//
//  Shapes.swift
//  prototype
//
//  Created by cjc on 11/8/20.
//

import Foundation
import SwiftUI
import ReSwift


/* ----------------------------------------------------------------
 UI ELEMENTS: draggable nodes, drawn edges etc.
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
    @Environment(\.managedObjectContext) var moc
    
//    @Binding private var nodeCount: Int
    @Binding private var connectingNode: Int? // not persisted
    
    // node info
    @State private var info: UUID = UUID()
    @State private var showPopover: Bool = false // not persisted
    
    private var node: Node
    
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let graphId: Int
    
    let connections: [Connection]
    

    // minimum distance for plus-sign to be dragged to become committed as a node
    let minDistance: CGFloat = CGFloat(90)
    
    let dispatch: Dispatch

    init(
//        nodeCount: Binding<Int>, // shouldn't need this anymore
         connectingNode: Binding<Int?>,
         node: Node,
         graphId: Int, // don't need to pass graphID -- the node will have it
         connections: [Connection],
         dispatch: @escaping Dispatch
    ) {
//        self._nodeCount = nodeCount // not used?
        self._connectingNode = connectingNode
        
        self.node = node
                
        // use node's position directly
        self._localPosition = State.init(initialValue: node.position)
        self._localPreviousPosition = State.init(initialValue: node.position)
        
        
        self.graphId = graphId
        
        self.connections = connections
        self.dispatch = dispatch
    }
    
    private func determineColor() -> Color {
        if connectingNode != nil && connectingNode! == node.nodeId {
            return Color.pink
        }
        else if !node.isAnchored {
            return Color.blue
        }
        else {
            return localPosition == CGSize.zero ?
                Color.white.opacity(0) :
                Color.blue.opacity(0 + Double((abs(localPosition.height) + abs(localPosition.width)) / 99))
        }
    }
    
    private func movedEnough(width: CGFloat, height: CGFloat) -> Bool {
        return abs(width) > minDistance || abs(height) > minDistance
    }
    
    var body: some View {
        Circle().stroke(Color.black)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack (spacing: 20) {
                    Text("Node ID: \(node.nodeId)")
                    Text("Node Serial: \(info)")
                }.padding()
            }
            .background(Image(systemName: "plus"))
            .overlay(LinearGradient(gradient: Gradient(colors: [
                                                        // white of opacity 0 means: 'invisible'
                                                        localPosition == CGSize.zero ? Color.white.opacity(0) : Color.white,
                                                        localPosition == CGSize.zero ? Color.white.opacity(0) : determineColor()]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
            ))
            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
//            .overlay(Text(movedEnough(width: localPosition.width, height: localPosition.height) ? "\(node.nodeNumber)": ""))
            .overlay(Text(movedEnough(width: localPosition.width, height: localPosition.height) ? "\(node.nodeId)": ""))
            .frame(width: CGFloat(node.radius), height: CGFloat(node.radius))
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: {
                                [BallPreferenceData(viewIdx: Int(node.nodeId), center: $0,
                                                    graphId: node.graphId,
                                                    nodeId: node.nodeId)] })
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
                            log("drag onChanged")
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                            
                            // if position just held locally, then when we close app,
                            // we won't have the position saved in redux store
                            if !node.isAnchored {
                                log("dragged node was not anchored")
                                dispatch(NodeMovedAction(graphId: node.graphId, position: self.localPosition, node: node))
                            }
                            
                            
                        }
                        .onEnded { (value: DragGesture.Value) in
                            log("drag onEnded")
                            if node.isAnchored {
                                if movedEnough(width: value.translation.width, height: value.translation.height) {
                                    log("movedEnough")
                                    self.localPreviousPosition = self.localPosition // not even needed here?
                                    playSound(sound: "positive_ping", type: "mp3")
                                    dispatch(NodeCommittedAction(graphId: node.graphId, position: self.localPosition, node: node))
                                }
                                else {
                                    withAnimation(.spring()) { self.localPosition = CGSize.zero }
                                }
                            }
                            else {
                                self.localPreviousPosition = self.localPosition
                            }
                        })
            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
            .onTapGesture(count: 2, perform: {
                log("2 tap")
                if !node.isAnchored {
                    self.showPopover.toggle()
                }
            })
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                log("1 tap")
                if !node.isAnchored {
                    let existsConnectingNode: Bool = connectingNode != nil
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeId
                    
                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
//                        self.connectingNode = Int(node.nodeNumber)
                        self.connectingNode = node.nodeId
                    }
                    else { // ie there is an connecting node:
                        let edgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
                            conn.graphId == graphId &&
                                (conn.to == node.nodeId && conn.from == connectingNode!
                                    || conn.from == node.nodeId && conn.to == connectingNode!)
                        }.isEmpty
                        
                        if isConnectingNode {
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
                            log("Need to delete this connection")
                            playSound(sound: "connection_removed", type: "mp3")
                            dispatch(EdgeRemovedAction(graphId: graphId,
                                                       from: connectingNode!,
                                                       to: node.nodeId))
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            log("Need to create new edge")
                            playSound(sound: "connection_added", type: "mp3")
                            dispatch(EdgeAddedAction(graphId: graphId,
                                                       from: connectingNode!,
                                                       to: node.nodeId))
                            self.connectingNode = nil
                        }
                    }
                }
            })
    }
}

    
