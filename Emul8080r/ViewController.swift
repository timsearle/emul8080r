import UIKit

class ViewController: UIViewController {
    @IBOutlet var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .red
            imageView.layer.magnificationFilter = .nearest
            imageView.transform = CGAffineTransform(rotationAngle: 3 * .pi/2)
        }
    }

    private var spaceInvaders: InvaderMachine!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let romPath = CommandLine.arguments[1]
        let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

        spaceInvaders = InvaderMachine(rom: data, loggingEnabled: false)

        CADisplayLink(target: self, selector: #selector(self.loadVideo)).add(to: .main, forMode: .common)
        
        try! self.spaceInvaders.play()
    }

    @objc func loadVideo() {
        let copy = spaceInvaders.videoMemory.map { $0.bits }.flatMap { $0 }
        let bitmap = Bitmap(width: 256, pixels: copy.map { $0 == .zero ? 0x00 : 0xff })
        imageView.image = UIImage(bitmap: bitmap)
    }
}

