import Foundation

enum OpCode: UInt8, CustomStringConvertible {
    case nop = 0x00
    case lxi_b_c = 0x01
    case dcr_b = 0x05
    case mvi_b = 0x06
    case dad_b_c = 0x09
    case ldax_b_c = 0x0a
    case dcr_c = 0x0d
    case mvi_c = 0x0e
    case rrc = 0x0f
    case lxi_d_e = 0x11
    case inx_d_e = 0x13
    case dad_d_e = 0x19
    case ldax_d_e = 0x1a
    case lxi_h_l = 0x21
    case shld = 0x22
    case inx_h_l = 0x23
    case mvi_h = 0x26
    case daa = 0x27
    case dad_h_l = 0x29
    case dcx_h_l = 0x2b
    case lxi_sp = 0x31
    case sta = 0x32
    case dcr_m = 0x35
    case mvi_m = 0x36
    case stc = 0x37
    case lda = 0x3a
    case dcr_a = 0x3d
    case mvi_a = 0x3e
    case mov_d_m = 0x56
    case mov_e_m = 0x5e
    case mov_h_m = 0x66
    case mov_l_a = 0x6f
    case mov_m_a = 0x77
    case mov_a_d = 0x7a
    case mov_a_e = 0x7b
    case mov_a_h = 0x7c
    case mov_a_m = 0x7e
    case add_b = 0x80
    case add_c = 0x81
    case add_d = 0x82
    case add_e = 0x83
    case add_h = 0x84
    case add_l = 0x85
    case add_m = 0x86
    case add_a = 0x87
    case ana_b = 0xa0
    case ana_c = 0xa1
    case ana_d = 0xa2
    case ana_e = 0xa3
    case ana_h = 0xa4
    case ana_l = 0xa5
    case ana_m = 0xa6
    case ana_a = 0xa7
    case xra_a = 0xaf
    case pop_b = 0xc1
    case jnz = 0xc2
    case jmp = 0xc3
    case push_b = 0xc5
    case adi = 0xc6
    case rz = 0xc8
    case ret = 0xc9
    case jz = 0xca
    case call = 0xcd
    case pop_d = 0xd1
    case jnc = 0xd2
    case out = 0xd3
    case push_d = 0xd5
    case jc = 0xda
    case `in` = 0xdb
    case pop_h = 0xe1
    case push_h = 0xe5
    case ani = 0xe6
    case xchg = 0xeb
    case pop_psw = 0xf1
    case di = 0xf3
    case push_psw = 0xf5
    case ei = 0xfb
    case cpi = 0xfe

    var cycleCount: Int {
        [
            4, 10, 7, 5, 5, 5, 7, 4, 4, 10, 7, 5, 5, 5, 7, 4,
            4, 10, 7, 5, 5, 5, 7, 4, 4, 10, 7, 5, 5, 5, 7, 4,
            4, 10, 16, 5, 5, 5, 7, 4, 4, 10, 16, 5, 5, 5, 7, 4,
            4, 10, 13, 5, 10, 10, 10, 4, 4, 10, 13, 5, 5, 5, 7, 4,

            5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
            5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
            5, 5, 5, 5, 5, 5, 7, 5, 5, 5, 5, 5, 5, 5, 7, 5,
            7, 7, 7, 7, 7, 7, 7, 7, 5, 5, 5, 5, 5, 5, 7, 5,

            4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
            4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
            4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,
            4, 4, 4, 4, 4, 4, 7, 4, 4, 4, 4, 4, 4, 4, 7, 4,

            11, 10, 10, 10, 17, 11, 7, 11, 11, 10, 10, 10, 10, 17, 7, 11,
            11, 10, 10, 10, 17, 11, 7, 11, 11, 10, 10, 10, 10, 17, 7, 11,
            11, 10, 10, 18, 17, 11, 7, 11, 11, 5, 10, 5, 17, 17, 7, 11,
            11, 10, 10, 4, 17, 11, 7, 11, 11, 5, 10, 4, 17, 17, 7, 11
        ][Int(rawValue)]
    }

