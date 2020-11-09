//
//  ContentView.swift
//  prototype
//
//  Created by cjc on 11/1/20.
//

import SwiftUI
import AVFoundation
import ReSwift

// Initialize redux store
let mainStore = Store<AppState>(
    reducer: counterReducer,
    state: nil
)

/* ----------------------------------------------------------------
 GRAPH EDITING VIEWS
 ---------------------------------------------------------------- */

struct GraphEditorChild: View {
//    @Environment(\.managedObjectContext) var moc

    // particular node to which we are adding/removing connections
    @State public var connectingNode: Int? = nil // not persisted

    @State private var nodeCount: Int

    let graphId: Int
    let nodes: [Node]
    let connections: [Connection]
    let dispatch: Dispatch
    
    init(graphId: Int, nodeCount: Int, nodes: [Node], connections: [Connection],
         dispatch: @escaping Dispatch) {
        self._nodeCount = State.init(initialValue: nodeCount)
        self.graphId = graphId
        self.nodes = nodes
        self.connections = connections
        self.dispatch = dispatch
    }

    var body: some View {
        VStack { // HACK: bottom right corner alignment
            log("GraphEditorChild: nodes: \(nodes)")
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    ForEach(nodes, id: \.id) { (node: Node) in
                        Ball(nodeCount: $nodeCount,
                             connectingNode: $connectingNode,
                             node: node,
                             graphId: graphId,
                             connections: connections,
                             dispatch: dispatch)
                    }.padding(.trailing, 30).padding(.bottom, 30)

                }
            }
        }
        .backgroundPreferenceValue(BallPreferenceKey.self) { (preferences: [BallPreferenceData]) in
            if connections.count >= 1 && nodeCount >= 2 {
                GeometryReader { (geometry: GeometryProxy) in
                    ForEach(connections, content: { (connection: Connection) in
                        // -1 to convert from 1-based count to 0-based index
                        log("backgroundPreferenceValue: Will draw edge")
                        let toPref: BallPreferenceData = preferences[Int(connection.to) - 1]
                        let fromPref: BallPreferenceData = preferences[Int(connection.from) - 1]
                        line(from: geometry[toPref.center], to: geometry[fromPref.center])
                    })

                }
            }
        }
    }
}



/* ----------------------------------------------------------------
 Content View
 ---------------------------------------------------------------- */

// has list of graphs, nodes etc.
// from here, user picks particular graphId
//struct GraphSelectionView: View {
//
//    let graphs: [Graph]
//
//    var body: some View {
//
//    }
//}

struct ContentView: View {
//struct XContentView: View {

    // MARK: Private Properties

    @ObservedObject private var state = ObservableState(store: mainStore)

    // MARK: Body

    
    var body: some View {
        log("redux ContentView: body")
        // just start with one
        
        let tempGraphId = 1
        
        GraphEditorChild(graphId: tempGraphId, // hardcode
                         nodeCount: state.current.nodes.count,
                         nodes: state.current.nodes.isEmpty ? [Node(graphId: tempGraphId)] : state.current.nodes,
                         connections: state.current.connections,
                         dispatch: { (action: Action) in state.dispatch(action) })
        
//        VStack {
//            // We just directly grab the data from the state
//            // ... can also pass this down later?
////            Text(String(state.current.counter))
//            Text(String(state.current.fun.count))
//            Button(action: state.dispatch(CounterActionIncrease())) {
//                log("redux ContentView: dispatch increment")
//                Text("Increase")
//            }
//            Button(action: state.dispatch(CounterActionDecrease())) {
//                log("redux ContentView: dispatch decrement")
//                Text("Decrease")
//            }
//            ForEach(state.current.muchFun, id: \.id) { (f: Fun) in
//                AuthorView(f: f)
//            }
//        }
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
