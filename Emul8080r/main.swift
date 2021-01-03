import Foundation

let romPath = CommandLine.arguments[1]

let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

let cpu = CPU()
cpu.load(data)
try cpu.start()
