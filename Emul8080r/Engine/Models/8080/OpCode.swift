import Foundation

enum OpCode: UInt8, CustomStringConvertible {
    case nop = 0x00
    case lxi_b_c = 0x01
    case inx_b_c = 0x03
    case inr_b = 0x04
    case dcr_b = 0x05
    case mvi_b = 0x06
    case rlc = 0x07
    case dad_b_c = 0x09
    case ldax_b_c = 0x0a
    case inr_c = 0x0c
    case dcr_c = 0x0d
    case mvi_c = 0x0e
    case rrc = 0x0f
    case lxi_d_e = 0x11
    case inx_d_e = 0x13
    case inr_d = 0x14
    case dcr_d = 0x15
    case mvi_d = 0x16
    case dad_d_e = 0x19
    case ldax_d_e = 0x1a
    case mvi_e = 0x1e
    case rar = 0x1f
    case lxi_h_l = 0x21
    case shld = 0x22
    case inx_h_l = 0x23
    case mvi_h = 0x26
    case daa = 0x27
    case dad_h_l = 0x29
    case lhld = 0x2a
    case dcx_h_l = 0x2b
    case inr_l = 0x2c
    case mvi_l = 0x2e
    case cma = 0x2f
    case lxi_sp = 0x31
    case sta = 0x32
    case inr_m = 0x34
    case dcr_m = 0x35
    case mvi_m = 0x36
    case stc = 0x37
    case lda = 0x3a
    case inr_a = 0x3c
    case dcr_a = 0x3d
    case mvi_a = 0x3e
    case mov_b_b = 0x40
    case mov_b_c = 0x41
    case mov_b_d = 0x42
    case mov_b_e = 0x43
    case mov_b_h = 0x44
    case mov_b_l = 0x45
    case mov_b_m = 0x46
    case mov_b_a = 0x47
    case mov_c_b = 0x48
    case mov_c_c = 0x49
    case mov_c_d = 0x4a
    case mov_c_e = 0x4b
    case mov_c_h = 0x4c
    case mov_c_l = 0x4d
    case mov_c_m = 0x4e
    case mov_c_a = 0x4f
    case mov_d_b = 0x50
    case mov_d_c = 0x51
    case mov_d_d = 0x52
    case mov_d_e = 0x53
    case mov_d_h = 0x54
    case mov_d_l = 0x55
    case mov_d_m = 0x56
    case mov_d_a = 0x57
    case mov_e_b = 0x58
    case mov_e_c = 0x59
    case mov_e_d = 0x5a
    case mov_e_e = 0x5b
    case mov_e_h = 0x5c
    case mov_e_l = 0x5d
    case mov_e_m = 0x5e
    case mov_e_a = 0x5f
    case mov_h_b = 0x60
    case mov_h_c = 0x61
    case mov_h_d = 0x62
    case mov_h_e = 0x63
    case mov_h_h = 0x64
    case mov_h_l = 0x65
    case mov_h_m = 0x66
    case mov_h_a = 0x67
    case mov_l_b = 0x68
    case mov_l_c = 0x69
    case mov_l_d = 0x6a
    case mov_l_e = 0x6b
    case mov_l_h = 0x6c
    case mov_l_l = 0x6d
    case mov_l_m = 0x6e
    case mov_l_a = 0x6f
    case mov_m_b = 0x70
    case mov_m_c = 0x71
    case mov_m_d = 0x72
    case mov_m_e = 0x73
    case mov_m_h = 0x74
    case mov_m_l = 0x75
    case mov_m_a = 0x77
    case mov_a_b = 0x78
    case mov_a_c = 0x79
    case mov_a_d = 0x7a
    case mov_a_e = 0x7b
    case mov_a_h = 0x7c
    case mov_a_l = 0x7d
    case mov_a_m = 0x7e
    case mov_a_a = 0x7f
    case add_b = 0x80
    case add_c = 0x81
    case add_d = 0x82
    case add_e = 0x83
    case add_h = 0x84
    case add_l = 0x85
    case add_m = 0x86
    case add_a = 0x87
    case sub_b = 0x90
    case sub_c = 0x91
    case sub_d = 0x92
    case sub_e = 0x93
    case sub_h = 0x94
    case sub_l = 0x95
    case sub_m = 0x96
    case sub_a = 0x97
    case ana_b = 0xa0
    case ana_c = 0xa1
    case ana_d = 0xa2
    case ana_e = 0xa3
    case ana_h = 0xa4
    case ana_l = 0xa5
    case ana_m = 0xa6
    case ana_a = 0xa7
    case xra_b = 0xa8
    case xra_a = 0xaf
    case ora_b = 0xb0
    case ora_c = 0xb1
    case ora_d = 0xb2
    case ora_e = 0xb3
    case ora_h = 0xb4
    case ora_l = 0xb5
    case ora_m = 0xb6
    case ora_a = 0xb7
    case cmp_b = 0xb8
    case cmp_c = 0xb9
    case cmp_d = 0xba
    case cmp_e = 0xbb
    case cmp_h = 0xbc
    case cmp_l = 0xbd
    case cmp_m = 0xbe
    case cmp_a = 0xbf
    case rnz = 0xc0
    case pop_b = 0xc1
    case jnz = 0xc2
    case jmp = 0xc3
    case cnz = 0xc4
    case push_b = 0xc5
    case adi = 0xc6
    case rz = 0xc8
    case ret = 0xc9
    case jz = 0xca
    case cz = 0xcc
    case call = 0xcd
    case rnc = 0xd0
    case pop_d = 0xd1
    case jnc = 0xd2
    case out = 0xd3
    case cnc = 0xd4
    case push_d = 0xd5
    case sui = 0xd6
    case rc = 0xd8
    case jc = 0xda
    case `in` = 0xdb
    case sbi = 0xde
    case rpo = 0xe0
    case pop_h = 0xe1
    case xthl = 0xe3
    case push_h = 0xe5
    case ani = 0xe6
    case rpe = 0xe8
    case pchl = 0xe9
    case xchg = 0xeb
    case rp = 0xf0
    case pop_psw = 0xf1
    case di = 0xf3
    case push_psw = 0xf5
    case ori = 0xf6
    case rm = 0xf8
    case jm = 0xfa
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
        case .nop, .inx_b_c, .inr_b, .dcr_b, .rlc, .dad_b_c, .ldax_b_c, .inr_c, .rar, .dcr_c, .rrc, .inx_d_e, .dad_d_e, .ldax_d_e, .inr_d, .dcr_d, .inx_h_l, .inr_m, .daa, .dcr_a, .dad_h_l, .dcx_h_l, .inr_l, .cma, .dcr_m, .inr_a, .stc, .mov_b_b, .mov_b_c, .mov_b_d, .mov_b_e, .mov_b_h, .mov_b_l, .mov_b_m, .mov_b_a, .mov_c_b, .mov_c_c, .mov_c_d, .mov_c_e, .mov_c_h, .mov_c_l, .mov_c_m, .mov_c_a, .mov_d_b, .mov_d_c, .mov_d_d, .mov_d_e, .mov_d_h, .mov_d_l, .mov_d_m, .mov_d_a, .mov_e_b, .mov_e_c, .mov_e_d, .mov_e_e, .mov_e_h, .mov_e_l, .mov_e_m, .mov_e_a, .mov_h_b, .mov_h_c, .mov_h_d, .mov_h_e, .mov_h_h, .mov_h_l, .mov_h_m, .mov_h_a, .mov_l_b, .mov_l_c, .mov_l_d, .mov_l_e, .mov_l_h, .mov_l_l, .mov_l_m, .mov_l_a, .mov_m_b, .mov_m_c, .mov_m_d, .mov_m_e, .mov_m_h, .mov_m_l, .mov_m_a, .mov_a_b, .mov_a_c, .mov_a_d, .mov_a_e, .mov_a_h, .mov_a_l, .mov_a_m, .mov_a_a, .add_b, .add_c, .add_d, .add_e, .add_h, .add_l, .add_m, .add_a, .sub_b, .sub_c, .sub_d, .sub_e, .sub_h, .sub_l, .sub_m, .sub_a, .ana_b, .ana_c, .ana_d, .ana_e, .ana_h, .ana_l, .ana_m, .ana_a, .xra_b, .xra_a, .ora_b, .ora_c, .ora_d, .ora_e, .ora_h, .ora_l, .ora_m, .ora_a, .cmp_b, .cmp_c, .cmp_d, .cmp_e, .cmp_h, .cmp_l, .cmp_m, .cmp_a, .rnz, .pop_b, .push_b, .rz, .ret, .pop_d, .push_d, .rc, .rp, .rpo, .rpe, .rm, .rnc, .pop_h, .xthl, .push_h, .pchl, .xchg, .pop_psw, .di, .push_psw, .ei:
            return 1
        case .mvi_b, .mvi_c, .mvi_d, .mvi_e, .mvi_h, .mvi_l, .mvi_m, .mvi_a, .sui, .adi, .out, .in, .sbi, .ani, .ori, .cpi:
            return 2
        case .lhld, .lxi_b_c, .lxi_d_e, .lxi_h_l, .lxi_sp, .shld, .lda, .sta, .jmp, .cnz, .jnz, .jz, .cz, .call, .jnc, .cnc, .jc, .jm:
            return 3
        }
    }

    var description: String {
        switch self {
        case .nop:
            return "NOP"
        case .lxi_b_c:
            return "LXI B C,#"
        case .inx_b_c:
            return "INX B C"
        case .inr_b:
            return "INR B"
        case .rlc:
            return "RLC"
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
        case .inr_c:
            return "INR C"
        case .rrc:
            return "RRC"
        case .lxi_d_e:
            return "LXI D E,#"
        case .inx_d_e:
            return "INX D E"
        case .inr_d:
            return "INR D"
        case .dcr_d:
            return "DCR D"
        case .mvi_d:
            return "MVI D,#"
        case .dad_d_e:
            return "DAD D E"
        case .ldax_d_e:
            return "LDAX D E"
        case .mvi_e:
            return "MVI E,#"
        case .rar:
            return "RAR"
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
        case .lhld:
            return "LHLD"
        case .dcx_h_l:
            return "DCX H L"
        case .inr_l:
            return "INR L"
        case .mvi_l:
            return "MVI L,#"
        case .cma:
            return "CMA"
        case .sta:
            return "STA"
        case .inr_m:
            return "INR M"
        case .dcr_m:
            return "DCR M"
        case .mvi_m:
            return "MVI M"
        case .stc:
            return "STC"
        case .lda:
            return "LDA"
        case .inr_a:
            return "INR A"
        case .dcr_a:
            return "DCR A"
        case .mvi_a:
            return "MVI A,#"
        case .mov_b_b:
            return "MOV B, B"
        case .mov_b_c:
            return "MOV B, C"
        case .mov_b_d:
            return "MOV B, D"
        case .mov_b_e:
            return "MOV B, E"
        case .mov_b_h:
            return "MOV B, H"
        case .mov_b_l:
            return "MOV B, L"
        case .mov_b_m:
            return "MOV B, M"
        case .mov_b_a:
            return "MOV B, A"
        case .mov_c_b:
            return "MOV C, B"
        case .mov_c_c:
            return "MOV C, C"
        case .mov_c_d:
            return "MOV C, D"
        case .mov_c_e:
            return "MOV C, E"
        case .mov_c_h:
            return "MOV C, H"
        case .mov_c_l:
            return "MOV C, L"
        case .mov_c_m:
            return "MOV C, M"
        case .mov_c_a:
            return "MOV C, A"
        case .mov_d_b:
            return "MOV D, B"
        case .mov_d_c:
            return "MOV D, C"
        case .mov_d_d:
            return "MOV D, D"
        case .mov_d_e:
            return "MOV D, E"
        case .mov_d_h:
            return "MOV D, H"
        case .mov_d_l:
            return "MOV D, L"
        case .mov_d_m:
            return "MOV D, M"
        case .mov_d_a:
            return "MOV D, A"
        case .mov_e_b:
            return "MOV E, B"
        case .mov_e_c:
            return "MOV E, C"
        case .mov_e_d:
            return "MOV E, D"
        case .mov_e_e:
            return "MOV E, E"
        case .mov_e_h:
            return "MOV E, H"
        case .mov_e_l:
            return "MOV E, L"
        case .mov_e_m:
            return "MOV E, M"
        case .mov_e_a:
            return "MOV E, A"
        case .mov_h_b:
            return "MOV H, B"
        case .mov_h_c:
            return "MOV H, C"
        case .mov_h_d:
            return "MOV H, D"
        case .mov_h_e:
            return "MOV H, E"
        case .mov_h_h:
            return "MOV H, H"
        case .mov_h_l:
            return "MOV H, L"
        case .mov_h_m:
            return "MOV H, M"
        case .mov_h_a:
            return "MOV H, A"
        case .mov_l_b:
            return "MOV L, B"
        case .mov_l_c:
            return "MOV L, C"
        case .mov_l_d:
            return "MOV L, D"
        case .mov_l_e:
            return "MOV L, E"
        case .mov_l_h:
            return "MOV L, H"
        case .mov_l_l:
            return "MOV L, L"
        case .mov_l_m:
            return "MOV L, M"
        case .mov_l_a:
            return "MOV L, A"
        case .mov_m_b:
            return "MOV M, B"
        case .mov_m_c:
            return "MOV M, C"
        case .mov_m_d:
            return "MOV M, D"
        case .mov_m_e:
            return "MOV M, E"
        case .mov_m_h:
            return "MOV M, H"
        case .mov_m_l:
            return "MOV M, L"
        case .mov_m_a:
            return "MOV M, A"
        case .mov_a_b:
            return "MOV A, B"
        case .mov_a_c:
            return "MOV A, C"
        case .mov_a_d:
            return "MOV A, D"
        case .mov_a_e:
            return "MOV A, E"
        case .mov_a_h:
            return "MOV A, H"
        case .mov_a_l:
            return "MOV A, L"
        case .mov_a_m:
            return "MOV A, M"
        case .mov_a_a:
            return "MOV A, A"
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
        case .sub_b:
            return "SUB B"
        case .sub_c:
            return "SUB C"
        case .sub_d:
            return "SUB D"
        case .sub_e:
            return "SUB E"
        case .sub_h:
            return "SUB H"
        case .sub_l:
            return "SUB L"
        case .sub_m:
            return "SUB M"
        case .sub_a:
            return "SUB A"
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
        case .xra_b:
            return "XRA B"
        case .xra_a:
            return "XRA A"
        case .ora_b:
            return "ORA B"
        case .ora_c:
            return "ORA C"
        case .ora_d:
            return "ORA D"
        case .ora_e:
            return "ORA E"
        case .ora_h:
            return "ORA H"
        case .ora_l:
            return "ORA L"
        case .ora_m:
            return "ORA M"
        case .ora_a:
            return "ORA A"
        case .cmp_b:
            return "CMP B"
        case .cmp_c:
            return "CMP C"
        case .cmp_d:
            return "CMP D"
        case .cmp_e:
            return "CMP E"
        case .cmp_h:
            return "CMP H"
        case .cmp_l:
            return "CMP L"
        case .cmp_m:
            return "CMP M"
        case .cmp_a:
            return "CMP A"
        case .rnz:
            return "RNZ"
        case .pop_b:
            return "POP B"
        case .jnz:
            return "JNZ"
        case .jmp:
            return "JMP"
        case .cnz:
            return "CNZ"
        case .adi:
            return "ADI #"
        case .rz:
            return "RET Z"
        case .ret:
            return "RET"
        case .jz:
            return "JZ"
        case .cz:
            return "CZ"
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
        case .cnc:
            return "CNC"
        case .push_d:
            return "PUSH D"
        case .sui:
            return "SUB #"
        case .rc:
            return "RET C"
        case .jc:
            return "JC"
        case .in:
            return "IN #"
        case .sbi:
            return "SUB #"
        case .pop_h:
            return "POP H"
        case .xthl:
            return "XTHL"
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
        case .ori:
            return "ORI #"
        case .rnc:
            return "RET NC"
        case .rpo:
            return "RET PO"
        case .rpe:
            return "RET PE"
        case .pchl:
            return "PCHL"
        case .rp:
            return "RET P"
        case .rm:
            return "RET M"
        case .jm:
            return "JMP M"
        case .ei:
            return "EI"
        case .cpi:
            return "CPI #"
        }
    }
}
