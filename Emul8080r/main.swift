import Foundation

let romPath = CommandLine.arguments[1]

let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

let cpu = CPU(memory: [UInt8](repeating: 0, count: 65536))
cpu.load(data)
try cpu.start()
