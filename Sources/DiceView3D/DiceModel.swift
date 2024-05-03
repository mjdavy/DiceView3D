//
//  DiceModel.swift
//  Yeeha!
//
//  Created by Martin Davy on 3/18/24.
//

import Foundation
import UIKit

public enum FaceRenderingScheme {
    case namedImage
    case string
}

@Observable
public class DiceModel {
    var dice: [Die]
    var roll = false
    var canSelectDice = false
    var arrangeDice = false
    var onRollComplete: (([Int]) -> Void)? // Closure to be executed when the dice roll completes
    var faceScheme: FaceRenderingScheme
    var faces: [String]
    var foregroundColor : UIColor
    var backgroundColor : UIColor
    var selectedColor : UIColor
    
    public init(initialValues: [Int], 
         faceScheme: FaceRenderingScheme = .namedImage,
         faces: [String] = (1...6).map { "dice\($0)" },
         foregroundColor : UIColor = .black,
         backgroundColor : UIColor = .white,
         selectedColor : UIColor = .orange,
         canSelect : Bool = false) {
        
        let count = initialValues.count
        precondition(count >= 1 && count <= 6, "Count must be between 1 and 6")
        precondition(faces.count == 6, "Dice must have 6 faces")
        self.dice = initialValues.enumerated().map {
            Die(name: "dice\($0.offset + 1)",
                value: $0.element,
                isSelected: false
            )
        }
        self.faceScheme = faceScheme
        self.faces = faces
        self.canSelectDice = canSelect
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.selectedColor = selectedColor
    }
    
    var values: [Int] {
        return dice.map { $0.value }
    }
    
    var numberOfDice : Int {
        dice.count
    }
    
    func getDie(byName dieName: String) -> Die? {
        // Find the die with the given name
        return dice.first(where: { $0.name == dieName })
    }
    
    func isSelected(dieName: String) -> Bool {
        // Find the die with the given name
        if let die = dice.first(where: { $0.name == dieName }) {
            // Return the selection state of the die
            return die.isSelected
        } else {
            print("Error: Unable to find die with name \(dieName)")
            return false
        }
    }
    
    func updateValue(byName dieName: String, with value: Int) {
        // Find the die with the given name
        if let index = dice.firstIndex(where: { $0.name == dieName }) {
            // Update the value of the die
            dice[index].value = value
        } else {
            print("Error: Unable to find die with name \(dieName)")
        }
    }
    
    func toggleSelection(byName dieName: String) {
        
        guard canSelectDice else {
            return
        }
        
        // Find the die with the given name
        if let index = dice.firstIndex(where: { $0.name == dieName }) {
            // Toggle the selection state of the die
            dice[index].isSelected.toggle()
        } else {
            print("Error: Unable to find die with name \(dieName)")
        }
    }
}

struct Die {
    let name : String
    var value : Int
    var isSelected : Bool
}
