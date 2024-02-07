//
//  File.swift
//  
//
//  Created by C3924521_Tim_Searle on 12/06/2021.
//

import XCTest
@testable import Emul8080r

final class AssemblerTests: XCTestCase {
    func testBasicAssembler() throws {
        let program = """
        MOV A,B ; a comment to be ignored
        MOV B,D
        ;ADD A,34D
        ;JMP $0000
        """

        let assembler = Assembler()
        let data = try assembler.assemble(program: program)

        let expectedData = Data([0x78, 0x42])

        XCTAssertEqual(data, expectedData)
    }
}