    var size: Int {
        switch self {
        case .nop, .dcr_b, .dad_b_c, .ldax_b_c, .dcr_c, .rrc, .inx_d_e, .dad_d_e, .ldax_d_e, .inx_h_l, .daa, .dcr_a, .dad_h_l, .dcx_h_l, .dcr_m, .mov_d_m, .mov_e_m, .stc, .mov_h_m, .mov_l_a, .mov_m_a, .mov_a_d, .mov_a_e, .mov_a_h, .mov_a_m, .add_b, .add_c, .add_d, .add_e, .add_h, .add_l, .add_m, .add_a, .ana_b, .ana_c, .ana_d, .ana_e, .ana_h, .ana_l, .ana_m, .ana_a, .xra_a, .pop_b, .push_b, .rz, .ret, .pop_d, .push_d, .pop_h, .push_h, .xchg, .pop_psw, .di, .push_psw, .ei:
            return 1
        case .mvi_b, .mvi_c, .mvi_h, .mvi_m, .mvi_a, .adi, .out, .in, .ani, .cpi:
            return 2
        case .lxi_b_c, .lxi_d_e, .lxi_h_l, .lxi_sp, .shld, .lda, .sta, .jmp, .jnz, .jz, .call, .jnc, .jc:
            return 3
        }
    }

    var description: String {
        switch self {
        case .nop:
            return "NOP"
        case .lxi_b_c:
            return "LXI B C,#"
        case .dcr_b:
            return "DCR B"
        case .mvi_b:
            return "MVI B,#"
        case .dcr_c:
            return "DCR C"
        case .mvi_c:
            return "MVI C,#"
        case .dad_b_c:
            return "DAD B C"
        case .ldax_b_c:
            return "LDAX B C"
        case .rrc:
            return "RRC"
        case .lxi_d_e:
            return "LXI D E,#"
        case .inx_d_e:
            return "INX D E"
        case .dad_d_e:
            return "DAD D E"
        case .ldax_d_e:
            return "LDAX D E"
        case .lxi_h_l:
            return "LXI H L,#"
        case .lxi_sp:
            return "LXI SP,#"
        case .shld:
            return "SHLD"
        case .inx_h_l:
            return "INX H L"
        case .mvi_h:
            return "MVI H,#"
        case .daa:
            return "DAA"
        case .dad_h_l:
            return "DAD H L"
        case .dcx_h_l:
            return "DCX H L"
        case .sta:
            return "STA"
        case .dcr_m:
            return "DCR M"
        case .mvi_m:
            return "MVI M"
        case .stc:
            return "STC"
        case .lda:
            return "LDA"
        case .dcr_a:
            return "DCR A"
        case .mvi_a:
            return "MVI A,#"
        case .mov_d_m:
            return "MOV D, M"
        case .mov_e_m:
            return "MOV E, M"
        case .mov_h_m:
            return "MOV H, M"
        case .mov_l_a:
            return "MOV L, A"
        case .mov_m_a:
            return "MOV M, A"
        case .mov_a_d:
            return "MOV A, D"
        case .mov_a_e:
            return "MOV A, E"
        case .mov_a_h:
            return "MOV A, H"
        case .mov_a_m:
            return "MOV A, M"
        case .add_b:
            return "ADD B"
        case .add_c:
            return "ADD C"
        case .add_d:
            return "ADD D"
        case .add_e:
            return "ADD E"
        case .add_h:
            return "ADD H"
        case .add_l:
            return "ADD L"
        case .add_m:
            return "ADD M"
        case .add_a:
            return "ADD A"
        case .ana_b:
            return "ANA B"
        case .ana_c:
            return "ANA C"
        case .ana_d:
            return "ANA D"
        case .ana_e:
            return "ANA E"
        case .ana_h:
            return "ANA H"
        case .ana_l:
            return "ANA L"
        case .ana_m:
            return "ANA M"
        case .ana_a:
            return "ANA A"
        case .xra_a:
            return "XRA A"
        case .pop_b:
            return "POP B"
        case .jnz:
            return "JNZ"
        case .jmp:
            return "JMP"
        case .adi:
            return "ADI #"
        case .rz:
            return "RET Z"
        case .ret:
            return "RET"
        case .jz:
            return "JZ"
        case .call:
            return "CALL"
        case .push_b:
            return "PUSH B"
        case .pop_d:
            return "POP D"
        case .jnc:
            return "JNC"
        case .out:
            return "OUT"
        case .push_d:
            return "PUSH D"
        case .jc:
            return "JC"
        case .in:
            return "IN #"
        case .pop_h:
            return "POP H"
        case .push_h:
            return "PUSH H"
        case .ani:
            return "ANI"
        case .xchg:
            return "XCHG"
        case .pop_psw:
            return "POP PSW"
        case .di:
            return "DI"
        case .push_psw:
            return "PUSH PSW"
        case .ei:
            return "EI"
        case .cpi:
            return "CPI #"
        }
    }
}
