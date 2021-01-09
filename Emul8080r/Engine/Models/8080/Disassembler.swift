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
                offset += try disassembleOpCode(offset: offset)
            } catch {
                print(offset)
                throw error
            }
        }
    }

    func disassembleOpCode(offset: Int) throws -> Int {
        guard let code = OpCode(rawValue: data[offset]) else {
            throw Error.unknownCode(String(format: "%02x %02x", offset, data[offset]))
        }

        var value = 1

        DispatchQueue.main.async {
            print("\(String(offset, radix: 16)) \(code)", terminator: " ")
        }

        var hex = ""

        while value < code.size {
            hex.insert(contentsOf: String(format: "%02x", data[offset + value]), at: hex.startIndex)
            value += 1
        }

        if !hex.isEmpty {
            hex.insert(contentsOf: "0x", at: hex.startIndex)
        }
        
        DispatchQueue.main.async {
            print(hex)
        }

        return code.size
    }
}
