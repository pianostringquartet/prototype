//
//  PreviewHelpers.swift
//  prototype
//
//  Created by cjc on 12/21/20.
//

import Foundation
import SwiftUI
import ReSwift


//
//// update a node's previous model
//func updatePreviewModel() -> NodeModel {
//
//
//}


func isBasePreviewElement(pe: PreviewElement) -> Bool {
    log("isBasePreviewElement called")
    switch pe {
        case .text, .imageLayer:
            return true
        case .typographyColor:
            return false
    }
}



//// for some reason, when if baseVn.previewElement! etc. is added,
//// we get "Function declares an opaque return type, but the return statements in its body do not have matching underlying types"
////func generateMiniview(state: AppState, dispatch: @escaping Dispatch) -> some View {
//
//// `some View` is a specific view-type;
//// instead, use `AnyView` since the view-type returned is dynamic
//func generateMiniview(state: AppState, dispatch: @escaping Dispatch) -> AnyView {
//    log("generateMiniview called")
//
//    // state would contain these values?
//    // iterate through vizModels/uiElems in state,
//    // iterate through the (input) PortModels of the VizNodes;
//    // these inputs contain eg. `Typography Text`, `Typography Color`
//
//    let vns: [NodeModel] = state.nodeModels.filter { $0.nodeType == .vizNode }
//
//    log("generateMiniview: vns: \(vns)")
//
//
////    let baseVn: NodeModel = vns.first { (nm: NodeModel) -> Bool in
////        log("baseVn: nm.previewModel!.previewElement: \(nm.previewModel!.previewElement)")
//////        return isBasePreviewElement(pe: nm.previewElement!)
////        return isBasePreviewElement(pe: nm.previewModel!.previewElement)
////    }!
//
//    let bases: [NodeModel] = vns.filter { (nm: NodeModel) -> Bool in
//        log("buildPreview: nm.previewModel!.previewElement: \(nm.previewModel!.previewElement)")
//        return isBasePreviewElement(pe: nm.previewModel!.previewElement)
//    }
//
//    let baseVn: NodeModel = bases.first!
////    let baseVn2: NodeModel = bases[1] // should be the second textlayer
//
//    let modifierVn: NodeModel? = vns.first { (nm: NodeModel) -> Bool in
//        log("baseVn: nm.previewModel!.previewElement: \(nm.previewModel!.previewElement)")
//        return !isBasePreviewElement(pe: nm.previewModel!.previewElement)
//    }
//
//    // ui base vs ui modifier
//    // ui base = eg Text, Image
//    // ui modifier = eg TypographyColor
//    // grab every VizNode base
//
//
//    // retrieve the correct base UI...
//    if baseVn.previewModel!.previewElement == .text {
//
//        let display: String = getDisplayablePortValue(mpv: baseVn.ports.first!.value)
//
//
//        // can't just build text like this --
//        // need to iterate through ALL
////        let preview: ZStack = ZStack {
////            baseVn.previewModel!.
////        }
////
//
//        let text = Text(display)
//            .font(.largeTitle)
//            .gesture(DragGesture(minimumDistance: 0)
//                        .onChanged { _ in
//                            log("onChanged inside generateMiniview")
////                            dispatch(TextTappedMiniviewAction())
//                            dispatch(TextTappedMiniviewAction(nodeId: baseVn.id))
//
//                        }
//                        .onEnded { _ in
//                            log("onEnded inside generateMiniview")
////                            dispatch(TextTappedMiniviewAction())
//                            dispatch(TextTappedMiniviewAction(nodeId: baseVn.id))
//
//                        }
//            )
//
//        // add any potential modifiers...
////        if modifierVn.previewElement! == .typographyColor {
////        if modifierVn.previewModel!.previewElement == .typographyColor {
//        if modifierVn != nil && modifierVn!.previewModel!.previewElement == .typographyColor {
//
//            if case .color(let x) = modifierVn!.ports.first!.value {
//                return AnyView(text.foregroundColor(colorFromString(x)).padding())
////                return AnyView(text.foregroundColor(x.color).padding())
//            }
//        }
//
//        return AnyView(text.padding())
//    }
//
//
//    else {
//        let defaultView = Text("No base UI found...").padding()
//        return AnyView(defaultView)
//    }
//
//
//    // how do you identify the 'base' view (e.g. `Text`) vs a modifier (e.g. `TypographyColor`)?
//    // how do you know which modifiers go with which bases, and in which order?
//    // eg what if you have two different `TextLayers` in the graph, and want each to be a different color?
//
//    // some modifiers obviously only apply to Text (e.g. TypographyColor)
//    // other modifiers obviously only apply to Image
//
//    // FOR NOW?: assume one Base (Text) and one modifier (Color)
//
//}


func generateMiniview(state: AppState, dispatch: @escaping Dispatch) -> AnyView {
    log("generateMiniview called")
    
    // state would contain these values?
    // iterate through vizModels/uiElems in state,
    // iterate through the (input) PortModels of the VizNodes;
    // these inputs contain eg. `Typography Text`, `Typography Color`
    
    let vns: [NodeModel] = state.nodeModels.filter { $0.nodeType == .vizNode }
    
    log("generateMiniview: vns: \(vns)")
    
    return buildPreview(state: state, vns: vns, dispatch: dispatch)
    
}


