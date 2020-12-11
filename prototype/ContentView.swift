//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation
import ReSwift


/* ----------------------------------------------------------------
 GRAPH EDITING VIEW
 ---------------------------------------------------------------- */

struct GraphEditorView: View {
    
    // zooming
    @State private var currentAmount: CGFloat = 0
    @State private var finalAmount: CGFloat = 1
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil // not persisted

    let graphId: Int
    let nodes: [Node]
    let connections: [Connection]
    let portConnections: [PortConnection]
    let dispatch: Dispatch
    
    let state: AppState
    
    init(graphId: Int,
         nodes: [Node],
         connections: [Connection],
         portConnections: [PortConnection],
         dispatch: @escaping Dispatch,
         state: AppState) {
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.portConnections = portConnections
        self.dispatch = dispatch
        self.state = state
    }

    var body: some View {
        log("GraphEditorView body called")
        
        HStack (spacing: 50) {
    
            let valNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.valNode
            }
            let calcNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.calcNode
            }
            let vizNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.vizNode
            }
            
            // left
            VStack {
                Text("Value nodes")
//                ForEach(state.valNodes, id: \.id) { (valNode: ValNode) in
//                    ValNodeView(title: "Val. Node", valNode: valNode, dispatch: dispatch, state: state)
//                }
                ForEach(valNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Val node", color: Color.gray)
                }
            }
            
            // middle
            VStack {
                Text("Calc nodes")
//                ForEach(state.calcNodes, id: \.id) { (calcNode: CalcNode) in
//                    CalcNodeView(title: "Calc Node", calcNode: calcNode, dispatch: dispatch, state: state)
//                }
                ForEach(calcNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Calc node", color: Color.yellow)
                }
            }
            
            // right
            VStack {
                Text("Viz nodes")
//                ForEach(state.vizNodes, id: \.id) { (vizNode: VizNode) in
//                    VizNodeView(title: "Viz. Node", vizNode: vizNode, dispatch: dispatch, state: state)
//                }
                ForEach(vizNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Viz node", color: Color.blue)
                }
            }
            
  // manually hardcode what you want / need here

                    // keep the logic of the nodes, adding removing etc.
//                    ForEach(nodes, id: \.id) { (node: Node) in
//                        Ball(connectingNode: $connectingNode,
//                             node: node,
//                             graphId: graphId,
//                             connections: connections,
//                             dispatch: dispatch)
//                    }
                }
        .padding(.trailing, 30).padding(.bottom, 30)
//            }
//        }
        
        
        .offset(x: localPosition.width, y: localPosition.height)
        .frame(idealWidth: 500, idealHeight: 500)
        
        // Pinch to zoom
        // TODO: set limit to how far out / in we can zoom
        .contentShape(Rectangle()) // make container
//        .scaleEffect(finalAmount + currentAmount)
//        .gesture(
//            MagnificationGesture()
//                .onChanged { amount in
//                    log("onChanged called")
//                    self.currentAmount = amount - 1
//                }
//                .onEnded { amount in
//                    log("onEnded called")
//                    self.finalAmount += self.currentAmount
//                    self.currentAmount = 0
//                }
//        )
  
        .backgroundPreferenceValue(PortPreferenceKey.self) { (preferences: [PortPreferenceData]) in
//            if connections.count >= 1 {
            if state.edges.count >= 1 {
                let graphPreferences = preferences
                // no graphId right now
//                    .filter( { (pref: PortPreferenceData) -> Bool in pref.graphId == graphId })
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(state.edges, content: { (portEdge: PortEdge) in
                        // Find each conn node's ball pref data
                        
                        // find the pref data for this port (its node id and port id)
                        let to: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in
                            pref.portId == portEdge.to.portId &&
                                pref.nodeId == portEdge.to.nodeId
                            
                        })
                        
                        let from: PortPreferenceData? = graphPreferences.first(where: { (pref: PortPreferenceData) -> Bool in
//                            pref.portId == portConnection.from
                            pref.portId == portEdge.from.portId &&
                                pref.nodeId == portEdge.from.nodeId
                        })
                        
                        // TODO: handle this properly;
                        // all connections should be deletions
                        if to != nil && from != nil {
                            line(from: geometry[to!.center], to: geometry[from!.center])
                        }
                        else {
                            log("Encountered a nil while trying to draw an edge.")
                            log("to: \(to)")
                            log("from: \(from)")
                        }
                    })
                }
            }
        } // backgroundPreferenceValue
        
        
    
        
        
        
        
        
    }
}


