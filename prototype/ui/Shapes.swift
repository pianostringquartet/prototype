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





// from Adam's prototype

//let edgeColor: Color = Color(red: 122 / 255, green: 237 / 255, blue: 175 / 255)
let edgeColor: Color = Color(red: 80 / 255, green: 250 / 255, blue: 200 / 255, opacity: 0.8)
let isActiveColor: Color = Color.red.opacity(0.8)


let nodeTopColor: Color = Color(red: 77 / 255, green: 77 / 255, blue: 77 / 255)
let nodeBottomColor: Color = Color(red: 52 / 255, green: 52 / 255, blue: 52 / 255)
//
//let nodeEmptyPortColor: Color = Color(red: 183 / 255, green: 183 / 255, blue: 183 / 255)

let pinkNodeTopColor: Color = Color (red: 231 / 255, green: 54 / 255, blue: 161 / 255)
let pinkNodeBottomColor: Color = Color (red: 198 / 255, green: 0 / 255, blue: 114 / 255)
let pinkTagColor: Color = Color (red: 100 / 255, green: 0 / 255, blue: 60 / 255)



let skyColor: Color = Color (red: 91 / 255, green: 179 / 255, blue: 230 / 255)
let bananaColor: Color = Color (red: 231 / 255, green: 233 / 255, blue: 87 / 255)
let mercuryColor: Color = Color (red: 208 / 255, green: 208 / 255, blue: 208 / 255)




// grey and pink scheme
//let valNodeColor: Color = nodeBottomColor
//let calcNodeColor: Color = nodeBottomColor
//let vizNodeColor: Color = pinkNodeBottomColor

let colorOpacity: Double = 0.6 // 0.8
let valNodeColor: Color = mercuryColor.opacity(colorOpacity)
let calcNodeColor: Color = bananaColor.opacity(colorOpacity)
let vizNodeColor: Color = skyColor.opacity(colorOpacity)


//let valNodeColor: Color = Color.gray.opacity(colorOpacity)
//let calcNodeColor: Color = Color.yellow.opacity(colorOpacity)
//let vizNodeColor: Color = Color.blue.opacity(colorOpacity)




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
//    Line(from: from, to: to).stroke().animation(.default)
    
    // teal / cyan
//    let color: Color = Color(red: 0, green: 255, blue: 255, opacity: 0.8)
    
    return Line(from: from, to: to)
//        .stroke(Color.green.brightness(0.9), lineWidth: 10)
//        .stroke(lineWidth: 10.0)
        .stroke(edgeColor,
                style: StrokeStyle(lineWidth: portAndEdgeWidth, // 10,
                                   lineCap: .round,
                                   lineJoin: .round))
        .animation(.default)
        .zIndex(2) // added
//        .foregroundColor(Color.green.brightness(0.9))
}

// common
//typealias <#type name#> = <#type expression#>


struct PlusButton: View {
    
    // dragging
    @State private var localPosition: CGSize = CGSize.zero
    @State private var localPreviousPosition: CGSize = CGSize.zero
 
    @State private var showPopover: Bool = false // not persisted
    
    let radius: CGFloat = 80 // 30
    
    let dispatch: Dispatch
    
