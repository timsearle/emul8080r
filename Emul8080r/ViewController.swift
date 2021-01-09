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

        self.spaceInvaders = InvaderMachine(rom: data, loggingEnabled: true)
        try! self.spaceInvaders.play()

        CADisplayLink(target: self, selector: #selector(self.loadVideo)).add(to: .main, forMode: .common)
    }

    @objc func loadVideo() {
        let copy = spaceInvaders.videoMemory
        var bits = [UInt8]()

        for byte in copy {
            bits.append(contentsOf: byte.bits)
        }

        let bitmap = Bitmap(width: 256, pixels: bits)
        imageView.image = UIImage(bitmap: bitmap)
    }

    //MARK: Machine controls
    @IBAction func leftDown(_ sender: Any) {
        spaceInvaders.fire(state: .down)
    }

    @IBAction func leftUp(_ sender: Any) {
        spaceInvaders.fire(state: .up)
    }

    @IBAction func rightDown(_ sender: Any) {
        spaceInvaders.right(state: .down)
    }

    @IBAction func rightUp(_ sender: Any) {
        spaceInvaders.right(state: .up)
    }

    @IBAction func fireDown(_ sender: Any) {
        spaceInvaders.fire(state: .down)
    }

    @IBAction func fireUp(_ sender: Any) {
        spaceInvaders.fire(state: .up)
    }

    @IBAction func coin(_ sender: Any) {
        spaceInvaders.coin()
    }
}

