//
//  ViewController.swift
//  AdderMatcher
//
//  Created by Brian Shaginaw on 9/1/15.
//  Copyright (c) 2015 Brian Shaginaw. All rights reserved.
//

import UIKit

let color_map:[(background:UIColor, text:UIColor)] = [
    (background:UIColor.redColor(), text:UIColor.lightTextColor()),
    (background:UIColor.greenColor(), text:UIColor.darkTextColor()),
    (background:UIColor.yellowColor(), text:UIColor.darkTextColor()),
    (background:UIColor.blueColor(), text:UIColor.lightTextColor()),
    (background:UIColor.magentaColor(), text:UIColor.lightTextColor()),
    (background:UIColor.cyanColor(), text:UIColor.darkTextColor()),
    (background:UIColor.grayColor(), text:UIColor.darkTextColor()),
    (background:UIColor.brownColor(), text:UIColor.lightTextColor()),
    (background:UIColor.orangeColor(), text:UIColor.darkTextColor())
]

let DELAY:Double = 0.33

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

private func tag_to_coord(tag:Int) -> Coord {
    return Coord(row: tag / SIZE, col: tag % SIZE)
}

private func coord_to_tag(coord:Coord) -> Int {
    return coord.row * SIZE + coord.col
}


class ViewController: UIViewController, GameObserver {
    var game_state:Game!
    @IBOutlet var board_area:UIView!
    @IBOutlet var score_box:UITextField!
    @IBOutlet var health_boxes:[UIView]!
    private var buttons = [Int: UIButton]()
    private var button_pool = Set<UIButton>()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.game_state = Game()
        game_state.observers.append(self)

