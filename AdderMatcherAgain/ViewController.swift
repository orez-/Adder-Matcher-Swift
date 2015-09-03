//
//  ViewController.swift
//  AdderMatcher
//
//  Created by Brian Shaginaw on 9/1/15.
//  Copyright (c) 2015 Brian Shaginaw. All rights reserved.
//

import UIKit

let color_map:[(background:UIColor, text:UIColor)] = [
    (background:UIColor.redColor(), text:UIColor.whiteColor()),
    (background:UIColor.greenColor(), text:UIColor.blackColor()),
    (background:UIColor.yellowColor(), text:UIColor.blackColor()),
    (background:UIColor.blueColor(), text:UIColor.whiteColor()),
    (background:UIColor.magentaColor(), text:UIColor.whiteColor()),
    (background:UIColor.cyanColor(), text:UIColor.blackColor()),
    (background:UIColor.grayColor(), text:UIColor.blackColor())
]

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}


class ViewController: UIViewController {
    var game_state:Game!
    @IBOutlet var board_area:UIView!
    @IBOutlet var score_box:UITextField!
    @IBOutlet var health_boxes:[UIView]!
    private var buttons:[UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.game_state = Game()

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
        button.frame = CGRectMake(CGFloat(col * 60) + 10, CGFloat(row * 60) + 10, 50, 50)
        button.tag = row * SIZE + col
        button.titleLabel!.font = UIFont(name: "Helvetica-Bold", size: 20)
        button.addTarget(self, action: "advanceTile:", forControlEvents: UIControlEvents.TouchUpInside)
        updateButton(button, value:value)

        self.buttons.append(button)

        self.board_area.addSubview(button)
    }

    private func updateButton(button:UIButton, value:UInt32) {
        let button_colors:(background:UIColor, text:UIColor)
        if value == 0 {
            button_colors = (UIColor.whiteColor(), UIColor.whiteColor())
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

    private func dispatch_acting() {
        self.score_box.text = "Score: \(self.game_state.score)"
        updateHealthDisplay()
        for button in buttons {
            let coord2 = Coord(row: button.tag / SIZE, col: button.tag % SIZE)
            updateButton(button, value: self.game_state.board[coord2.row][coord2.col])
        }
        if game_state.act() {
            delay(0.5, dispatch_acting)
        }
    }

    @IBAction func advanceTile(sender:UIButton) {
        let coord = Coord(row: sender.tag / SIZE, col: sender.tag % SIZE)
        if self.game_state.advance_tile(coord) {
            dispatch_acting()
        }
    }
}