// vns should be viznodes only
func buildPreview(state: AppState, vns: [NodeModel], dispatch: @escaping Dispatch) -> AnyView {
    log("buildPreview called")
    
    // gather up all the base viz nodes,
    // and the modifiers
    
    let bases: [NodeModel] = vns.filter { (nm: NodeModel) -> Bool in
        log("buildPreview: nm.previewModel!.previewElement: \(nm.previewModel!.previewElement)")
        return isBasePreviewElement(pe: nm.previewModel!.previewElement)
    }.sorted(by: ascendingNodes)
    
    
    if bases.isEmpty {
        let defaultView = Text("buildPreview: No base UI found").padding()
        return AnyView(defaultView)
    
    } else {
        
        let preview: ZStack = ZStack {
            // ForEach ... wrapped in anyview?
            
//            ForEach(bases, id: \.id) { (base: NodeModel) in
            ForEach(bases, id: \.id) { (base: NodeModel) in
                viewFromBasePreviewModel(nodes: state.nodeModels,
                                         node: base,
                                         preview: base.previewModel!,
                                         dispatch: dispatch)

            }
            
            // for now, assume one base layer
//            let base: NodeModel = bases.first!
//            viewFromBasePreviewModel(nodes: state.nodeModels,
//                                     node: base,
//                                     preview: base.previewModel!,
//                                     dispatch: dispatch)

            
            
            // HARDCODED: for demo purposes
            Text("Example").offset(x: 50, y: 50)
            
        }
        
        return AnyView(preview)
    }
}


// assume no modifier viz nodes for now
// given a preview model, get a view
func viewFromBasePreviewModel(nodes: [NodeModel], // all nodes from state
                              node: NodeModel, // ie the base node ie the viz layer node
                              preview: PreviewModel,
//                              interaction: PreviewInteraction,
                              dispatch: @escaping Dispatch) -> AnyView {

    log("viewFromBasePreviewModel called; node.id: \(node.id)")
    
    // must be sorted consistently
    let ports: [PortModel] = node.ports.sorted(by: ascending)
    
    let interaction: InteractionModel = getInteractionNode(nodes: nodes, vizNodeId: node.id).interactionModel!
    

    switch preview.previewElement {
                
        // TextLayer's have string input and color input
        case .text:
            log("viewFromBasePreviewModel: matched on .text")
            let display: String = getDisplayablePortValue(mpv: ports[0].value)
            
            var color: Color = Color.black
            if case .color(let x) = ports[1].value {
                color = x
            }
            
            let text = Text(display)
                .font(.largeTitle)
                // .gesture // originally
                .foregroundColor(color).padding()
                
                // offset shold be contained within the previewModel?
//                .offset(x: -60, y: -60)
                .offset(x: preview.position.width, y: preview.position.height)
            
            
//            return AnyView(text)
            return AnyView(addTextLayerInteraction(text: AnyView(text), // text as! AnyView,
                                                   node: node,
                                                   preview: preview,
                                                   // where to get the interaction?
                                                   interaction: interaction,
                                                   dispatch: dispatch))

        case .imageLayer:
            return AnyView(Text("Please implement Image..."))
        default:
            return AnyView(Text("Failure..."))
    }

}


func addTextLayerInteraction(text: AnyView, // Text,
                             node: NodeModel, // the vizlayer node for this preview text
                             preview: PreviewModel,
                             interaction: InteractionModel,
                             dispatch: @escaping Dispatch) -> some View {
    
    log("addTextLayerInteraction called; node.id: \(node.id)")
    
    
    switch interaction.previewInteraction {
        case .press:
            log("addTextLayerInteraction: matched on .press")
            return text
                .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                log(".press onChanged inside generateMiniview")
                                dispatch(TextTappedMiniviewAction(nodeId: node.id))
                                
                            }
                            .onEnded { _ in
                                log(".press onEnded inside generateMiniview")
                                dispatch(TextTappedMiniviewAction(nodeId: node.id))
                            }
                )
        
        
        
        // for now, don't
        case .drag:
            log("addTextLayerInteraction: matched on .drag")
            return text
                .gesture(DragGesture()
                            .onChanged {
                                log(".drag onChanged inside generateMiniview")
//                                self.localPosition = updatePosition(value: $0, position: self.localPreviousPosition)
//
                                var localPreviousPosition: CGSize = preview.position
                                var localPosition: CGSize = updatePosition(value: $0,
                                                                   position: localPreviousPosition)
                                
                                dispatch(TextMovedMiniviewAction(textLayerId: node.id,
                                                                 position: localPosition,
                                                                 previousPosition: localPreviousPosition))
                            }
                            .onEnded {
                                log(".drag onEnded inside generateMiniview")
                                // i.e. no anchoring for now
//                                self.localPreviousPosition = self.localPosition
                                
                                var localPreviousPosition: CGSize = preview.position
                                var localPosition: CGSize = updatePosition(value: $0,
                                                                   position: localPreviousPosition)
                     
                                dispatch(TextMovedMiniviewAction(textLayerId: node.id,
                                                                 position: localPosition,
                                                                 previousPosition: localPreviousPosition))
                            }
                ) // .gesture
        
        default:
            Text("Failed to add interaction to TextLayer")
    }
    

}
