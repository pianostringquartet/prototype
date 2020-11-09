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
    
    @Binding private var nodeCount: Int
    @Binding private var connectingNode: Int? // not persisted
    
    // node info
    @State private var info: UUID = UUID()
    @State private var showPopover: Bool = false // not persisted
    
    private var node: Node
    
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let graphId: Int
    
    let connections: [Connection]
    
//    private var connectionsFetchRequest: FetchRequest<Connection>
//    private var connections: FetchedResults<Connection> { connectionsFetchRequest.wrappedValue }
    
    // minimum distance for plus-sign to be dragged to become committed as a node
    let minDistance: CGFloat = CGFloat(90)
    
    let dispatch: Dispatch

    init(nodeCount: Binding<Int>, // shouldn't need this anymore
         connectingNode: Binding<Int?>,
         node: Node,
         graphId: Int, // don't need to pass graphID -- the node will have it
         connections: [Connection],
         dispatch: @escaping Dispatch
    ) {
        self._nodeCount = nodeCount
        self._connectingNode = connectingNode
        
//        connectionsFetchRequest = FetchRequest<Connection>(
//            entity: Connection.entity(),
//            sortDescriptors: [],
//            predicate: NSPredicate(format: "graphId = %@", NSNumber(value: graphId)))
        
        self.node = node
        
//        let convertedPosition: CGSize = CGSize(width: CGFloat(node.positionX),
//                                               height: CGFloat(node.positionY))
//        self._localPosition = State.init(initialValue: convertedPosition)
//        self._localPreviousPosition = State.init(initialValue: convertedPosition)
        
        // use node's position directly
        self._localPosition = State.init(initialValue: node.position)
        self._localPreviousPosition = State.init(initialValue: node.position)
        
        
        self.graphId = graphId
        
        self.connections = connections
        self.dispatch = dispatch
    }
    
    private func determineColor() -> Color {
//        if connectingNode != nil && connectingNode! == node.nodeNumber {
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
//                    Text("Node Number: \(node.nodeNumber)")
                    Text("Node ID: \(node.nodeId)")
                    Text("Node Serial: \(info)")
                }
                .padding()
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
//                                [BallPreferenceData(viewIdx: Int(node.nodeNumber), center: $0)] })
                                [BallPreferenceData(viewIdx: Int(node.nodeId), center: $0)] })
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
                            log("drag onChanged")
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
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
                            
//                            node.positionX = Float(localPosition.width)
//                            node.positionY = Float(localPosition.height)
                            
//                            node.position = localPosition
                            
                            
//                            try? moc.save()
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
//                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeNumber
                    
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeId
                    
                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
//                        self.connectingNode = Int(node.nodeNumber)
                        self.connectingNode = Int(node.nodeId)
                    }
                    else { // ie there is an connecting node:
                        let edgeAlreadyExists: Bool = !connections.filter { (conn: Connection) -> Bool in
                            conn.graphId == Int32(graphId) &&
                                (conn.to == node.nodeId && conn.from == Int32(connectingNode!)
                                    || conn.from == node.nodeId && conn.to == Int32(connectingNode!))
                        }.isEmpty
                        
                        if isConnectingNode {
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there already exists a connxn(connecting node, me),
                        // remove the connection and set connecting node=nil
                        else if !isConnectingNode && edgeAlreadyExists {
                            
                            // Retrieve the existing connection and delete it
//                            let fetchRequest : NSFetchRequest<Connection> = Connection.fetchRequest()
//                            fetchRequest.predicate = NSPredicate(format: "graphId = %i AND (from = %i AND to = %i) OR (to = %i AND from = %i)",
//                                                                 graphId, connectingNode!, node.nodeNumber, connectingNode!, node.nodeNumber)
//                            let fetchedResults = try? moc.fetch(fetchRequest) as! [Connection]
//                            if let aConnection = fetchedResults?.first {
//                                moc.delete(aConnection)
//                                try? moc.save()
//                            }
                            
                            log("Need to delete this connection")
                            
                            self.connectingNode = nil
                            playSound(sound: "connection_removed", type: "mp3")
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
                            
//                            let edge = Connection(context: self.moc)
//                            edge.id = UUID()
//                            edge.from = Int32(connectingNode!)
//                            edge.to = node.nodeNumber
//                            edge.graphId = Int32(graphId)
//                            try? moc.save()
                            
                            log("Need to create new node")
                            
                            self.connectingNode = nil
                            playSound(sound: "connection_added", type: "mp3")
                        }
                    }
                }
            })
    }
}

    
