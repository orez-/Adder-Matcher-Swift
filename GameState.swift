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


protocol GameObserver {
    func on_collapse(collapse_set:Set<Coord>, coord:Coord)
    func on_fall([(src:Coord, dest:Coord)])
}


class Game {
    var board:[[UInt32]]!
    private var highest:UInt32
    var score:UInt32
    var state:GameState
    var health:Int
    var observers:Array<GameObserver>
    var first_collapse:Coord?

    init() {
        self.highest = START_MAX_VALUE
        self.score = 0
        self.health = MAX_HEALTH
        self.state = .check_collapse
        self.observers = Array()
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
                if self.health == 0 {
                    state = .dead
                    score += board.reduce(0, combine: {(value, row) in row.reduce(value, combine: +)}) * 10
                } else {
                    state = .awaiting_action
                }
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
        self.health -= 1
        first_collapse = c
        state = .check_collapse
        return true
    }

    private func random_drop() -> UInt32 {
        return arc4random_uniform(highest - 1) + 1
    }
    
    private func neighbors(c:Coord) -> [(Coord, UInt32)] {
        return filter([
            Coord(row:c.row - 1, col:c.col),
            Coord(row:c.row, col:c.col - 1),
            Coord(row:c.row + 1, col:c.col),
            Coord(row:c.row, col:c.col + 1),
            ], in_bounds).map({(c:Coord) -> (Coord, UInt32) in (c, self.board[c.row][c.col])})
    }

    private func collapse_one() -> Bool {
        let r_c:Coord
        let collapse_set:Set<Coord>
        if first_collapse == nil {
            let matches = self.find_matches()
            if matches == nil {return false}
            (r_c, collapse_set) = matches!
        }
        else {
            r_c = first_collapse!
            first_collapse = nil
            let matches = self.get_matches_at(r_c)
            if matches.count < MINIMUM_COLLAPSE {return false}
            collapse_set = matches
        }
        self.collapse(collapse_set, coord:r_c)
        return true
    }

    /// Find the first contiguous set of tiles whose values match in
    /// a sizeable group (as determined by MINIMUM_COLLAPSE) and return
    /// the coordinate to which they should collapse and their set.
    
    /// Search order is reading order: left to right, top to bottom.
    private func find_matches() -> (Coord, Set<Coord>)? {
        var seen_set:Set<Coord> = Set()
        for (r, row) in enumerate(self.board) {
            for (c, number) in enumerate(row) {
                let r_c = Coord(row:r, col:c)
                if seen_set.contains(r_c) {continue}
                let collapse_set = self.get_matches_at(r_c)
                if collapse_set.count >= MINIMUM_COLLAPSE {return (r_c, collapse_set)}
                seen_set.unionInPlace(collapse_set)
            }
        }
        return nil
    }

    /// Get the contiguous set of tiles whose values match those at the
    /// given coordinate.
    private func get_matches_at(coord:Coord) -> Set<Coord> {
        let num = self.board[coord.row][coord.col]
        var collapse_set:Set<Coord> = Set()
        // Swift doesn't have native queues, maybe I'll build my own
        // later, but for now this list will have to do.
        var queue = [coord]
        while !queue.isEmpty {
            let r_c = queue.removeAtIndex(0)  // *wince*
            for (coord, elem) in self.neighbors(r_c) {
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

        for observer in observers {
            observer.on_collapse(collapse_set, coord:coord)
        }

        self.state = .falling
    }

    private func fall() {
        var fall_map:[(src:Coord, dest:Coord)] = []
        var column_holes = map(0..<SIZE, {_ in 0})

        // Settle all floating pieces
        for column in 0..<SIZE {
            var built_row = SIZE - 1
            var floating_row = SIZE - 1

            while floating_row >= 0 {
                if board[built_row][column] != 0 {
                    // Find the first empty row from the bottom
                    built_row -= 1
                    floating_row = min(floating_row, built_row)
                }
                else if board[floating_row][column] == 0 {
                    // Find the first floating block above the empty row
                    floating_row -= 1
                }
                else {
                    // Swap the two
                    fall_map.append(
                        src:Coord(row:floating_row, col:column),
                        dest:Coord(row:built_row, col:column)
                    )
                    board[built_row][column] = board[floating_row][column]
                    board[floating_row][column] = 0
                }
            }
            column_holes[column] = floating_row - built_row
        }

        // Backfill empty spots
        for (r, row) in enumerate(board) {
            for (c, elem) in enumerate(row) {
                if elem == 0 {
                    fall_map.append(
                        src:Coord(row:column_holes[c], col:c),
                        dest:Coord(row:r, col:c)
                    )
                    column_holes[c] += 1
                    assert(column_holes[c] <= 0, "\(column_holes[c])")
                    board[r][c] = random_drop()
                }
            }
        }

        for observer in observers {
            observer.on_fall(fall_map)
        }

        state = .check_collapse
    }
}
