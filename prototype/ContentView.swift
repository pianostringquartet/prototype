//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation
import ReSwift
//import ui


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

    
    let dispatch: Dispatch
    let state: AppState
    
//    let
    
    init(dispatch: @escaping Dispatch, state: AppState) {
        self.dispatch = dispatch
        self.state = state
    }

    var body: some View {
        log("GraphEditorView body called")
        
        VStack {
            HStack (spacing: 50) {
                let ascending = { (nm1: NodeModel, nm2: NodeModel) -> Bool in nm1.id < nm2.id }
                
                let valNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                    n.nodeType == NodeType.valNode
                }.sorted(by: ascending)
                
                let calcNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                    n.nodeType == NodeType.calcNode
                }.sorted(by: ascending)
                
                let vizNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                    n.nodeType == NodeType.vizNode
                }.sorted(by: ascending)
                
                // left
                VStack {
                    ForEach(valNodes, id: \.id) { (nm: NodeModel) in
                        NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Val node",
//                                 color: Color.gray)
//                                 color: nm.previewInteraction == nil ? nodeBottomColor : pinkNodeBottomColor)
                                 color: valNodeColor)
                    }
                }
                
                // middle
                HStack (spacing: 50) {
                    ForEach(calcNodes, id: \.id) { (nm: NodeModel) in
                        NodeView(nodeModel: nm, dispatch: dispatch, state: state,
                                 title: "Calc node",
//                                 color: nodeBottomColor)
                                 color: calcNodeColor)
//                                 color: Color.yellow)
                    }
                }
                
                // right
                VStack {
                    ForEach(vizNodes, id: \.id) { (nm: NodeModel) in
                        NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Viz node",
//                                 color: Color.blue)
//                                 color: pinkNodeBottomColor)
                                 color: vizNodeColor)
                    }
                }
            } // HStack
            .padding()
                        
        }
        .padding(.trailing, 30).padding(.bottom, 30)
        .offset(x: localPosition.width, y: localPosition.height)
        .frame(idealWidth: 500, idealHeight: 500)
        
        .overlay(FloatingWindow(content: generateMiniview(state: state, dispatch: dispatch)))
        
        
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



let valNodeId = 1
let valNodeId2 = 2
let valNodeId3 = 3 // press-interaction node ('as a val-node')

let calcNodeId = 4
let calcNodeId2 = 5
let calcNodeId3 = 6 // option picker

let vizNodeId = 7
let vizNodeId2 = 8


//let valNodeOutput: PortModel = PortModel(id: 1, nodeId: valNodeId, portType: PortType.output, label: "output: String", value: "hello")
//
//let valNode: NodeModel = NodeModel(id: valNodeId, nodeType: NodeType.valNode, ports: [valNodeOutput])

let valNode = stringValNode(id: valNodeId, value: "hello")
let valNode2 = stringValNode(id: valNodeId2, value: "world")

//let valNodeOutput2: PortModel = PortModel(id: 2, nodeId: valNodeId2, portType: PortType.output, label: "output: String", value: "world")
//
//let valNode2: NodeModel = NodeModel(id: valNodeId2, nodeType: NodeType.valNode, ports: [valNodeOutput2])

let valNode3: NodeModel = pressInteractionNodeModel(id: valNodeId3)


//let calcNodeInput: PortModel = PortModel(id: 1, nodeId: calcNodeId, portType: PortType.input, label: commonLabel, value: "")
//
//let calcNodeOutput: PortModel = PortModel(id: 2, nodeId: calcNodeId, portType: PortType.output, label: commonLabel, value: "")

//let calcNode: NodeModel = NodeModel(id: calcNodeId, nodeType: .calcNode, ports: [calcNodeInput, calcNodeOutput], operation: Operation.uppercase)

let calcNode = concatNodeModel(id: calcNodeId)
let calcNode2 = uppercaseNodeModel(id: calcNodeId2)
let calcNode3 = optionPickerNodeModel(id: calcNodeId3)




//let vizNodeInput: PortModel = PortModel(id: 1, nodeId: vizNodeId, portType: PortType.input, label: "Text", value: "")
//
//let vizNode: NodeModel = NodeModel(id: vizNodeId, nodeType: NodeType.vizNode, ports: [vizNodeInput], previewElement: PreviewElement.text)

let vizNode: NodeModel = stringVizNode(id: vizNodeId, value: "", previewElement: PreviewElement.text, label: "TextLayer")


// hard code color as a string right now FOR THE DISPLAY VALUE
// i.e. this viz node is not taking any inputs right now
// and when minipreview text clicked on, we dispatched an change color

//let vizNodeInput2: PortModel = PortModel(id: 1, nodeId: vizNodeId2, portType: PortType.input, label: "TypographyColor", value: "Purple")

//let vizNode2: NodeModel = NodeModel(id: vizNodeId2, nodeType: NodeType.vizNode, ports: [vizNodeInput2], previewElement: PreviewElement.typographyColor)

let vizNode2: NodeModel = stringVizNode(id: vizNodeId, value: "Purple", previewElement: PreviewElement.typographyColor, label: "TypographyColor")


//let hwState = AppState(nodeModels: [valNode, valNode2, valNode3, calcNode, calcNode2, calcNode3, vizNode, vizNode2])

// REMOVED CONCAT FOR NOW
let hwState = AppState(nodeModels: [valNode, valNode2, valNode3, calcNode2, calcNode3, vizNode, vizNode2])



struct ContentView: View {

    @ObservedObject private var state = ObservableState(store: mainStore)

    var body: some View {
        let dispatcher: Dispatch = { state.dispatch($0) }
        
        return GraphEditorView(dispatch: dispatcher, state: state.current)
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