    var body: some View {
        Circle().stroke(Color.black)
        
//        .offset(x: localPosition.width, y: localPosition.height)
        
        .overlay(LinearGradient(gradient: Gradient(colors: [Color.white, Color.green]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
            ))
        
        .overlay(Image(systemName: "plus"))
        .clipShape(Circle())
        .frame(width: CGFloat(radius), height: CGFloat(radius))
            
            // added:
            .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                 VStack (spacing: 20) {
//                         Text("Node ID: \(node.nodeId)")
                    
//                         Text("Node Serial: \(info)")
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
//                    Button("calcNode: string concat") {
//                       dispatch(NodeCreatedAction())
//                    }
                    
                 }.padding()
             }
            
        .onTapGesture(count: 1, perform: {
                log("Plus button clicked")
//                playSound(sound: "positive_ping", type: "mp3")
//                dispatch(NodeCreatedAction())
                self.showPopover.toggle()
            })
            
        .offset(x: localPosition.width, y: localPosition.height)
        .gesture(DragGesture()
                            .onChanged {
                                self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
                            }
                            .onEnded { _ in
                                self.localPreviousPosition = self.localPosition
                            })
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
    
    // should these properties of NodeModel?
    let title: String
    let color: Color
    
    let spacing: CGFloat = 20
    
    var body: some View {
    
//        let ascending = { (pm1: PortModel, pm2: PortModel) -> Bool in pm1.id < pm2.id }
//
        let inputs: [PortModel] = nodeModel
            .ports
            .filter { $0.portType == PortType.input }
            .sorted(by: ascending)
        
        let outputs: [PortModel] = nodeModel.ports.filter { (pm: PortModel) -> Bool in
            pm.portType == PortType.output
        }.sorted(by: ascending)
        
                
        // must switch to a clear model of
        VStack (spacing: spacing) {
         // top
            Text("\(nodeModel.nodeType.rawValue) \(nodeModel.id)")
                .padding(5)
                .background(Color.gray.opacity(0.4))
                
                // added
                .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                     VStack (spacing: 20) {
//                         Text("Node ID: \(node.nodeId)")
                        Text("Node ID: \(nodeModel.id)")
//                         Text("Node Serial: \(info)")
                         Button("Delete") {
                            log("delete button pressed...")
                            dispatch(NodeDeletedAction(id: nodeModel.id))
                         }
                        
                     }.padding()
                 }
            
//                .shadow(radius: 20)
            
            nodeModel.operation != nil ?
                Text("\(nodeModel.operation!.rawValue)")
                    .padding(5)
                    .background(Color.gray.opacity(0.4))
                : nil
  
            
//            nodeModel.previewElement != nil ?
            nodeModel.previewModel != nil ?
//                Text("\(nodeModel.previewElement!.rawValue)")
                Text("\(nodeModel.previewModel!.previewElement.rawValue)")
                    .padding(5)
                    .background(Color.gray.opacity(0.4))
                : nil
            
            
//            nodeModel.previewInteraction != nil ?
            nodeModel.interactionModel != nil ?
//                Text("\(nodeModel.interactionModel!.rawValue)")
                Text("\(nodeModel.interactionModel!.previewInteraction.rawValue) for node \(nodeModel.interactionModel!.forNodeId)")
                    .padding(5)
                    .background(Color.gray.opacity(0.4))
                : nil
            
            
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
        
        
        .padding()
//        .background(color.opacity(0.3))
        .background(color)
        .offset(x: localPosition.width, y: localPosition.height)
        
        // added
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
        .frame(maxHeight: 600)
//        .shadow(radius: 15)
    }
}



//for both inputs and outputs (calc node)
// Hstack + vstacks
struct DualPortTypeView: View {

    let inputs: [PortModel]
    let outputs: [PortModel]
    let state: AppState
    let dispatch: Dispatch
    
    let spacing: CGFloat = 10
    
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
    
    let spacing: CGFloat = 20
    
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
        }
    }
}


let commonSpacing: CGFloat = 10


// fill port's color
func fillColor(hasEdge: Bool, thisPM: PortModel, activePM: PortModel?) -> Color {
//        log("fillColor called for node \(pm.nodeId), port \(pm.id)")
    
    let isActivePort: Bool = activePM?.nodeId == thisPM.nodeId && activePM?.id == thisPM.id
    
    let defaultColor: Color = Color.white.opacity(1.0)

    // Arranged by color priority:
    // activePort: highest priority
    // coloredPorts
    // hasEdge
    // default: lowest priority
    
    if isActivePort {
//        return edgeColor // active port always looks like this...
        return isActiveColor
    }
    else if case .color(let x) = thisPM.value {
//        return x.color
//        switch x {
//            case greenColorString: return Color.green
//            case purpleColorString: return Color.purple
//            default: return defaultColor // temporary...
//        }
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

//    let isOptionPicker: Bool
    
    

    var body: some View {
        let portDot = Circle()
//            .stroke(hasEdge ? edgeColor : Color.black)
//            .fill((hasEdge || isActivePort) ? edgeColor : Color.white.opacity(1.0))
            .fill(fillColor(hasEdge: hasEdge, thisPM: pm, activePM: state.activePM))
//            .fill((hasEdge || isActivePort) ? edgeColor : nodeEmptyPortColor)
//            .background(isActivePort ? edgeColor : Color.white.opacity(1.0))
            .clipShape(Circle())
//            .frame(width: 30, height: 30)
            .frame(width: portAndEdgeWidth, height: portAndEdgeWidth)
            .anchorPreference(key: PortPreferenceKey.self,
                              value: .center,
                              transform: {
                                [PortPreferenceData(viewIdx: pm.nodeId,
                                                    center: $0,
                                                    nodeId: pm.nodeId,
                                                    portId: pm.id)] })

            .onTapGesture(count: 1, perform: {
                log("PortView tap called: Node \(pm.nodeId), Port \(pm.id), Value: \(pm.value)")
                log("PortView tap called: current pm is: \(state.activePM)")
                
                dispatch(PortTappedAction(port: pm))
            })
                
        let displayablePortValue: String = getDisplayablePortValue(mpv: pm.value)
        
        let portValue = Text(displayablePortValue)
        
        VStack (spacing: 10) {
            Text("Port \(pm.id)") // for debug, really
            
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
        }
    }
}


// ball's new position = old position + displacement from current drag gesture
func updatePosition(value: DragGesture.Value, position: CGSize) -> CGSize {
    CGSize(width: value.translation.width + position.width,
           height: value.translation.height + position.height)
}


struct Shapes_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}

