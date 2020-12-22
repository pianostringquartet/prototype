//
//  Sample.swift
//  prototype
//
//  Created by cjc on 12/17/20.
//

import Foundation
import SwiftUI
import ReSwift


/* ----------------------------------------------------------------
 Sample colors
 ---------------------------------------------------------------- */

let trueColor = Color.green
let greenColorString = "green"
let trueColorString = greenColorString

let falseColor = Color.purple
let purpleColorString = "purple"
let falseColorString = purpleColorString



/* ----------------------------------------------------------------
 Sample nodes, state etc.
 ---------------------------------------------------------------- */


// ids


let valNodeId0 = 0
let valNodeId = 1
let valNodeId2 = 2
let valNodeId3 = 3

let calcNodeId = 4
let calcNodeId2 = 5
let calcNodeId3 = 6 // option picker

let vizNodeId = 7
let vizNodeId2 = 8
let vizNodeId3 = 9


//let createdValNodeId =



let previewModelId = 1
let previewModelId2 = 2
let previewModelId3 = 3

// nodes

let valNode0 = stringValNode(id: valNodeId0, value: "salut")
let valNode = stringValNode(id: valNodeId, value: "hello")
//let valNode2 = stringValNode(id: valNodeId2, value: "world")

// TWO interactions nodes
//let valNode2 = pressInteractionNodeModel(id: valNodeId2, forNodeId: vizNodeId)

let valNode2 = dragInteractionNodeModel(id: valNodeId2, forNodeId: vizNodeId, forPreviewModelId: previewModelId)

let valNode3 = pressInteractionNodeModel(id: valNodeId3, forNodeId: vizNodeId2, forPreviewModelId: previewModelId2)

//let valNode3 = dragInteractionNodeModel(id: valNodeId3, forNodeId: vizNodeId2)


let calcNode = concatNodeModel(id: calcNodeId)
//let calcNode2 = uppercaseNodeModel(id: calcNodeId2)

// TWO color option pickers
let calcNode2 = optionPickerNodeModel(id: calcNodeId2)

let calcNode3 = optionPickerNodeModel(id: calcNodeId3)


//let vizNode: NodeModel = stringVizNode(id: vizNodeId, value: "",
//                                       previewModel: PreviewModel(id: previewModelId,
//                                                                  nodeId: vizNodeId,
//                                                                  previewElement: PreviewElement.text),
//                                       label: "TextLayer")


let vizNode: NodeModel = textLayerVizNode(nodeId: vizNodeId, previewModelId: previewModelId)
let vizNode2: NodeModel = textLayerVizNode(nodeId: vizNodeId2, previewModelId: previewModelId2)



//let vizNode2: NodeModel = stringVizNode(id: vizNodeId2, value: "Purple", previewElement: PreviewElement.typographyColor, label: "TypographyColor")

//let vizNode2: NodeModel = colorVizNode(id: vizNodeId2,
//                                       value: falseColorString,
//                                       previewModel: PreviewModel(id: previewModelId2,
//                                                                  nodeId: vizNodeId2,
//                                                                  previewElement: PreviewElement.typographyColor),
//                                       label: "TypographyColor")


// a second text layer
//let vizNode3: NodeModel = stringVizNode(id: vizNodeId3, value: "",
//                                       previewModel: PreviewModel(id: previewModelId3,
//                                                                  nodeId: vizNodeId3,
//                                                                  previewElement: PreviewElement.text),
//                                       label: "TextLayer")



// state

// REMOVED CONCAT FOR NOW
//let hwState = AppState(nodeModels: [valNode, valNode2, valNode3, calcNode2, calcNode3, vizNode, vizNode2])

let hwState = AppState(nodeModels: [
    valNode0,
    valNode,
                                    valNode2,
                                    valNode3,
                                    calcNode2,
//                                    calcNode3,
                                    vizNode,
    
    vizNode2
    
//                                    vizNode3 // additional text layer
])


let sampleStore = Store<AppState>(
    reducer: reducer,
    state: hwState
)
