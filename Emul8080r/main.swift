import Foundation

let romPath = CommandLine.arguments[1]
let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

let spaceInvaders = InvaderMachine(rom: data)
try spaceInvaders.play()
