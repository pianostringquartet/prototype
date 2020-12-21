//
//  PreviewData.swift
//  prototype
//
//  Created by cjc on 12/21/20.
//

import Foundation
import ReSwift
import SwiftUI

// MARK: - MINIVIEWER MODELS

/* ----------------------------------------------------------------
 `Viz-layer -> miniviewer` models
 ---------------------------------------------------------------- */

struct PreviewModel: Equatable, Codable {
    let id: Int // ui element's id
    let nodeId: Int // node id for
    let previewElement: PreviewElement // eg TextLayer, ImageLayer etc.
    
//    let interactionId: Int? = nil // the interaction for this preview model, if any
//    let interactionId: Int?
    
    // modify these upon instantiation
    var position: CGSize = CGSize.zero
    var previousPosition: CGSize = CGSize.zero
    
    func updatePosition(position: CGSize? = nil,
                        previousPosition: CGSize? = nil) -> PreviewModel {
        
        log("PreviewModel updatePosition called")
        
        return PreviewModel(id: self.id, nodeId: self.nodeId, previewElement: self.previewElement,
//                            interactionId: self.interactionId,
                            position: position ?? self.position, previousPosition: previousPosition ?? self.previousPosition)
    }
}


// PMs are turned into the SwiftUI components we see in the preview;

struct PM: Equatable, Codable {
    let id: Int // ui element's
    
    // NO 'node id'; a viz node must have a preview model, but a
    
    // might have an interaction
    let interaction: IM?
    
    var position: CGSize = CGSize.zero
    var previousPosition: CGSize = CGSize.zero
}


struct IM: Equatable, Codable {
    let id: Int
    let previewModelId: Int // the specific PM this interaction is for
//    let
    let interactionType: PreviewInteraction
}


// string is user displayable?
// and then these get matched in a gigantic
enum PreviewElement: String, Codable {
    case text = "TextLayer"
    case typographyColor = "TypographyColor"
    case imageLayer = "ImageLayer"
}


struct InteractionModel: Equatable, Codable {
    let id: Int
    let nodeId: Int // node id on which interaction resides
    let forNodeId: Int // node id (viz node) which the interaction is FOR
    
    // the preview model this intrxn is for;
    // not all preview models have interactions;
    // but every interaction is tied to a preview model
    let forPreviewModelId: Int
    
    let previewInteraction: PreviewInteraction
    
    
}


enum PreviewInteraction: String, Codable {
    case press = "Press"
    case drag = "Drag"
}



