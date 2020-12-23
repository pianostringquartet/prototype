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
 UI CONSTANTS: colors from prototypes, shared widths etc.
 ---------------------------------------------------------------- */

// COLORS

// imitates grid
let backgroundColor: Color = Color.black.opacity(0.85)

let floatingWindowColor: Color = Color.white.opacity(0.9)

// for text on nodes
let textColor: Color = Color.white.opacity(0.8)
    
let defaultPortColor: Color = textColor

let isActiveColor: Color = Color.red.opacity(0.8)


// from Adam's prototype

let edgeColor: Color = Color(red: 122 / 255, green: 237 / 255, blue: 175 / 255)

let nodeTopColor: Color = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
let nodeBottomColor: Color = Color(red: 52 / 255, green: 52 / 255, blue: 52 / 255)

let pinkNodeTopColor: Color = Color (red: 231 / 255, green: 54 / 255, blue: 161 / 255)
let pinkNodeBottomColor: Color = Color (red: 198 / 255, green: 0 / 255, blue: 114 / 255)
let pinkTagColor: Color = Color (red: 100 / 255, green: 0 / 255, blue: 60 / 255)


let valNodeColor: Color = nodeBottomColor
let calcNodeColor: Color = nodeBottomColor
let vizNodeColor: Color = pinkNodeBottomColor


// MEASUREMENTS

let portAndEdgeWidth: CGFloat = 30




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
    return Line(from: from, to: to)
        .stroke(edgeColor,
                style: StrokeStyle(lineWidth: portAndEdgeWidth,
                                   lineCap: .round,
                                   lineJoin: .round))
        .animation(.default)
//        .zIndex(2)
}


struct PlusButton: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
 
    @State private var showPopover: Bool = false // not persisted
    
    let radius: CGFloat = 80
    
    let dispatch: Dispatch
    
    var body: some View {
        Circle().stroke(Color.black)
        .overlay(LinearGradient(gradient: Gradient(colors: [Color.white, Color.green]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
        .overlay(Image(systemName: "plus"))
        .clipShape(Circle())
        .frame(width: CGFloat(radius), height: CGFloat(radius))
        // what about click-to-dismiss?
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack (spacing: 20) {
                Button("valNode: 'ciao'") {
                    dispatch(NodeCreatedAction(portValue: .string("ciao")))
                }
                Button("valNode: 'hola'") {
                    dispatch(NodeCreatedAction(portValue: .string("hola")))
                }
                Button("valNode: Color Blue") {
                    dispatch(NodeCreatedAction(portValue: .color(Color.blue)))
                }
                Button("calcNode: string concat") {
                    dispatch(NodeCreatedAction(operation: .concat))
                }
            }.padding()
        }
        .onTapGesture(count: 1, perform: {
            log("showPopover was: \(showPopover)")
            // ie toggle
            dispatch(PlusButtonTappedAction(newValue: self.showPopover ? false : true))
        
            self.showPopover.toggle()
            log("showPopover is now: \(showPopover)")
            })
            
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                            .onChanged {
                                self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                            }
                            .onEnded { _ in
                                self.localPreviousPosition = self.localPosition
                            })
        .animation(.spring(response: 0.3, dampingFraction: 0.65, blendDuration: 4))
        .shadow(radius: 25)
    }
}


func nodeTitle(_ node: NodeModel) -> String {
    switch node.nodeType {
        case .calcNode:
            return node.operation!.rawValue
        case .valNode:
            return node.interactionModel != nil
                ? "\(node.interactionModel!.previewInteraction) for \(node.interactionModel!.forNodeId)"
                : "Value"
        case .vizNode:
            return node.previewModel!.previewElement.rawValue
    }
}


