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


private func in_bounds(coord: Coord) -> Bool {
    return 0 <= coord.row && coord.row < SIZE && 0 <= coord.col && coord.col < SIZE
}


enum GameState {
    case awaiting_action
    case falling
    case check_collapse
    case dead
}


class Game {
    var board:[[UInt32]]!
    private var highest:UInt32
    var score:UInt32
    var state:GameState
    var health:Int

    init() {
        self.highest = START_MAX_VALUE
        self.score = 0
        self.health = MAX_HEALTH
        self.state = .check_collapse
        self.board = Array(map(1...SIZE) {_ in Array(map(1...SIZE) {_ in self.random_drop()})})

        while self.act() {}
        
        self.score = 0
    }

    func act() -> Bool {
        switch self.state {
        case .falling:
            fall()
        case .check_collapse:
            if !collapse_one() {
                state = .awaiting_action
            }
        case .awaiting_action:
            return false
        case .dead:
            return false
        }
        return true
    }
    
    func advance_tile(c:Coord) -> Bool {
        switch self.state {
        case .awaiting_action: break
        default: return false
        }
        self.board[c.row][c.col] += 1
        let collapse_set = self._get_matches_at(c)
        self.health -= 1
        if collapse_set.count < MINIMUM_COLLAPSE {
            self.highest = max(self.highest, self.board[c.row][c.col])
            if self.health == 0 {
                state = .dead
                score += board.reduce(0, combine: {(value, row) in row.reduce(value, combine: +)}) * 10
            }
            return true
        }

        collapse(collapse_set, coord: c)
        return true
    }

    private func random_drop() -> UInt32 {
        return arc4random_uniform(highest - 1) + 1
    }
    
    func _neighbors(c:Coord) -> [(Coord, UInt32)] {
        return filter([
            Coord(row:c.row - 1, col:c.col),
            Coord(row:c.row, col:c.col - 1),
            Coord(row:c.row + 1, col:c.col),
            Coord(row:c.row, col:c.col + 1),
            ], in_bounds).map({(c:Coord) -> (Coord, UInt32) in (c, self.board[c.row][c.col])})
    }

    private func collapse_one() -> Bool {
        let matches = self._find_matches()
        if matches == nil {return false}
        let (r_c, collapse_set) = matches!
        self.collapse(collapse_set, coord:r_c)
        return true
    }


    /// Find the first contiguous set of tiles whose values match in
    /// a sizeable group (as determined by MINIMUM_COLLAPSE) and return
    /// the coordinate to which they should collapse and their set.
    
    /// Search order is reading order: left to right, top to bottom.
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

    /// Get the contiguous set of tiles whose values match those at the
    /// given coordinate.
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
    
    private func collapse(collapse_set:Set<Coord>, coord:Coord) {
        let value = self.board[coord.row][coord.col]
        self.score += value * UInt32(collapse_set.count * 10)
        self.health = min(MAX_HEALTH, health + 1)

        for c in collapse_set {
            if c == coord {
                self.board[c.row][c.col] += 1
                self.highest = max(self.highest, self.board[c.row][c.col])
            }
            else {
                self.board[c.row][c.col] = 0
            }
        }
        self.state = .falling
    }

    private func fall() {
        // Settle all floating pieces
        for column in 0..<SIZE {
            var built_row = SIZE - 1
            var floating_row = SIZE - 1

            while floating_row >= 0 {
                if board[built_row][column] != 0 {
                    built_row -= 1
                    floating_row = min(floating_row, built_row)
                }
                else if board[floating_row][column] == 0 {
                    floating_row -= 1
                }
                else {
                    board[built_row][column] = board[floating_row][column]
                    board[floating_row][column] = 0
                }
            }
        }

        // Backfill empty spots
        for (r, row) in enumerate(board) {
            for (c, elem) in enumerate(row) {
                if elem == 0 {
                    board[r][c] = random_drop()
                }
            }
        }
        state = .check_collapse
    }
}

