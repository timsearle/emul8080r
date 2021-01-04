//
//  ViewController.swift
//  Emul8080r
//
//  Created by Tim on 04/01/2021.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .black
            imageView.layer.magnificationFilter = .nearest
        }
    }

    private var spaceInvaders: InvaderMachine!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let romPath = CommandLine.arguments[1]
        let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

        spaceInvaders = InvaderMachine(rom: data, loggingEnabled: true)

        CADisplayLink(target: self, selector: #selector(self.loadVideo)).add(to: .main, forMode: .default)
        
        try! self.spaceInvaders.play()
    }

    @objc func loadVideo() {
        let copy = Bitmap(width: 256, pixels: spaceInvaders.videoMemory.map { $0 == 0 ? 0x00 : 0xff })
        imageView.image = UIImage(bitmap: copy)
    }
}