/* ----------------------------------------------------------------
 Content View
 ---------------------------------------------------------------- */


// Initialize redux store
let mainStore = Store<AppState>(
    reducer: reducer,
//    state: nil
    state: hwState
)


//let valNodeOutput = PortValue(id: 1, nodeId: 1, label: "String value", value: "hello")
//let valNode = ValNode(id: 1, outputs: [valNodeOutput])
//
//
//let calcNodeInput = PortValue(id: 2, nodeId: 2, label: "String value", value: "x1")
//let calcNodeOutput = PortValue(id: 3, nodeId: 2, label: "String value", value: "x2")
//let calcNode: CalcNode = CalcNode(
//    id: 2,
//    inputs: [calcNodeInput],
//    output: calcNodeOutput,
//    operation: "uppercase"
////    operation: { (s: String) -> String in s.uppercased() }
//)
//
////let vizNodeInput = Input(id: 3, nodeId: 3, value: "HELLO")
////let vizNodeInput = PortValue(id: 4, nodeId: 3, label: "String value", value: "HELLO")
//let vizNodeInput = PortValue(id: 4, nodeId: 3, label: "String value", value: "x3")
//let vizNode = VizNode(id: 3, inputs: [vizNodeInput])




let valNodeId = 1
let calcNodeId = 2
let vizNodeId = 3
let commonLabel = "String value"


let valNodeOutput: PortModel = PortModel(id: 1, nodeId: valNodeId, portType: PortType.output, label: commonLabel, value: "hello")

let valNode: NodeModel = NodeModel(id: valNodeId, nodeType: NodeType.valNode, ports: [valNodeOutput])


let calcNodeInput: PortModel = PortModel(id: 1, nodeId: calcNodeId, portType: PortType.input, label: commonLabel, value: "")
//    PortValue(id: 2, nodeId: 2, label: "String value", value: "x1")
let calcNodeOutput: PortModel = PortModel(id: 2, nodeId: calcNodeId, portType: PortType.output, label: commonLabel, value: "")
//    PortValue(id: 3, nodeId: 2, label: "String value", value: "x2")

let calcNode: NodeModel = NodeModel(id: calcNodeId, nodeType: .calcNode, ports: [calcNodeInput, calcNodeOutput])

//let calcNode: CalcNode = CalcNode(
//    id: 2,
//    inputs: [calcNodeInput],
//    output: calcNodeOutput,
//    operation: "uppercase"
////    operation: { (s: String) -> String in s.uppercased() }
//)

//let vizNodeInput = Input(id: 3, nodeId: 3, value: "HELLO")
//let vizNodeInput = PortValue(id: 4, nodeId: 3, label: "String value", value: "HELLO")
let vizNodeInput: PortModel = PortModel(id: 1, nodeId: vizNodeId, portType: PortType.input, label: commonLabel, value: "")
    //PortValue(id: 4, nodeId: 3, label: "String value", value: "x3")
let vizNode: NodeModel = NodeModel(id: vizNodeId, nodeType: NodeType.vizNode, ports: [vizNodeInput])
    // VizNode(id: 3, inputs: [vizNodeInput])





let hwState = AppState(graphs: [],
                       nodes: [],
                       connections: [],
                       currentScreen: Screens.graphEditing,
                       currentGraphId: 1,
                       // might want each of these to be a map {:nodeId nodeType}
                       // instead of just a list?
//                       valNodes: [valNode],
//                       calcNodes: [calcNode],
//                       vizNodes: [vizNode],
                       
                       // graphEditor view will need to edit these themselves
                       nodeModels: [valNode, calcNode, vizNode])




struct ContentView: View {

    @ObservedObject private var state = ObservableState(store: mainStore)

    var body: some View {
        let dispatcher: Dispatch = { state.dispatch($0) }
        
        return GraphEditorView(graphId: 1, //state.current.currentGraphId!,
                               nodes: state.current.nodes,
                               connections: state.current.connections,
                                portConnections: [],
                                dispatch: dispatcher,
                                // careful -- is this updated enough?
                                state: state.current
               )
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
