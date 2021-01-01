import Foundation

let romPath = CommandLine.arguments[1]

let data = try! Data(contentsOf: URL(fileURLWithPath: romPath))

enum DisassemblerError: Error {
    case unknownCode(String)
}

func disassembleOpCode(from data: Data, offset: Int) throws -> Int {
    guard let code = OpCode(rawValue: data[offset]) else {
        throw DisassemblerError.unknownCode(String(format: "%02x", data[offset]))
    }

    var value = 1

    print(code, terminator: " ")

    var hex = ""

    while value < code.size {
        hex.insert(contentsOf: String(format: "%02x", data[offset + value]), at: hex.startIndex)
        value += 1
    }

    if !hex.isEmpty {
        hex.insert(contentsOf: "0x", at: hex.startIndex)
    }

    print(hex)

    return code.size
}

var offset = 0

while offset < data.count {
    do {
        offset += try disassembleOpCode(from: data, offset: offset)
    } catch {
        print(offset)
        throw error
    }
}
