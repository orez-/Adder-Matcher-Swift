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
    (background:UIColor.blueColor(), text:UIColor.blackColor()),
    (background:UIColor.purpleColor(), text:UIColor.blackColor()),
    (background:UIColor.cyanColor(), text:UIColor.blackColor()),
    (background:UIColor.whiteColor(), text:UIColor.blackColor())
]


class ViewController: UIViewController {
//    @IBOutlet var num:UIButton!
//    @IBOutlet var buttons:[UIButton]!
//        var labels:[UILabel]()
    var game_state:GameState!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.game_state = GameState()

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
        button.frame = CGRectMake(CGFloat(col * 60) + 50, CGFloat(row * 60) + 80, 50, 50)
        let button_colors = color_map[(Int(value) - 1) % color_map.count]
        button.backgroundColor = button_colors.background
        button.setTitle("\(value)", forState: UIControlState.Normal)
        button.titleLabel!.font = UIFont(name: "Helvetica-Bold", size: 20)
        button.setTitleColor(button_colors.text, forState: UIControlState.Normal)
        button.tag = row * SIZE + col
        button.addTarget(self, action: "advanceTile:", forControlEvents: UIControlEvents.TouchUpInside)

        self.view.addSubview(button)
    }

    @IBAction func advanceTile(sender:UIButton) {
        let coord = Coord(row: sender.tag / SIZE, col: sender.tag % SIZE)
        println(coord)
    }
}