        updateHealthDisplay()
        for (r, row) in enumerate(self.game_state.board) {
            for (c, elem) in enumerate(row) {
                addButton(elem, row:r, col:c)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func addButton(value:UInt32, row:Int, col:Int) {
        let button = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        button.frame = CGRectMake(CGFloat(col * 60) + 10, CGFloat((row - SIZE) * 60) + 10, 50, 50)
        let delay_ = Double(col) * Double(SIZE - row) / (Double(SIZE) * Double(SIZE)) * DELAY
        UIView.animateWithDuration(DELAY,
            delay: delay_,
            options: .CurveEaseIn,
            animations: {
                button.frame.origin.x = CGFloat(col * 60 + 10)
                button.frame.origin.y = CGFloat(row * 60 + 10)
            },
            completion: nil
        )
        button.tag = row * SIZE + col
        button.titleLabel!.font = UIFont(name: "Helvetica-Bold", size: 20)
        button.addTarget(self, action: "advanceTile:", forControlEvents: UIControlEvents.TouchUpInside)
        updateButton(button, value:value)

        self.buttons[button.tag] = button

        self.board_area.addSubview(button)
    }

    private func updateButton(button:UIButton, value:UInt32) {
        let button_colors:(background:UIColor, text:UIColor)
        if value == 0 {
            return
        }
        else {
            button_colors = color_map[(Int(value) - 1) % color_map.count]
        }
        button.backgroundColor = button_colors.background
        button.setTitle("\(value)", forState: UIControlState.Normal)
        button.setTitleColor(button_colors.text, forState: UIControlState.Normal)
    }

    private func updateHealthDisplay() {
        let healthColor:UIColor
        switch(game_state.health) {
        case 1: healthColor = UIColor.redColor()
        case 5: healthColor = UIColor.greenColor()
        default: healthColor = UIColor.yellowColor()
        }

        for (i, box) in enumerate(health_boxes) {
            if i < game_state.health {
                box.backgroundColor = healthColor
            }
            else {
                box.backgroundColor = UIColor(white: 1, alpha: 0)
            }
        }
    }

    private func updateScoreDisplay() {
        // TODO: animation
        var formatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        let score = formatter.stringFromNumber(Int(self.game_state.score))!
        self.score_box.text = "Score: \(score)"
    }

    func on_collapse(collapsed: Set<Coord>, coord: Coord) {
        let collapse_button = buttons[coord_to_tag(coord)]!
        let dest_x = collapse_button.frame.origin.x
        let dest_y = collapse_button.frame.origin.y
        for button_coord in collapsed {
            if button_coord == coord {
                continue
            }
            let button = buttons[coord_to_tag(button_coord)]!
            let start_x = button.frame.origin.x
            let start_y = button.frame.origin.y
            board_area.bringSubviewToFront(button)

            UIView.animateWithDuration(DELAY, animations: {
                button.frame.origin.x = dest_x
                button.frame.origin.y = dest_y
            })

            button_pool.insert(button)
        }
        board_area.bringSubviewToFront(collapse_button)
    }

    func on_fall(falling_pts:[(src:Coord, dest:Coord)]) {
        // It would be Very Bad to update the lookups on the buttons
        // while retagging them, so we track them here and wait until
        // after to do so.
        var buttons_to_update = Set<UIButton>()
        for (src, dest) in falling_pts {
            let button:UIButton
            if src.row < 0 {
                // Offscreen buttons, pull from pool
                button = button_pool.removeFirst()
                updateButton(button, value: self.game_state.board[dest.row][dest.col])
                button.frame.origin.x = CGFloat(src.col * 60 + 10)
                button.frame.origin.y = CGFloat(src.row * 60 + 10)
            }
            else {
                // Onscreen buttons, find the correct one
                button = buttons[coord_to_tag(src)]!
            }
            buttons_to_update.insert(button)
            UIView.animateWithDuration(DELAY, animations: {
                button.tag = coord_to_tag(dest)
                button.frame.origin.x = CGFloat(dest.col * 60 + 10)
                button.frame.origin.y = CGFloat(dest.row * 60 + 10)
            })
        }
        for button in buttons_to_update {
            buttons[button.tag] = button
        }

        assert(filter(buttons) {
            key, value in
            key != value.tag
        }.isEmpty)
    }

    private func dispatch_acting() {
        updateScoreDisplay()
        for (id, button) in buttons {
            let coord2 = tag_to_coord(button.tag)
            updateButton(button, value: self.game_state.board[coord2.row][coord2.col])
        }
        if game_state.act() {
            updateHealthDisplay()
            delay(DELAY, dispatch_acting)
        }
    }

    @IBAction func advanceTile(sender:UIButton) {
        let coord = tag_to_coord(sender.tag)
        if self.game_state.advance_tile(coord) {
            updateButton(buttons[coord_to_tag(coord)]!, value:game_state.board[coord.row][coord.col])
            dispatch_acting()
        }
    }

    @IBAction func restart(sender:UIButton) {
        // TODO: ensure the buttons are all assigned correctly when you tap this
        game_state = Game()
        game_state.observers.append(self)
        updateScoreDisplay()
        updateHealthDisplay()
        for (tag, button) in buttons {
            let coord = tag_to_coord(tag)
            let delay_ = Double(coord.col) * Double(SIZE - coord.row) / (Double(SIZE) * Double(SIZE)) * DELAY

            UIView.animateWithDuration(DELAY,
                delay: delay_,
                options: .CurveEaseIn,
                animations: {
                    button.frame.origin.x = CGFloat(coord.col * 60 + 10)
                    button.frame.origin.y = CGFloat((coord.row + SIZE) * 60 + 10)
                },
                completion: {_ in
                    self.updateButton(button, value: self.game_state.board[coord.row][coord.col])
                    button.frame.origin.x = CGFloat(coord.col * 60 + 10)
                    button.frame.origin.y = CGFloat((coord.row - SIZE) * 60 + 10)
                    UIView.animateWithDuration(DELAY, animations: {
                        button.frame.origin.x = CGFloat(coord.col * 60 + 10)
                        button.frame.origin.y = CGFloat(coord.row * 60 + 10)
                    })
                }
            )
        }
    }
}
