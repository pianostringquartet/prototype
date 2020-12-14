//
//  Legacy.swift
//  prototype
//
//  Created by cjc on 12/14/20.
//

import Foundation
import SwiftUI
import ReSwift

//
//// 'layer 1' node: output only
//struct ValNode: Identifiable, Codable {
//
//    let id: Int
////    let outputs: [Output]
//    let outputs: [PortValue]
//}
//
//
//// 'layer 2' node: input and output
////struct CalcNode: Identifiable, Codable {
//struct CalcNode: Identifiable, Codable {
//
//    let id: Int
////    let inputs: [Input]
//    let inputs: [PortValue]
////    let outputs: [Output]
////    let outputs: [PortValue]
//
//    // a calc node only has one output!
//    let output: PortValue
//
//    // functionality, e.g. str-concat or str-caps
//    // swift: how to indicate just a general function?
////    let operation: (Any) -> Any
//
//    // for now using:
//    // how to use this with Codable?
//    // if can't serialize the function,
//    // alternatively, could have a redux action for operation,
//    // and dispatch the
////    let operation: (String) -> String
//    // but redux actions are hardcoded and known;
//
//    // some redux action
//    // not serializable?
////    let operation: Action.Type
//
//    //
////    let operation: NodeDeletedAction.Type
//
//    // RIGHT NOW: unused and
//    let operation: String // and do Action.Type
//
//
//    // or define custom serializers?
//    // toString: Action.self or Action.type
//    // fromString: ... would need to match the string against a list of actions...
//
//    // can you set this aside for now?
//    // can you just hardcode something for now?
//
//
//
//}
//
//
//// 'layer 3' node: input only; UI elem only
//// what
//struct VizNode: Identifiable, Codable {
//
//    let id: Int
////    let inputs: [Input]
//    let inputs: [PortValue]
//
//
//
//}



struct Connection: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var graphId: Int
    var from: Int
    var to: Int
    
    static func ==(lhs: Connection, rhs: Connection) -> Bool {
        // Edgeless connection:
        return lhs.graphId == rhs.graphId && (lhs.from == rhs.from && lhs.to == rhs.to || lhs.from == rhs.to && lhs.to == rhs.from)
    }
}

struct Graph: Identifiable, Codable {
    var id: UUID = UUID()
    var graphId: Int
}


struct Node: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var graphId: Int
    var info: UUID = UUID()
    var isAnchored: Bool
    var nodeId: Int
    
    var position: CGSize = .zero
    var radius: Int = 40 // start out at 40
    
}




// Datatype for preference data
struct BallPreferenceData: Identifiable {
    let id = UUID()
    let viewIdx: Int
    let center: Anchor<CGPoint>
    let graphId: Int
    let nodeId: Int
}

// Preference key for preference data
struct BallPreferenceKey: PreferenceKey {
    typealias Value = [BallPreferenceData]

    static var defaultValue: [BallPreferenceData] = []

