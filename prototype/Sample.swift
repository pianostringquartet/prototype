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

//let trueColor2 = Color2(g: 1.0)



let falseColor = Color.purple
let purpleColorString = "purple"
let falseColorString = purpleColorString
//let falseColor2 = Color2(r: 0.5, b: 0.5)



/* ----------------------------------------------------------------
 Sample nodes, state etc.
 ---------------------------------------------------------------- */


// ids

let valNodeId = 1
let valNodeId2 = 2
let valNodeId3 = 3 // press-interaction node ('as a val-node')

let calcNodeId = 4
let calcNodeId2 = 5
let calcNodeId3 = 6 // option picker

let vizNodeId = 7
let vizNodeId2 = 8


// nodes

let valNode = stringValNode(id: valNodeId, value: "hello")
let valNode2 = stringValNode(id: valNodeId2, value: "world")
let valNode3: NodeModel = pressInteractionNodeModel(id: valNodeId3)


let calcNode = concatNodeModel(id: calcNodeId)
let calcNode2 = uppercaseNodeModel(id: calcNodeId2)
let calcNode3 = optionPickerNodeModel(id: calcNodeId3)


let vizNode: NodeModel = stringVizNode(id: vizNodeId, value: "", previewElement: PreviewElement.text, label: "TextLayer")

//let vizNode2: NodeModel = stringVizNode(id: vizNodeId2, value: "Purple", previewElement: PreviewElement.typographyColor, label: "TypographyColor")

let vizNode2: NodeModel = colorVizNode(id: vizNodeId2,
                                       value: falseColorString,
                                       previewElement: PreviewElement.typographyColor, label: "TypographyColor")


// state

// REMOVED CONCAT FOR NOW
let hwState = AppState(nodeModels: [valNode, valNode2, valNode3, calcNode2, calcNode3, vizNode, vizNode2])

let sampleStore = Store<AppState>(
    reducer: reducer,
    state: hwState
)
