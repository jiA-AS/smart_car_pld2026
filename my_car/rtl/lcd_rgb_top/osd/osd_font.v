// ============================================================================
// osd_font.v —— OSD 字符点阵 ROM（unifont 点阵生成）
//   ch  : ASCII 码（8x16，占 bits[7:0]，bit7=最左像素）
//         8'h80~8'h8B = 编 码 器 陀 螺 仪 距 离 目 标 丢 失（16x16，bit15=最左）
//   row : 字内行号 0~15
// ============================================================================
module osd_font(
    input  wire [ 7:0] ch,
    input  wire [ 3:0] row,
    output reg  [15:0] bits
);
always @(*) begin
    case (ch)
        8'h30: begin  // 0
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0018;
                4'd5: bits = 16'h0024;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0046;
                4'd8: bits = 16'h004A;
                4'd9: bits = 16'h0052;
                4'd10: bits = 16'h0062;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0024;
                4'd13: bits = 16'h0018;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h31: begin  // 1
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0008;
                4'd5: bits = 16'h0018;
                4'd6: bits = 16'h0028;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h003E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h32: begin  // 2
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0002;
                4'd8: bits = 16'h000C;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0020;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h007E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h33: begin  // 3
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0002;
                4'd8: bits = 16'h001C;
                4'd9: bits = 16'h0002;
                4'd10: bits = 16'h0002;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h34: begin  // 4
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0004;
                4'd5: bits = 16'h000C;
                4'd6: bits = 16'h0014;
                4'd7: bits = 16'h0024;
                4'd8: bits = 16'h0044;
                4'd9: bits = 16'h0044;
                4'd10: bits = 16'h007E;
                4'd11: bits = 16'h0004;
                4'd12: bits = 16'h0004;
                4'd13: bits = 16'h0004;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h35: begin  // 5
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007E;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h0040;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0002;
                4'd10: bits = 16'h0002;
                4'd11: bits = 16'h0002;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h36: begin  // 6
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h001C;
                4'd5: bits = 16'h0020;
                4'd6: bits = 16'h0040;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h37: begin  // 7
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007E;
                4'd5: bits = 16'h0002;
                4'd6: bits = 16'h0002;
                4'd7: bits = 16'h0004;
                4'd8: bits = 16'h0004;
                4'd9: bits = 16'h0004;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h38: begin  // 8
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h003C;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h39: begin  // 9
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h003E;
                4'd9: bits = 16'h0002;
                4'd10: bits = 16'h0002;
                4'd11: bits = 16'h0002;
                4'd12: bits = 16'h0004;
                4'd13: bits = 16'h0038;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h41: begin  // A
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0018;
                4'd5: bits = 16'h0024;
                4'd6: bits = 16'h0024;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h007E;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h42: begin  // B
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h007C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h43: begin  // C
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h0040;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h44: begin  // D
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0078;
                4'd5: bits = 16'h0044;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0044;
                4'd13: bits = 16'h0078;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h45: begin  // E
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007E;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h0040;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h007E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h46: begin  // F
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007E;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h0040;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h0040;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h47: begin  // G
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h0040;
                4'd9: bits = 16'h004E;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h003A;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h48: begin  // H
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h007E;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h49: begin  // I
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003E;
                4'd5: bits = 16'h0008;
                4'd6: bits = 16'h0008;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h003E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4A: begin  // J
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h001F;
                4'd5: bits = 16'h0004;
                4'd6: bits = 16'h0004;
                4'd7: bits = 16'h0004;
                4'd8: bits = 16'h0004;
                4'd9: bits = 16'h0004;
                4'd10: bits = 16'h0004;
                4'd11: bits = 16'h0044;
                4'd12: bits = 16'h0044;
                4'd13: bits = 16'h0038;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4B: begin  // K
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0044;
                4'd6: bits = 16'h0048;
                4'd7: bits = 16'h0050;
                4'd8: bits = 16'h0060;
                4'd9: bits = 16'h0060;
                4'd10: bits = 16'h0050;
                4'd11: bits = 16'h0048;
                4'd12: bits = 16'h0044;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4C: begin  // L
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0040;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h0040;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h0040;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h007E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4D: begin  // M
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0066;
                4'd7: bits = 16'h0066;
                4'd8: bits = 16'h005A;
                4'd9: bits = 16'h005A;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4E: begin  // N
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0062;
                4'd6: bits = 16'h0062;
                4'd7: bits = 16'h0052;
                4'd8: bits = 16'h0052;
                4'd9: bits = 16'h004A;
                4'd10: bits = 16'h004A;
                4'd11: bits = 16'h0046;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h4F: begin  // O
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h50: begin  // P
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h0040;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h51: begin  // Q
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h005A;
                4'd12: bits = 16'h0066;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0003;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h52: begin  // R
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h007C;
                4'd9: bits = 16'h0048;
                4'd10: bits = 16'h0044;
                4'd11: bits = 16'h0044;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h53: begin  // S
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h003C;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0040;
                4'd8: bits = 16'h0030;
                4'd9: bits = 16'h000C;
                4'd10: bits = 16'h0002;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h54: begin  // T
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007F;
                4'd5: bits = 16'h0008;
                4'd6: bits = 16'h0008;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h55: begin  // U
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h56: begin  // V
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0041;
                4'd5: bits = 16'h0041;
                4'd6: bits = 16'h0041;
                4'd7: bits = 16'h0022;
                4'd8: bits = 16'h0022;
                4'd9: bits = 16'h0022;
                4'd10: bits = 16'h0014;
                4'd11: bits = 16'h0014;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h57: begin  // W
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h005A;
                4'd9: bits = 16'h005A;
                4'd10: bits = 16'h0066;
                4'd11: bits = 16'h0066;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h58: begin  // X
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0042;
                4'd5: bits = 16'h0042;
                4'd6: bits = 16'h0024;
                4'd7: bits = 16'h0024;
                4'd8: bits = 16'h0018;
                4'd9: bits = 16'h0018;
                4'd10: bits = 16'h0024;
                4'd11: bits = 16'h0024;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h59: begin  // Y
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0041;
                4'd5: bits = 16'h0041;
                4'd6: bits = 16'h0022;
                4'd7: bits = 16'h0022;
                4'd8: bits = 16'h0014;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h5A: begin  // Z
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h007E;
                4'd5: bits = 16'h0002;
                4'd6: bits = 16'h0002;
                4'd7: bits = 16'h0004;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0020;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h007E;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h3A: begin  // :
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0018;
                4'd7: bits = 16'h0018;
                4'd8: bits = 16'h0000;
                4'd9: bits = 16'h0000;
                4'd10: bits = 16'h0000;
                4'd11: bits = 16'h0018;
                4'd12: bits = 16'h0018;
                4'd13: bits = 16'h0000;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h2C: begin  // ,
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0000;
                4'd7: bits = 16'h0000;
                4'd8: bits = 16'h0000;
                4'd9: bits = 16'h0000;
                4'd10: bits = 16'h0000;
                4'd11: bits = 16'h0000;
                4'd12: bits = 16'h0018;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0008;
                4'd15: bits = 16'h0010;
                default: bits = 16'h0000;
            endcase
        end
        8'h2E: begin  // .
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0000;
                4'd7: bits = 16'h0000;
                4'd8: bits = 16'h0000;
                4'd9: bits = 16'h0000;
                4'd10: bits = 16'h0000;
                4'd11: bits = 16'h0000;
                4'd12: bits = 16'h0018;
                4'd13: bits = 16'h0018;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h2D: begin  // -
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0000;
                4'd7: bits = 16'h0000;
                4'd8: bits = 16'h0000;
                4'd9: bits = 16'h003C;
                4'd10: bits = 16'h0000;
                4'd11: bits = 16'h0000;
                4'd12: bits = 16'h0000;
                4'd13: bits = 16'h0000;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h28: begin  // (
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0004;
                4'd4: bits = 16'h0008;
                4'd5: bits = 16'h0008;
                4'd6: bits = 16'h0010;
                4'd7: bits = 16'h0010;
                4'd8: bits = 16'h0010;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0010;
                4'd11: bits = 16'h0010;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0008;
                4'd14: bits = 16'h0004;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h29: begin  // )
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0020;
                4'd4: bits = 16'h0010;
                4'd5: bits = 16'h0010;
                4'd6: bits = 16'h0008;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0010;
                4'd13: bits = 16'h0010;
                4'd14: bits = 16'h0020;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h2F: begin  // /
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0002;
                4'd5: bits = 16'h0002;
                4'd6: bits = 16'h0004;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0010;
                4'd11: bits = 16'h0020;
                4'd12: bits = 16'h0040;
                4'd13: bits = 16'h0040;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h20: begin  // space
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0000;
                4'd7: bits = 16'h0000;
                4'd8: bits = 16'h0000;
                4'd9: bits = 16'h0000;
                4'd10: bits = 16'h0000;
                4'd11: bits = 16'h0000;
                4'd12: bits = 16'h0000;
                4'd13: bits = 16'h0000;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h80: begin  // CJK '编'
            case (row)
                4'd0: bits = 16'h1080;
                4'd1: bits = 16'h1040;
                4'd2: bits = 16'h23FC;
                4'd3: bits = 16'h2204;
                4'd4: bits = 16'h4A04;
                4'd5: bits = 16'hFBFC;
                4'd6: bits = 16'h1200;
                4'd7: bits = 16'h2200;
                4'd8: bits = 16'h43FC;
                4'd9: bits = 16'hFB54;
                4'd10: bits = 16'h4354;
                4'd11: bits = 16'h05FC;
                4'd12: bits = 16'h1D54;
                4'd13: bits = 16'hE554;
                4'd14: bits = 16'h4944;
                4'd15: bits = 16'h010C;
                default: bits = 16'h0000;
            endcase
        end
        8'h81: begin  // CJK '码'
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h01F8;
                4'd2: bits = 16'hFC08;
                4'd3: bits = 16'h1008;
                4'd4: bits = 16'h1088;
                4'd5: bits = 16'h2088;
                4'd6: bits = 16'h3C88;
                4'd7: bits = 16'h64FE;
                4'd8: bits = 16'h6402;
                4'd9: bits = 16'hA402;
                4'd10: bits = 16'h2402;
                4'd11: bits = 16'h25FA;
                4'd12: bits = 16'h3C02;
                4'd13: bits = 16'h2402;
                4'd14: bits = 16'h2014;
                4'd15: bits = 16'h0008;
                default: bits = 16'h0000;
            endcase
        end
        8'h82: begin  // CJK '器'
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h3E7C;
                4'd2: bits = 16'h2244;
                4'd3: bits = 16'h2244;
                4'd4: bits = 16'h3E7C;
                4'd5: bits = 16'h0120;
                4'd6: bits = 16'h0110;
                4'd7: bits = 16'hFFFE;
                4'd8: bits = 16'h0280;
                4'd9: bits = 16'h0C60;
                4'd10: bits = 16'h3018;
                4'd11: bits = 16'hC006;
                4'd12: bits = 16'h3E7C;
                4'd13: bits = 16'h2244;
                4'd14: bits = 16'h2244;
                4'd15: bits = 16'h3E7C;
                default: bits = 16'h0000;
            endcase
        end
        8'h83: begin  // CJK '陀'
            case (row)
                4'd0: bits = 16'h0040;
                4'd1: bits = 16'h7C20;
                4'd2: bits = 16'h4420;
                4'd3: bits = 16'h49FE;
                4'd4: bits = 16'h4902;
                4'd5: bits = 16'h5204;
                4'd6: bits = 16'h4900;
                4'd7: bits = 16'h4908;
                4'd8: bits = 16'h4510;
                4'd9: bits = 16'h4520;
                4'd10: bits = 16'h45C0;
                4'd11: bits = 16'h6904;
                4'd12: bits = 16'h5104;
                4'd13: bits = 16'h4104;
                4'd14: bits = 16'h40FC;
                4'd15: bits = 16'h4000;
                default: bits = 16'h0000;
            endcase
        end
        8'h84: begin  // CJK '螺'
            case (row)
                4'd0: bits = 16'h1000;
                4'd1: bits = 16'h11FC;
                4'd2: bits = 16'h1124;
                4'd3: bits = 16'h7DFC;
                4'd4: bits = 16'h5524;
                4'd5: bits = 16'h55FC;
                4'd6: bits = 16'h5440;
                4'd7: bits = 16'h5488;
                4'd8: bits = 16'h7DF0;
                4'd9: bits = 16'h5020;
                4'd10: bits = 16'h1044;
                4'd11: bits = 16'h17FE;
                4'd12: bits = 16'h1C22;
                4'd13: bits = 16'hE524;
                4'd14: bits = 16'h4222;
                4'd15: bits = 16'h0060;
                default: bits = 16'h0000;
            endcase
        end
        8'h85: begin  // CJK '仪'
            case (row)
                4'd0: bits = 16'h0880;
                4'd1: bits = 16'h0848;
                4'd2: bits = 16'h0A48;
                4'd3: bits = 16'h1208;
                4'd4: bits = 16'h1208;
                4'd5: bits = 16'h3110;
                4'd6: bits = 16'h3110;
                4'd7: bits = 16'h5110;
                4'd8: bits = 16'h90A0;
                4'd9: bits = 16'h10A0;
                4'd10: bits = 16'h1040;
                4'd11: bits = 16'h1040;
                4'd12: bits = 16'h10A0;
                4'd13: bits = 16'h1110;
                4'd14: bits = 16'h1208;
                4'd15: bits = 16'h1406;
                default: bits = 16'h0000;
            endcase
        end
        8'h86: begin  // CJK '距'
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h7DFE;
                4'd2: bits = 16'h4500;
                4'd3: bits = 16'h4500;
                4'd4: bits = 16'h4500;
                4'd5: bits = 16'h7DFC;
                4'd6: bits = 16'h1104;
                4'd7: bits = 16'h1104;
                4'd8: bits = 16'h5D04;
                4'd9: bits = 16'h5104;
                4'd10: bits = 16'h51FC;
                4'd11: bits = 16'h5100;
                4'd12: bits = 16'h5D00;
                4'd13: bits = 16'hE100;
                4'd14: bits = 16'h01FE;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h87: begin  // CJK '离'
            case (row)
                4'd0: bits = 16'h0200;
                4'd1: bits = 16'h0100;
                4'd2: bits = 16'hFFFE;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h1450;
                4'd5: bits = 16'h1390;
                4'd6: bits = 16'h1450;
                4'd7: bits = 16'h1FF0;
                4'd8: bits = 16'h0100;
                4'd9: bits = 16'h7FFC;
                4'd10: bits = 16'h4204;
                4'd11: bits = 16'h4444;
                4'd12: bits = 16'h4FE4;
                4'd13: bits = 16'h4424;
                4'd14: bits = 16'h4014;
                4'd15: bits = 16'h4008;
                default: bits = 16'h0000;
            endcase
        end
        8'h88: begin  // CJK '目'
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h3FF8;
                4'd2: bits = 16'h2008;
                4'd3: bits = 16'h2008;
                4'd4: bits = 16'h2008;
                4'd5: bits = 16'h3FF8;
                4'd6: bits = 16'h2008;
                4'd7: bits = 16'h2008;
                4'd8: bits = 16'h2008;
                4'd9: bits = 16'h3FF8;
                4'd10: bits = 16'h2008;
                4'd11: bits = 16'h2008;
                4'd12: bits = 16'h2008;
                4'd13: bits = 16'h2008;
                4'd14: bits = 16'h3FF8;
                4'd15: bits = 16'h2008;
                default: bits = 16'h0000;
            endcase
        end
        8'h89: begin  // CJK '标'
            case (row)
                4'd0: bits = 16'h1000;
                4'd1: bits = 16'h11FC;
                4'd2: bits = 16'h1000;
                4'd3: bits = 16'h1000;
                4'd4: bits = 16'hFC00;
                4'd5: bits = 16'h13FE;
                4'd6: bits = 16'h3020;
                4'd7: bits = 16'h3820;
                4'd8: bits = 16'h5528;
                4'd9: bits = 16'h5524;
                4'd10: bits = 16'h9224;
                4'd11: bits = 16'h1222;
                4'd12: bits = 16'h1422;
                4'd13: bits = 16'h1020;
                4'd14: bits = 16'h10A0;
                4'd15: bits = 16'h1040;
                default: bits = 16'h0000;
            endcase
        end
        8'h8A: begin  // CJK '丢'
            case (row)
                4'd0: bits = 16'h0010;
                4'd1: bits = 16'h00F8;
                4'd2: bits = 16'h3F00;
                4'd3: bits = 16'h0100;
                4'd4: bits = 16'h0100;
                4'd5: bits = 16'h3FF8;
                4'd6: bits = 16'h0100;
                4'd7: bits = 16'h0100;
                4'd8: bits = 16'h0100;
                4'd9: bits = 16'hFFFE;
                4'd10: bits = 16'h0200;
                4'd11: bits = 16'h0400;
                4'd12: bits = 16'h0820;
                4'd13: bits = 16'h1010;
                4'd14: bits = 16'h3FF8;
                4'd15: bits = 16'h1008;
                default: bits = 16'h0000;
            endcase
        end
        8'h8B: begin  // CJK '失'
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h1100;
                4'd2: bits = 16'h1100;
                4'd3: bits = 16'h1100;
                4'd4: bits = 16'h1FF8;
                4'd5: bits = 16'h2100;
                4'd6: bits = 16'h4100;
                4'd7: bits = 16'h0100;
                4'd8: bits = 16'hFFFE;
                4'd9: bits = 16'h0100;
                4'd10: bits = 16'h0280;
                4'd11: bits = 16'h0280;
                4'd12: bits = 16'h0440;
                4'd13: bits = 16'h0820;
                4'd14: bits = 16'h1010;
                4'd15: bits = 16'h600C;
                default: bits = 16'h0000;
            endcase
        end
        default: bits = 16'h0000;
    endcase
end
endmodule