struct NodeView: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
    
    @State private var showPopover: Bool = false // not persisted
    
    // contains the ports etc.
    let nodeModel: NodeModel
    
    let dispatch: Dispatch
    let state: AppState // convenience for now?
    
    let isPink: Bool
    
    let spacing: CGFloat = 20
    
    var bottomSection: some View {
        
        let inputs: [PortModel] = nodeModel.ports.filter { $0.portType == PortType.input }
            .sorted(by: ascending)
        
        let outputs: [PortModel] = nodeModel.ports.filter { $0.portType == PortType.output }
            .sorted(by: ascending)
        
        return ZStack {
            switch nodeModel.nodeType {
                case .valNode:
                    SinglePortTypeView(ports: outputs, state: state, dispatch: dispatch, isInput: false)
                case .calcNode:
                    DualPortTypeView(inputs: inputs,
                                     outputs: outputs,
                                     state: state,
                                     dispatch: dispatch)
                case .vizNode:
                    SinglePortTypeView(ports: inputs, state: state, dispatch: dispatch, isInput: true)
            }
        }
    }
    
    var body: some View {

        VStack {
            Text("\(nodeTitle(nodeModel)) (\(nodeModel.id))")
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, maxHeight: 40)
                .background(isPink ? pinkNodeTopColor : nodeTopColor)
                .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                     VStack (spacing: 20) {
                        Text("Node ID: \(nodeModel.id)")
                         Button("Delete") {
                            log("delete button pressed...")
                            dispatch(NodeDeletedAction(id: nodeModel.id))
                         }
                     }.padding()
                 }
            
            bottomSection
                .frame(maxWidth: .infinity, minHeight: 60) // .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isPink ? pinkNodeBottomColor : nodeBottomColor)
                    
        } // Vstack
        .background(isPink ? pinkNodeBottomColor : nodeBottomColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: 200) // .frame(width: 300, height: 250)
        .offset(x: localPosition.width, y: localPosition.height)
        .onTapGesture(count: 2, perform: {
                self.showPopover.toggle()
        })
        
        .gesture(DragGesture()
                    .onChanged {
                        self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                    }
                    .onEnded {  _ in
                        // i.e. no anchoring for now
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
    
    let spacing: CGFloat = 5
    
    var body: some View {
        HStack (spacing: spacing) {
            
            // left side
            VStack (spacing: spacing) {
                ForEach(inputs, id: \.id) {
                    (input: PortModel) in
                    PortView(pm: input,
                          dispatch: dispatch,
                          state: state,
                          isInput: true,
                          hasEdge: hasEdge(edges: state.edges, pm: input, isInput: true))
                }
            }
            
            // right side
            VStack (spacing: spacing) {
                ForEach(outputs, id: \.id) {
                    (output: PortModel) in
                    PortView(pm: output,
                             dispatch: dispatch,
                             state: state,
                             isInput: false,
                             hasEdge: hasEdge(edges: state.edges, pm: output, isInput: false))

                }
            }
        } // HStack
    }
}

struct SinglePortTypeView: View {

    let ports: [PortModel]
    let state: AppState
    let dispatch: Dispatch
    
    let isInput: Bool
    
    let spacing: CGFloat = 5
    
    var body: some View {
        // output or inputs
        VStack (spacing: spacing) {
            ForEach(ports, id: \.id) {
                (port: PortModel) in
                PortView(pm: port,
                         dispatch: dispatch,
                         state: state,
                         isInput: isInput,
                         hasEdge: hasEdge(edges: state.edges, pm: port, isInput: isInput))
            }
        }.padding(spacing)
    }
}

// fill port's color
func fillColor(hasEdge: Bool, thisPM: PortModel, activePM: PortModel?) -> Color {
    
    let isActivePort: Bool = activePM?.nodeId == thisPM.nodeId && activePM?.id == thisPM.id
    
//    let defaultColor: Color = Color.white.opacity(1.0)
    let defaultColor: Color = defaultPortColor

    // Arranged by color priority:
    // activePort: highest priority
    // coloredPorts
    // hasEdge
    // default: lowest priority
    
    if isActivePort {
        return isActiveColor
    }
    else if case .color(let x) = thisPM.value {
        return x
    }
    else if hasEdge {
        return edgeColor
    }
    else {
        return defaultColor
    }
}


struct PortView: View {

    let pm: PortModel

    let dispatch: Dispatch
    let state: AppState
    
    let isInput: Bool
    
    // is this specific port CURRENTLY either the origin or the target for an edge?
    let hasEdge: Bool
    
    var body: some View {
        
        let portDot = Circle()
            .fill(fillColor(hasEdge: hasEdge, thisPM: pm, activePM: state.activePM))
            .clipShape(Circle())
            .frame(width: portAndEdgeWidth, height: portAndEdgeWidth)
            .anchorPreference(key: PortPreferenceKey.self,
                              value: .center,
                              transform: {
                                [PortPreferenceData(viewIdx: pm.nodeId,
                                                    center: $0,
                                                    nodeId: pm.nodeId,
                                                    portId: pm.id)] })

            .onTapGesture(count: 1, perform: { dispatch(PortTappedAction(port: pm)) })
                
        let displayablePortValue: String = getDisplayablePortValue(mpv: pm.value)
        
        let portValue = Text("(\(pm.id)) \(displayablePortValue)").foregroundColor(textColor)
        
        VStack {
            if isInput == true {
                HStack {
                    portDot
                    portValue.frame(minWidth: 90)
                }
            } else {
                HStack {
                    portValue.frame(minWidth: 90)
                    portDot
                }
            }
        } // VStack
    }
}


// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}


//
struct DrawEdges<ContentView: View>: View {

    let state: AppState
    
    let content: ContentView
    
    var body: some View {
        content
            // can also use .overlayPreferenceValu where helpful
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
                    }
    }
}


struct Shapes_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}

