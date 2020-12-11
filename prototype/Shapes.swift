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
    
    
    let spacing: CGFloat = 10
    
    var body: some View {
        
        let inputs: [PortModel] = nodeModel.ports.filter { (pm: PortModel) -> Bool in
            pm.portType == PortType.input
        }
        
        let outputs: [PortModel] = nodeModel.ports.filter { (pm: PortModel) -> Bool in
            pm.portType == PortType.output
        }
        
//        log("NodeView: nodeModel.nodeType: \(nodeModel.nodeType)")
//        log("NodeView: inputs: \(inputs)")
//        log("NodeView: outputs: \(outputs)")
        
        VStack (spacing: spacing) {
         // top
            Text(title)
                // should be frame that covers whole space
                .background(Color.gray.opacity(0.4))
                
            // bottom
            HStack (spacing: spacing) {
                
                // left side
                VStack (spacing: spacing) {
//                    ForEach(nodeModel.inputs, id: \.id) {
                    ForEach(inputs, id: \.id) {
                        (input: PortModel) in
                        PortView(pm: input,
                              dispatch: dispatch,
                              state: state)
                    }
                }
                
                // right side
                VStack (spacing: spacing) {
//                    ForEach(nodeModel.outputs, id: \.id) {
                    ForEach(outputs, id: \.id) {
                        (output: PortModel) in
                        PortView(pm: output, dispatch: dispatch, state: state)

                    }
                }
            }
        }
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




let commonSpacing: CGFloat = 10

struct ValNodeView: View {
    
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let title: String // title of the node
    let valNode: ValNode
    let dispatch: Dispatch
    let state: AppState
    
    var body: some View {
        VStack (spacing: commonSpacing) {
            Text(title)
//            ForEach(valNode.outputs, id: \.id) { (output: Output) in
//                Text(output.value)
//            }
            
            
            HStack {
                Spacer()
                ForEach(valNode.outputs, id: \.id) { (output: PortValue) in
    //                Text(output.value)
                    Port2(pv: output, dispatch: dispatch, state: state, isInput: false)
                }
            }
            
        }
        .frame(maxWidth: 100)
        .background(Color.gray.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("ValNodeView: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("ValNodeView: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
        
    }
}

struct CalcNodeView: View {

    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let title: String
    let calcNode: CalcNode
    let dispatch: Dispatch
    let state: AppState

    var body: some View {
        VStack (spacing: commonSpacing) {
         // top
            Text(title)
                // should be frame that covers whole space
                .background(Color.gray.opacity(0.4))
                
            // bottom
            HStack (spacing: commonSpacing) {
                
                // left side
                VStack (spacing: commonSpacing) {
                    ForEach(calcNode.inputs, id: \.id) {
//                        (input: Input) in
                        (input: PortValue) in
//                        Text(input.value)
                        Port2(pv: input,
                              dispatch: dispatch,
                              state: state,
                              isInput: true)
                    }
                }
                
                // right side
                Port2(pv: calcNode.output,
                      dispatch: dispatch,
                      state: state,
                      isInput: false)
//                VStack (spacing: commonSpacing) {
//                    ForEach(calcNode.output, id: \.id) {
////                        (output: Output) in
//                        (output: PortValue) in
////                        Text(output.value)
//                        Port2(pv: output, dispatch: dispatch, state: state, isInput: false)
//
//                    }
//                }
            }
            
        }
        .background(Color.yellow.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("CalcNodeView: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("CalcNodeView: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}

struct VizNodeView: View {
    
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let title: String
    let vizNode: VizNode
    let dispatch: Dispatch
    let state: AppState
    
    var body: some View {
        VStack (spacing: commonSpacing) {
            Text(title)
            
            HStack {
                ForEach(vizNode.inputs, id: \.id) {
    //                (input: Input) in
                    (input: PortValue) in
                    // wrap the input in a port
    //                Text(input.value)
                    Port2(pv: input, dispatch: dispatch,
                          state: state, isInput: true)
                }
                Spacer()
                
            }
            
            
        }
        .frame(maxWidth: 100)
        .background(Color.blue.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("VizNodeView: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("VizNodeView: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}



struct PortView: View {
    
//    let pv: PortValue
    
    //
    let pm: PortModel
    
    let dispatch: Dispatch
    let state: AppState

    
    //    let isInput: Bool
    
    
//    init(
//        pv: PortValue,
//        dispatch: @escaping Dispatch,
//        state: AppState,
//        isInput: Bool
//        ) {
//        self.pv = pv
//        self.dispatch = dispatch
//        self.state = state
//        self.isInput = isInput
//    }
    
    var body: some View {
        
//        let isActivePort: Bool = state.activePort?.nodeId == pv.nodeId && state.activePort?.portId == pv.id
        
//        let isActivePort: Bool = state.activePort?.nodeId == pm.nodeId && state.activePort?.portId == pm.id
        let isActivePort: Bool = state.activePM?.nodeId == pm.nodeId && state.activePM?.id == pm.id
        
        VStack (spacing: 10) {
            Text(pm.label)
            Text("Node \(pm.nodeId), Port \(pm.id)")
            Circle().stroke(Color.black)
    //            .overlay(Text(pm.label))
                .overlay(Text(pm.value))
                .background(isActivePort ? Color.green.opacity(1.0) : Color.white.opacity(1.0))
            
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .frame(width: 60, height: 60)
                
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


// a Port has portId, nodeId etc.,
// but these are stored in the PortValue,
// which represents them at the redux level...
struct Port2: View {

//    let id: Int
//    let label: String
//    let nodeId: Int
    
    let pv: PortValue
    let dispatch: Dispatch
    let state: AppState
    let isInput: Bool
    
    
    init(
        pv: PortValue,
        dispatch: @escaping Dispatch,
        state: AppState,
        isInput: Bool
        ) {
        self.pv = pv
        self.dispatch = dispatch
        self.state = state
        self.isInput = isInput
    }
    
    var body: some View {
        
        let isActivePort: Bool = state.activePort?.nodeId == pv.nodeId && state.activePort?.portId == pv.id
        
        VStack (spacing: 10) {
            Text(pv.label)
            Text("Node \(pv.nodeId), Port \(pv.id)")
            Circle().stroke(Color.black)
    //            .overlay(Text(pv.label))
                .overlay(Text(pv.value))
                .background(isActivePort ? Color.green.opacity(1.0) : Color.white.opacity(1.0))
            
                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                .frame(width: 60, height: 60)
                
                .anchorPreference(key: PortPreferenceKey.self,
                                  value: .center,
                                  transform: {
                                    [PortPreferenceData(viewIdx: pv.nodeId,
                                                        center: $0,
                                                        nodeId: pv.nodeId,
                                                        portId: pv.id)] })
                
                .onTapGesture(count: 1, perform: {
                    log("port2 tap called: Node \(pv.nodeId), Port \(pv.id)")
                    
                    // prev: dispatched based on passed around connecting-node
                    dispatch(PortTapped(
                                port: PortIdentifier(
                                    nodeId: pv.nodeId,
                                    portId: pv.id,
                                    isInput: isInput))
                    )
                })
        }
    }
}



// a UI element
struct Port: View {

//    let id: UUID = UUID()
    let id: Int
    
    let label: String
    
    // is input vs output
    // and two inputs cannot connect?
    
//    let direction: Directionality
    
    // e.g. port 1 is input and port 2 is NOT input
    
    let isInput: Bool
    
    // also want something like a node id,
    // ie which node this specific port belongs to
    let nodeId: Int
    
    // and also graphId?
    
    var body: some View {
        Circle().stroke(Color.black)
            .overlay(Text(label))
//            .overlay(Text("Label"))
            .frame(width: 45, height: 45)
            
            .anchorPreference(key: PortPreferenceKey.self,
                              value: .center, // center for Anchor<CGPoint>
                              transform: {
                                [PortPreferenceData(viewIdx: nodeId,
                                                    center: $0,
                                                    nodeId: nodeId,
                                                    portId: id)] })
    }
}


// VBox: top is title,
//  bottom is HBox of: ports etc.
// bottom
struct Box2: View {
    
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    let title: String
    let color: Color
//    let width: CGFloat
//    let height: CGFloat
    
    // really, should be a tuple?
    let leftPorts: [Port]
    let rightPorts: [Port]
    
    let spacing: CGFloat = 10
    
    var body: some View {
        VStack (spacing: spacing) {
         // top
            Text(verbatim: title)
                // should be frame that covers whole space
                .background(Color.gray.opacity(0.4))
                
            // bottom
            HStack (spacing: spacing) {
                
                // left side
                VStack (spacing: spacing) {
//                    Text("Port Left 1")
//                    Text("Port Left 2")
                    ForEach(leftPorts, id: \.id) { (port: Port) in
                        port // just showing the port
                    }
                    
                }
                
                // right side
                VStack (spacing: spacing) {
//                    Text("Port Right 1")
//                    Text("Port Right 2")
                    ForEach(rightPorts, id: \.id) { (port: Port) in
                        port // just showing the port
                    }
                }
            }
            
        }
        .background(color.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                    .onChanged {
                        log("Box2: onChanged")
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
                        log("Box2: onEnded")
                        self.localPreviousPosition = self.localPosition
                    })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
    }
}


// square node
//struct Box: View {
//
//    let title: String
//
//    let color: Color
//
//    @State private var localPosition: CGSize = CGSize.zero
//    @State private var localPreviousPosition: CGSize = CGSize.zero
//
//    let width: CGFloat
//    let height: CGFloat
//
//    var body: some View {
//        Rectangle()
//            .stroke(color.opacity(0.5), lineWidth: 3)
//            .background(Color.gray.opacity(0.5))
//            .overlay(Text(title))
//
//
//            .background(Port(label: title))
//
//
//            .frame(width: width, height: height)
//            .offset(x: localPosition.width, y: localPosition.height)
//            .gesture(DragGesture()
//                        .onChanged {
//                            log("Box: onChanged")
//                            self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
//                        }
//                        .onEnded {  _ in
//                            // i.e. no anchoring for now
//                            self.localPreviousPosition = self.localPosition
//                        })
//            .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
//
//    }
//
//}


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
