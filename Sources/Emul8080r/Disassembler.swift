struct Disassembler {
    enum Error: Swift.Error {
        case unknownCode(String)
    }

    let data: [UInt8]

    func run() throws {
        var offset = 0

        while offset < data.count {
            do {
                offset += try disassembleOpCode(offset: offset)
            } catch {
                throw error
            }
        }
    }

    func disassembleOpCode(offset: Int) throws -> Int {
        guard let code = OpCode(rawValue: data[offset]) else {
            throw Error.unknownCode("PC: \(String(offset, radix: 16)): \(String(data[offset], radix: 16))")
        }

        var value = 1

        print("0x\(String(offset, radix: 16)) \(code)", terminator: " ")

        var hex = ""

        while value < code.size {
            hex.insert(contentsOf: String(data[offset + value], radix: 16), at: hex.startIndex)
            value += 1
        }

        if !hex.isEmpty {
            hex.insert(contentsOf: "0x", at: hex.startIndex)
        }

        print(hex)

        return code.size
    }
}
