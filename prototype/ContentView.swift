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
    
    let dispatch: Dispatch
    let state: AppState
    
    init(dispatch: @escaping Dispatch, state: AppState) {
        self.dispatch = dispatch
        self.state = state
    }

    // the nodes themselves // NEEDS TO BE ZSTACK
    var graph: some View {
        HStack (spacing: 50) {
            let valNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.valNode
            }.sorted(by: ascendingNodes)
            
            let calcNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.calcNode
            }.sorted(by: ascendingNodes)
            
            let vizNodes = state.nodeModels.filter { (n: NodeModel) -> Bool in
                n.nodeType == NodeType.vizNode
            }.sorted(by: ascendingNodes)
            
            // left
            VStack {
                ForEach(valNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, isPink: nm.interactionModel != nil)
                }
            }
            
            // middle
            HStack (spacing: 50) {
                ForEach(calcNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, isPink: false)

                }
            }
            
            // right
            VStack {
                ForEach(vizNodes, id: \.id) { (nm: NodeModel) in
                    NodeView(nodeModel: nm, dispatch: dispatch, state: state, isPink: true)
                }
            }
        } // HStack
        
    }
    
    
    var body: some View {
        log("GraphEditorView body called")
    
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    DrawEdges(state: state, content: graph)
                ) // .overlay
        } // ZStack
        .offset(x: localPosition.width, y: localPosition.height)
        
        // was this causing problems? we were outside the frame?
//        .frame(idealWidth: 500, idealHeight: 500)
    
        // Pinch to zoom
        // TODO: set limit to how far out / in we can zoom
        
        // CAREFUL: .contentShape CHANGES THE AREA THAT YOU THINK YOU CAN CLICK IN ETC.
//        .contentShape(Rectangle()) // make container
        
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
  
        .overlay(FloatingWindow(content: generateMiniview(state: state, dispatch: dispatch)).padding(),
                 alignment: .topTrailing)
        .blur(radius: state.shouldBlur ? 5 : 0)
        // ie only the plus button is visible above the frost
        .overlay(PlusButton(dispatch: dispatch).padding(),
                 alignment: .bottomTrailing)
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
