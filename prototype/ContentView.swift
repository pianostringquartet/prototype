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

    let dispatch: Dispatch
    let state: AppState
        
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
                                 color: valNodeColor)
                    }
                }
                
                // middle
                HStack (spacing: 50) {
                    ForEach(calcNodes, id: \.id) { (nm: NodeModel) in
                        NodeView(nodeModel: nm, dispatch: dispatch, state: state,
                                 title: "Calc node",
                                 color: calcNodeColor)

                    }
                }
                
                // right
                VStack {
                    ForEach(vizNodes, id: \.id) { (nm: NodeModel) in
                        NodeView(nodeModel: nm, dispatch: dispatch, state: state, title: "Viz node",
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
                            pref.portId == portEdge.from.portId &&
                                pref.nodeId == portEdge.from.nodeId
                        })
                        
                        // TODO: handle this properly;
                        // all connections should be really existing
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
    state: nil
)


struct ContentView: View {
//    @ObservedObject private var state = ObservableState(store: mainStore)
    
    @ObservedObject private var state = ObservableState(store: sampleStore) // dev etc.

    var body: some View {
        let dispatch: Dispatch = { state.dispatch($0) }
        
        return GraphEditorView(dispatch: dispatch, state: state.current)
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
