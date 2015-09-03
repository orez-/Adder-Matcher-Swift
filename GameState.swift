//
//  GameState.swift
//  AdderMatcher
//
//  Created by Brian Shaginaw on 9/1/15.
//  Copyright (c) 2015 Brian Shaginaw. All rights reserved.
//

import Foundation

let SIZE = 5
let START_MAX_VALUE:UInt32 = 3
let MAX_HEALTH = 5
let MINIMUM_COLLAPSE = 3


struct Coord:Hashable, Printable {
    let row:Int
    let col:Int
    
    var hashValue: Int {
        return row ^ col
    }
    
    var description : String {
        return "(\(row), \(col))"
    }
}

func ==(lhs: Coord, rhs: Coord) -> Bool {
    return lhs.row == rhs.row && lhs.col == rhs.col
}


func in_bounds(coord: Coord) -> Bool {
    return 0 <= coord.row && coord.row < SIZE && 0 <= coord.col && coord.col < SIZE
}


class GameState {
    var board:[[UInt32]]
    var _highest:UInt32
    var score:UInt32
    
    init() {
        self.board = Array(map(1...SIZE) {_ in Array(map(1...SIZE) {_ in arc4random_uniform(START_MAX_VALUE) + 1})})
        self._highest = START_MAX_VALUE
        self.score = 0
        
//        self._collapse_all()
        
        self.score = 0
    }
    
    func advance_tile(c:Coord) {
        println(c.row, c.col)
    }
    
    func _neighbors(c:Coord) -> [(Coord, UInt32)] {
        return filter([
            Coord(row:c.row - 1, col:c.col),
            Coord(row:c.row, col:c.col - 1),
            Coord(row:c.row + 1, col:c.col),
            Coord(row:c.row, col:c.col + 1),
            ], in_bounds).map({(c:Coord) -> (Coord, UInt32) in (c, self.board[c.row][c.col])})
    }
    
    func _collapse_all() {
        while true {
            let matches = self._find_matches()
            if matches == nil {break}
            let (r_c, collapse_set) = matches!
            self._collapse(collapse_set, coord:r_c)
        }
    }
    
    /*
    Find the first contiguous set of tiles whose values match in
    a sizeable group (as determined by MINIMUM_COLLAPSE) and return
    the coordinate to which they should collapse and their set.
    
    Search order is reading order: left to right, top to bottom.
    */
    func _find_matches() -> (Coord, Set<Coord>)? {
        var seen_set:Set<Coord> = Set()
        for (r, row) in enumerate(self.board) {
            for (c, number) in enumerate(row) {
                let r_c = Coord(row:r, col:c)
                if seen_set.contains(r_c) {continue}
                let collapse_set = self._get_matches_at(r_c)
                if collapse_set.count >= MINIMUM_COLLAPSE {return (r_c, collapse_set)}
                seen_set.unionInPlace(collapse_set)
            }
        }
        return nil
    }
    
    /*
    Get the contiguous set of tiles whose values match those at the
    given coordinate.
    */
    func _get_matches_at(coord:Coord) -> Set<Coord> {
        let num = self.board[coord.row][coord.col]
        var collapse_set:Set<Coord> = Set()
        // Swift doesn't have native queues, maybe I'll build my own
        // later, but for now this list will have to do.
        var queue = [coord]
        while !queue.isEmpty {
            let r_c = queue.removeAtIndex(0)  // *wince*
            for (coord, elem) in self._neighbors(r_c) {
                if elem == num && !collapse_set.contains(coord) {
                    queue.append(coord)
                    collapse_set.insert(coord)
                }
            }
        }
        return collapse_set
    }
    
    func _collapse(collapse_set:Set<Coord>, coord:Coord) -> [GameState] {
        var consequences:[GameState] = []
        
        // let value = self.board[][]
        
        return consequences
    }
}

