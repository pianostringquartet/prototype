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

// common
//typealias <#type name#> = <#type expression#>

struct NodeView: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    // contains the ports etc.
    let nodeModel: NodeModel
    
    
    let dispatch: Dispatch
    let state: AppState // convenience for now?
    
    // should these properties of NodeModel?
    let title: String
    let color: Color
    
    
    let spacing: CGFloat = 20
    
    var body: some View {
        
        // need to always sort by ascending port# order, so that ports have consistent position
    
        let ascending = { (pm1: PortModel, pm2: PortModel) -> Bool in
            pm1.id < pm2.id
        }
        
        let inputs: [PortModel] = nodeModel.ports.filter { (pm: PortModel) -> Bool in
            pm.portType == PortType.input
        }.sorted(by: ascending)
        
        let outputs: [PortModel] = nodeModel.ports.filter { (pm: PortModel) -> Bool in
            pm.portType == PortType.output
        }.sorted(by: ascending)
        
        
//        log("NodeView: nodeModel.nodeType: \(nodeModel.nodeType)")
//        log("NodeView: inputs: \(inputs)")
//        log("NodeView: outputs: \(outputs)")
        
        VStack (spacing: spacing) {
         // top
            Text(title)
                // should be frame that covers whole space
                .padding(10)
                .background(Color.gray.opacity(0.4))
            
            nodeModel.operation != nil ?
                Text("Operation: \(nodeModel.operation!.rawValue)")
                    .padding(10)
                    .background(Color.gray.opacity(0.4))
                : nil
  
//            DualPortTypeView(inputs: inputs, outputs: outputs, state: state, dispatch: dispatch)
            
            // unable to infer complex closure type? wtf?
            switch nodeModel.nodeType {
                case .valNode:
                    SinglePortTypeView(ports: outputs, state: state, dispatch: dispatch)
                case .calcNode:
                    DualPortTypeView(inputs: inputs, outputs: outputs, state: state, dispatch: dispatch)
//                    return SinglePortTypeView(ports: inputs, state: state, dispatch: dispatch)
                case .vizNode:
                    SinglePortTypeView(ports: inputs, state: state, dispatch: dispatch)
            }
            
//            // bottom
//            HStack (spacing: spacing) {
//
//                // left side
//                VStack (spacing: spacing) {
//                    ForEach(inputs, id: \.id) {
//                        (input: PortModel) in
//                        PortView(pm: input,
//                              dispatch: dispatch,
//                              state: state)
//                    }
//                }
//
//                // right side
//                VStack (spacing: spacing) {
//                    ForEach(outputs, id: \.id) {
//                        (output: PortModel) in
//                        PortView(pm: output, dispatch: dispatch, state: state)
//
//                    }
//                }
//            } // HStack
            
        }
        .padding()
        .background(color.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("NodeView: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("NodeView: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}



//for both inputs and outputs (calc node)
// Hstack + vstacks
struct DualPortTypeView: View {

    let inputs: [PortModel]
    let outputs: [PortModel]
    let state: AppState
    let dispatch: Dispatch
    
    
    let spacing: CGFloat = 20
    
    var body: some View {
        HStack (spacing: spacing) {
            
            // left side
            VStack (spacing: spacing) {
                ForEach(inputs, id: \.id) {
                    (input: PortModel) in
                    PortView(pm: input,
                          dispatch: dispatch,
                          state: state)
                }
            }
            
            // right side
            VStack (spacing: spacing) {
                ForEach(outputs, id: \.id) {
                    (output: PortModel) in
                    PortView(pm: output, dispatch: dispatch, state: state)

                }
            }
        } // HStack
    }
}

struct SinglePortTypeView: View {

    let ports: [PortModel]
    let state: AppState
    let dispatch: Dispatch
    
    let spacing: CGFloat = 20
    
    var body: some View {
        // output or inputs
        VStack (spacing: spacing) {
            ForEach(ports, id: \.id) {
                (port: PortModel) in
                PortView(pm: port, dispatch: dispatch, state: state)
            }
        }
    }
}



let commonSpacing: CGFloat = 10


struct PortView: View {
    
    let pm: PortModel
    
    let dispatch: Dispatch
    let state: AppState

    let radius: CGFloat = 80
    
    var body: some View {
        
        let isActivePort: Bool = state.activePM?.nodeId == pm.nodeId && state.activePM?.id == pm.id
        
        VStack (spacing: 10) {
            Text(pm.label)
            Text("Node \(pm.nodeId), Port \(pm.id)")
            Circle().stroke(Color.black)
                .overlay(Text(pm.value))
                .background(isActivePort ? Color.green.opacity(1.0) : Color.white.opacity(1.0))
            
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .frame(width: radius, height: radius)
                
                .anchorPreference(key: PortPreferenceKey.self,
                                  value: .center,
                                  transform: {
                                    [PortPreferenceData(viewIdx: pm.nodeId,
                                                        center: $0,
                                                        nodeId: pm.nodeId,
                                                        portId: pm.id)] })
                
                .onTapGesture(count: 1, perform: {
                    log("PortView tap called: Node \(pm.nodeId), Port \(pm.id), Value: \(pm.value)")
                    
                    // prev: dispatched based on passed around connecting-node
//                    dispatch(PortTapped(
//                                port: PortIdentifier(
//                                    nodeId: pm.nodeId,
//                                    portId: pm.id,
//                                    isInput: pm.portType == .input)))
                    
                    // CANNOT USE THE VALUE HERE, because e.g. the value will be the value of the tapped port, which might be an output
                    dispatch(PortTappedAction(port: pm))
        
                })
        }
    }
}




// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
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

struct Shapes_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}

