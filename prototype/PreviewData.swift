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
        
    // modify these upon instantiation
    var position: CGSize = CGSize.zero
    var previousPosition: CGSize = CGSize.zero
    
    func updatePosition(position: CGSize? = nil,
                        previousPosition: CGSize? = nil) -> PreviewModel {
        
        log("PreviewModel updatePosition called")
        
        return PreviewModel(id: self.id, nodeId: self.nodeId, previewElement: self.previewElement,
                            position: position ?? self.position, previousPosition: previousPosition ?? self.previousPosition)
    }
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