    static func reduce(value: inout [BallPreferenceData], nextValue: () -> [BallPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}


struct Ball: View {
    @Environment(\.managedObjectContext) var moc
    
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

    init(connectingNode: Binding<Int?>,
         node: Node,
         graphId: Int, // don't need to pass graphID -- the node will have it
         connections: [Connection],
         dispatch: @escaping Dispatch
    ) {
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
        Circle()
            .stroke(Color.black)
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                VStack (spacing: 20) {
                    Text("Node ID: \(node.nodeId)")
                    Text("Node Serial: \(info)")
                    Button("Delete") {
                        dispatch(NodeDeletedAction(graphId: node.graphId, nodeId: node.nodeId))
                    }
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
            .overlay(Text(movedEnough(width: localPosition.width, height: localPosition.height) ? "\(node.nodeId)": ""))
            .frame(width: CGFloat(node.radius), height: CGFloat(node.radius))
            
            // Child stores its center in anchor preference data,
            // for parent to later access.
            // NOTE: must come before .offset modifier
            .anchorPreference(key: BallPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: {
                                [BallPreferenceData(viewIdx: Int(node.nodeId),
                                                    center: $0,
                                                    graphId: node.graphId,
                                                    nodeId: node.nodeId)] })
            
            .offset(x: localPosition.width, y: localPosition.height)
            .gesture(DragGesture()
                        .onChanged {
                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                            
                            if !node.isAnchored {
                                dispatch(NodeMovedAction(graphId: node.graphId, position: self.localPosition, node: node))
                            }
                        }
                        .onEnded { (value: DragGesture.Value) in
                            if node.isAnchored {
                                if movedEnough(width: value.translation.width, height: value.translation.height) {
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
                if !node.isAnchored {
                    self.showPopover.toggle()
                }
            })
            .onTapGesture(count: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/, perform: {
                if !node.isAnchored {
                    let existsConnectingNode: Bool = connectingNode != nil
                    let isConnectingNode: Bool = existsConnectingNode && connectingNode != nil && connectingNode! == node.nodeId
                    
                    // Note: if no existing connecting node, make this node the connecting node
                    // ie user is attempting to create or remove a node
                    if !existsConnectingNode {
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
                            playSound(sound: "connection_removed", type: "mp3")
                            dispatch(EdgeRemovedAction(graphId: graphId,
                                                       from: connectingNode!,
                                                       to: node.nodeId))
                            self.connectingNode = nil
                        }
                        // if existing connecting node and I am NOT the connecting node AND there DOES NOT exist a connxn(connecting node, me),
                        // add the connection and set connecting node=nil
                        else if !isConnectingNode && !edgeAlreadyExists {
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


// NODES

//        case let nodeMoved as NodeMovedAction:
//            // remove the old node and insert and updated one:
//            state.nodes.removeAll(where: {
//                (n: Node) in n.nodeId == nodeMoved.node.nodeId && n.graphId == nodeMoved.graphId
//            })
//            state.nodes.append(Node(graphId: nodeMoved.graphId,
//                                    isAnchored: false, // unanchored
//                                    nodeId: nodeMoved.node.nodeId,
//                                    // use the updated position
//                                    position: nodeMoved.position))
//
//        case let nodeCommitted as NodeCommittedAction:
//            // remove the old node and insert and updated one:
//            state.nodes.removeAll(where: {
//                (n: Node) in n.nodeId == nodeCommitted.node.nodeId && n.graphId == nodeCommitted.graphId
//            })
//            state.nodes.append(Node(graphId: nodeCommitted.graphId,
//                                    isAnchored: false, // unanchored
//                                    nodeId: nodeCommitted.node.nodeId,
//                                    // use the updated position
//                                    position: nodeCommitted.position))
//
//            // create the new node ie plus ball
//            state.nodes.append(
//                Node(graphId: nodeCommitted.graphId,
//                     isAnchored: true,
//                     nodeId: nextNodeId(nodes: nodesForGraph(graphId: nodeCommitted.graphId,
//                                                             nodes: state.nodes))
//                )
//            )
//
//        case let nodeDeleted as NodeDeletedAction:
//            state.nodes.removeAll(where: { $0.graphId == nodeDeleted.graphId && $0.nodeId == nodeDeleted.nodeId })
//            state.connections.removeAll(where: {
//                                            $0.graphId == nodeDeleted.graphId &&
//                                                ($0.to == nodeDeleted.nodeId || $0.from == nodeDeleted.nodeId) })

    
//        // EDGES
//
////        case let edgeAdded as EdgeAddedAction:
////            state.connections.append(Connection(graphId: edgeAdded.graphId, from: edgeAdded.from, to: edgeAdded.to))
////
////        case let edgeRemoved as EdgeRemovedAction:
////            state.connections.removeAll(where: {(conn: Connection) -> Bool in
////                conn.graphId == edgeRemoved.graphId && (conn.from == edgeRemoved.from && conn.to == edgeRemoved.to || conn.from == edgeRemoved.to && conn.to == edgeRemoved.from)
////            })
