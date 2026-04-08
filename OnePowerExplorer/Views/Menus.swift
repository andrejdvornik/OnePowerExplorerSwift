//
//  Menus.swift
//  OnePowerExplorer
//
//  Created by Andrej Dvornik on 08.04.26.
//

import SwiftUI

struct Menus: Commands {
    @FocusedObject var vm: ExplorerViewModel?
    
    var body: some Commands {
        SidebarCommands()
        ToolbarCommands()
        CommandGroup(replacing: .newItem) { }
        CommandGroup(before: .saveItem) {
            Button("Set", systemImage: "plus") {
                vm?.setReferenceModel()
            }
            .disabled(vm?.computedOutputs.isEmpty ?? true)
            .help("Set the current computed outputs as the reference model for comparison")
            
            .keyboardShortcut("R", modifiers: .command)
            Button("Clear", systemImage: "trash") {
                vm?.clearReferenceModel()
            }
            .disabled(vm?.referenceModel == nil)
            .help("Clear the reference model")
            .keyboardShortcut("X", modifiers: .command)
            
            Button("Reset", systemImage: "arrow.uturn.backward") {
                vm?.params.resetParameters()
            }
            .help("Reset all parameters to their default values")
            .keyboardShortcut("Z", modifiers: .command)
        }
        // Remove Undo / Redo
        CommandGroup(replacing: .undoRedo) { }
            
        // Remove Cut / Copy / Paste / Select All
        CommandGroup(replacing: .pasteboard) { }
            
        // Optional: remove Find / Spelling menu items
        CommandGroup(replacing: .textEditing) { }
    }
}
