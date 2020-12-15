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
//    Line(from: from, to: to).stroke().animation(.default)
    
    
    // teal / cyan
    let color: Color = Color(red: 0, green: 255, blue: 255, opacity: 0.8)
    
    return Line(from: from, to: to)
//        .stroke(Color.green.brightness(0.9), lineWidth: 10)
//        .stroke(lineWidth: 10.0)
        .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        .animation(.default)
//        .foregroundColor(Color.green.brightness(0.9))
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
//            Text(title)
            Text("\(nodeModel.nodeType.rawValue) \(nodeModel.id)")
                // should be frame that covers whole space
//                .padding()
                .background(Color.gray.opacity(0.4))
            
            nodeModel.operation != nil ?
                Text("\(nodeModel.operation!.rawValue)")
                    .padding(10)
                    .background(Color.gray.opacity(0.4))
                : nil
  
            
            nodeModel.previewElement != nil ?
                Text("\(nodeModel.previewElement!.rawValue)")
                    .padding(10)
                    .background(Color.gray.opacity(0.4))
                : nil
            
            
            switch nodeModel.nodeType {
                case .valNode:
                    SinglePortTypeView(ports: outputs, state: state, dispatch: dispatch, isInput: false)
                case .calcNode:
                    DualPortTypeView(inputs: inputs, outputs: outputs, state: state, dispatch: dispatch)
                case .vizNode:
                    SinglePortTypeView(ports: inputs, state: state, dispatch: dispatch, isInput: true)
            }
            
        }
        .padding()
        .background(color.opacity(0.3))
        .offset(x: localPosition.width, y: localPosition.height)
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
                          isInput: true)
                }
            }
            
            // right side
            VStack (spacing: spacing) {
                ForEach(outputs, id: \.id) {
                    (output: PortModel) in
                    PortView(pm: output, dispatch: dispatch, state: state, isInput: false)

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
                PortView(pm: port, dispatch: dispatch, state: state, isInput: isInput)
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
    
    let isInput: Bool

    var body: some View {

        let isActivePort: Bool = state.activePM?.nodeId == pm.nodeId && state.activePM?.id == pm.id

        let portDot = Circle()
            .stroke(Color.black)
            .background(isActivePort ? Color.green.opacity(1.0) : Color.white.opacity(1.0))
            .clipShape(Circle())
            .frame(width: 30, height: 30)
            .anchorPreference(key: PortPreferenceKey.self,
                              value: .center,
                              transform: {
                                [PortPreferenceData(viewIdx: pm.nodeId,
                                                    center: $0,
                                                    nodeId: pm.nodeId,
                                                    portId: pm.id)] })

            .onTapGesture(count: 1, perform: {
                log("PortView tap called: Node \(pm.nodeId), Port \(pm.id), Value: \(pm.value)")
                dispatch(PortTappedAction(port: pm))

            })
        
        let portValue = Text(pm.value)
        
        VStack (spacing: 10) {
//            Text(pm.label)
            
            Text("Port \(pm.id)") // for debug, really
            
            if isInput == true {
                HStack {
                    portDot
                    portValue.frame(minWidth: 60)
                }
                
            } else {
                HStack {
                    portValue.frame(minWidth: 60)
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


// original
//struct PortView: View {
//
//    let pm: PortModel
//
//    let dispatch: Dispatch
//    let state: AppState
//
//    let radius: CGFloat = 80
//
//    var body: some View {
//
//        let isActivePort: Bool = state.activePM?.nodeId == pm.nodeId && state.activePM?.id == pm.id
//
//        VStack (spacing: 10) {
//            Text(pm.label)
////            Text("Node \(pm.nodeId), Port \(pm.id)")
//            Circle().stroke(Color.black)
//                .overlay(Text(pm.value))
//                .background(isActivePort ? Color.green.opacity(1.0) : Color.white.opacity(1.0))
//
//                .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
//                .frame(width: radius, height: radius)
//
//                .anchorPreference(key: PortPreferenceKey.self,
//                                  value: .center,
//                                  transform: {
//                                    [PortPreferenceData(viewIdx: pm.nodeId,
//                                                        center: $0,
//                                                        nodeId: pm.nodeId,
//                                                        portId: pm.id)] })
//
//                .onTapGesture(count: 1, perform: {
//                    log("PortView tap called: Node \(pm.nodeId), Port \(pm.id), Value: \(pm.value)")
//
//                    // prev: dispatched based on passed around connecting-node
////                    dispatch(PortTapped(
////                                port: PortIdentifier(
////                                    nodeId: pm.nodeId,
////                                    portId: pm.id,
////                                    isInput: pm.portType == .input)))
//
//                    // CANNOT USE THE VALUE HERE, because e.g. the value will be the value of the tapped port, which might be an output
//                    dispatch(PortTappedAction(port: pm))
//
//                })
//        }
//    }
//}
//
