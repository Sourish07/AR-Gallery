//
//  Counter.swift
//  AR Gallery
//
//  Created by Sourish Kundu on 9/18/22.
//

import Foundation

class Counter: ObservableObject {
    var upperBound: Int
    var value: Int
    
    init(upperBound: Int) {
        self.upperBound = upperBound
        self.value = 0
    }
    
    func get() -> Int {
        return self.value
    }
    
    func increment() {
        self.value = (self.value + 1) % self.upperBound
    }
    
    func getAndIncrement() -> Int {
        let toReturn = self.get()
        self.increment()
        return toReturn
    }
    
}
