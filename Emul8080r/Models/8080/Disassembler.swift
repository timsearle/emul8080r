import Foundation

struct Disassembler {
    enum Error: Swift.Error {
        case unknownCode(String)
    }

    let data: Data

    func run() throws {
        var offset = 0

        while offset < data.count {
            do {
                offset += try disassembleOpCode(from: data, offset: offset)
            } catch {
                print(offset)
                throw error
            }
        }
    }

    func disassembleOpCode(from data: Data, offset: Int) throws -> Int {
        guard let code = OpCode(rawValue: data[offset]) else {
            throw Error.unknownCode(String(format: "%02x", data[offset]))
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
}
