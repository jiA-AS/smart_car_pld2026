// ============================================================================
// osd_font.v -- OSD ×Ö·ûµãÕó ROM£¨unifont µãÕóÉú³É£¬V3£©
//   ch  : ASCII Âë£¨8x16£¬Õ¼ bits[7:0]£¬bit7=×î×óÏñËØ£©
//   8'h80~8'hA2 ÖĞÎÄ£¨16x16£¬bit15=×î×óÏñËØ£©£º
//   80±à 81Âë 82Æ÷ 83ÍÓ 84Âİ 85ÒÇ 86¾à 87Àë 88Ä¿ 89±ê 8A¶ª 8BÊ§
//   8CÎ´ 8DÊ¶ 8E±ğ 8Fµ¥ 90¸ú 91×Ù 92Ë« 93¶Ô 94½Ó 95×¢ 96Òâ 97ËÙ
//   98¶È 99×Ë 9AÌ¬ 9B¹ì 9C¼£ 9DÒ¹ 9E¼ä 9Fµ÷ A0ÊÔ A1Õı A2³£
//   row : ×ÖÄÚĞĞºÅ 0~15
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
        8'h61: begin  // a
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003C;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0002;
                4'd9: bits = 16'h003E;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h003A;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h62: begin  // b
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0040;
                4'd4: bits = 16'h0040;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h005C;
                4'd7: bits = 16'h0062;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0062;
                4'd13: bits = 16'h005C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h63: begin  // c
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003C;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0040;
                4'd9: bits = 16'h0040;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h64: begin  // d
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0002;
                4'd4: bits = 16'h0002;
                4'd5: bits = 16'h0002;
                4'd6: bits = 16'h003A;
                4'd7: bits = 16'h0046;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h003A;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h65: begin  // e
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003C;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h007E;
                4'd10: bits = 16'h0040;
                4'd11: bits = 16'h0040;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h66: begin  // f
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h000C;
                4'd4: bits = 16'h0010;
                4'd5: bits = 16'h0010;
                4'd6: bits = 16'h0010;
                4'd7: bits = 16'h007C;
                4'd8: bits = 16'h0010;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0010;
                4'd11: bits = 16'h0010;
                4'd12: bits = 16'h0010;
                4'd13: bits = 16'h0010;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h67: begin  // g
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0002;
                4'd6: bits = 16'h003A;
                4'd7: bits = 16'h0044;
                4'd8: bits = 16'h0044;
                4'd9: bits = 16'h0044;
                4'd10: bits = 16'h0038;
                4'd11: bits = 16'h0020;
                4'd12: bits = 16'h003C;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0042;
                4'd15: bits = 16'h003C;
                default: bits = 16'h0000;
            endcase
        end
        8'h68: begin  // h
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0040;
                4'd4: bits = 16'h0040;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h005C;
                4'd7: bits = 16'h0062;
                4'd8: bits = 16'h0042;
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
        8'h69: begin  // i
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0008;
                4'd4: bits = 16'h0008;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0018;
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
        8'h6A: begin  // j
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0004;
                4'd4: bits = 16'h0004;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h000C;
                4'd7: bits = 16'h0004;
                4'd8: bits = 16'h0004;
                4'd9: bits = 16'h0004;
                4'd10: bits = 16'h0004;
                4'd11: bits = 16'h0004;
                4'd12: bits = 16'h0004;
                4'd13: bits = 16'h0004;
                4'd14: bits = 16'h0048;
                4'd15: bits = 16'h0030;
                default: bits = 16'h0000;
            endcase
        end
        8'h6B: begin  // k
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0040;
                4'd4: bits = 16'h0040;
                4'd5: bits = 16'h0040;
                4'd6: bits = 16'h0044;
                4'd7: bits = 16'h0048;
                4'd8: bits = 16'h0050;
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
        8'h6C: begin  // l
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0018;
                4'd4: bits = 16'h0008;
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
        8'h6D: begin  // m
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0076;
                4'd7: bits = 16'h0049;
                4'd8: bits = 16'h0049;
                4'd9: bits = 16'h0049;
                4'd10: bits = 16'h0049;
                4'd11: bits = 16'h0049;
                4'd12: bits = 16'h0049;
                4'd13: bits = 16'h0049;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h6E: begin  // n
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h005C;
                4'd7: bits = 16'h0062;
                4'd8: bits = 16'h0042;
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
        8'h6F: begin  // o
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003C;
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
        8'h70: begin  // p
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h005C;
                4'd7: bits = 16'h0062;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0062;
                4'd13: bits = 16'h005C;
                4'd14: bits = 16'h0040;
                4'd15: bits = 16'h0040;
                default: bits = 16'h0000;
            endcase
        end
        8'h71: begin  // q
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003A;
                4'd7: bits = 16'h0046;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h003A;
                4'd14: bits = 16'h0002;
                4'd15: bits = 16'h0002;
                default: bits = 16'h0000;
            endcase
        end
        8'h72: begin  // r
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h005C;
                4'd7: bits = 16'h0062;
                4'd8: bits = 16'h0042;
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
        8'h73: begin  // s
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h003C;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0040;
                4'd9: bits = 16'h0030;
                4'd10: bits = 16'h000C;
                4'd11: bits = 16'h0002;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h003C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h74: begin  // t
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0010;
                4'd5: bits = 16'h0010;
                4'd6: bits = 16'h0010;
                4'd7: bits = 16'h007C;
                4'd8: bits = 16'h0010;
                4'd9: bits = 16'h0010;
                4'd10: bits = 16'h0010;
                4'd11: bits = 16'h0010;
                4'd12: bits = 16'h0010;
                4'd13: bits = 16'h000C;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h75: begin  // u
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0042;
                4'd12: bits = 16'h0046;
                4'd13: bits = 16'h003A;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h76: begin  // v
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0024;
                4'd10: bits = 16'h0024;
                4'd11: bits = 16'h0024;
                4'd12: bits = 16'h0018;
                4'd13: bits = 16'h0018;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h77: begin  // w
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0041;
                4'd7: bits = 16'h0049;
                4'd8: bits = 16'h0049;
                4'd9: bits = 16'h0049;
                4'd10: bits = 16'h0049;
                4'd11: bits = 16'h0049;
                4'd12: bits = 16'h0049;
                4'd13: bits = 16'h0036;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h78: begin  // x
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0024;
                4'd9: bits = 16'h0018;
                4'd10: bits = 16'h0018;
                4'd11: bits = 16'h0024;
                4'd12: bits = 16'h0042;
                4'd13: bits = 16'h0042;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h79: begin  // y
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0042;
                4'd7: bits = 16'h0042;
                4'd8: bits = 16'h0042;
                4'd9: bits = 16'h0042;
                4'd10: bits = 16'h0042;
                4'd11: bits = 16'h0026;
                4'd12: bits = 16'h001A;
                4'd13: bits = 16'h0002;
                4'd14: bits = 16'h0002;
                4'd15: bits = 16'h003C;
                default: bits = 16'h0000;
            endcase
        end
        8'h7A: begin  // z
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h007E;
                4'd7: bits = 16'h0002;
                4'd8: bits = 16'h0004;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0010;
                4'd11: bits = 16'h0020;
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
        8'h2B: begin  // +
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0000;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h0008;
                4'd7: bits = 16'h0008;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h007F;
                4'd10: bits = 16'h0008;
                4'd11: bits = 16'h0008;
                4'd12: bits = 16'h0008;
                4'd13: bits = 16'h0000;
                4'd14: bits = 16'h0000;
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
        8'h25: begin  // %
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'h0000;
                4'd3: bits = 16'h0000;
                4'd4: bits = 16'h0031;
                4'd5: bits = 16'h004A;
                4'd6: bits = 16'h004A;
                4'd7: bits = 16'h0034;
                4'd8: bits = 16'h0008;
                4'd9: bits = 16'h0008;
                4'd10: bits = 16'h0016;
                4'd11: bits = 16'h0029;
                4'd12: bits = 16'h0029;
                4'd13: bits = 16'h0046;
                4'd14: bits = 16'h0000;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h20: begin  //  
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
        8'h80: begin  // ±à
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
        8'h81: begin  // Âë
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
        8'h82: begin  // Æ÷
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
        8'h83: begin  // ÍÓ
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
        8'h84: begin  // Âİ
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
        8'h85: begin  // ÒÇ
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
        8'h86: begin  // ¾à
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
        8'h87: begin  // Àë
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
        8'h88: begin  // Ä¿
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
        8'h89: begin  // ±ê
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
        8'h8A: begin  // ¶ª
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
        8'h8B: begin  // Ê§
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
        8'h8C: begin  // Î´
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h0100;
                4'd2: bits = 16'h0100;
                4'd3: bits = 16'h3FF8;
                4'd4: bits = 16'h0100;
                4'd5: bits = 16'h0100;
                4'd6: bits = 16'h0100;
                4'd7: bits = 16'hFFFE;
                4'd8: bits = 16'h0380;
                4'd9: bits = 16'h0540;
                4'd10: bits = 16'h0920;
                4'd11: bits = 16'h1110;
                4'd12: bits = 16'h2108;
                4'd13: bits = 16'hC106;
                4'd14: bits = 16'h0100;
                4'd15: bits = 16'h0100;
                default: bits = 16'h0000;
            endcase
        end
        8'h8D: begin  // Ê¶
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h2000;
                4'd2: bits = 16'h11FC;
                4'd3: bits = 16'h1104;
                4'd4: bits = 16'h0104;
                4'd5: bits = 16'h0104;
                4'd6: bits = 16'hF104;
                4'd7: bits = 16'h1104;
                4'd8: bits = 16'h11FC;
                4'd9: bits = 16'h1104;
                4'd10: bits = 16'h1000;
                4'd11: bits = 16'h1490;
                4'd12: bits = 16'h1888;
                4'd13: bits = 16'h1104;
                4'd14: bits = 16'h0202;
                4'd15: bits = 16'h0402;
                default: bits = 16'h0000;
            endcase
        end
        8'h8E: begin  // ±ğ
            case (row)
                4'd0: bits = 16'h0004;
                4'd1: bits = 16'h7F04;
                4'd2: bits = 16'h4104;
                4'd3: bits = 16'h4124;
                4'd4: bits = 16'h4124;
                4'd5: bits = 16'h7F24;
                4'd6: bits = 16'h1024;
                4'd7: bits = 16'h1024;
                4'd8: bits = 16'hFF24;
                4'd9: bits = 16'h1124;
                4'd10: bits = 16'h1124;
                4'd11: bits = 16'h1124;
                4'd12: bits = 16'h2104;
                4'd13: bits = 16'h2104;
                4'd14: bits = 16'h4A14;
                4'd15: bits = 16'h8408;
                default: bits = 16'h0000;
            endcase
        end
        8'h8F: begin  // µ¥
            case (row)
                4'd0: bits = 16'h1010;
                4'd1: bits = 16'h0820;
                4'd2: bits = 16'h0440;
                4'd3: bits = 16'h3FF8;
                4'd4: bits = 16'h2108;
                4'd5: bits = 16'h2108;
                4'd6: bits = 16'h3FF8;
                4'd7: bits = 16'h2108;
                4'd8: bits = 16'h2108;
                4'd9: bits = 16'h3FF8;
                4'd10: bits = 16'h0100;
                4'd11: bits = 16'h0100;
                4'd12: bits = 16'hFFFE;
                4'd13: bits = 16'h0100;
                4'd14: bits = 16'h0100;
                4'd15: bits = 16'h0100;
                default: bits = 16'h0000;
            endcase
        end
        8'h90: begin  // ¸ú
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h7DF8;
                4'd2: bits = 16'h4508;
                4'd3: bits = 16'h4508;
                4'd4: bits = 16'h45F8;
                4'd5: bits = 16'h7D08;
                4'd6: bits = 16'h1108;
                4'd7: bits = 16'h11F8;
                4'd8: bits = 16'h5D44;
                4'd9: bits = 16'h5148;
                4'd10: bits = 16'h5130;
                4'd11: bits = 16'h5120;
                4'd12: bits = 16'h5D10;
                4'd13: bits = 16'hE148;
                4'd14: bits = 16'h0186;
                4'd15: bits = 16'h0100;
                default: bits = 16'h0000;
            endcase
        end
        8'h91: begin  // ×Ù
            case (row)
                4'd0: bits = 16'h0040;
                4'd1: bits = 16'h7820;
                4'd2: bits = 16'h4BFE;
                4'd3: bits = 16'h4A02;
                4'd4: bits = 16'h4C04;
                4'd5: bits = 16'h79F8;
                4'd6: bits = 16'h1000;
                4'd7: bits = 16'h1000;
                4'd8: bits = 16'h53FE;
                4'd9: bits = 16'h5C20;
                4'd10: bits = 16'h5128;
                4'd11: bits = 16'h5124;
                4'd12: bits = 16'h5A22;
                4'd13: bits = 16'hE422;
                4'd14: bits = 16'h00A0;
                4'd15: bits = 16'h0040;
                default: bits = 16'h0000;
            endcase
        end
        8'h92: begin  // Ë«
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h0000;
                4'd2: bits = 16'hFDFC;
                4'd3: bits = 16'h0484;
                4'd4: bits = 16'h4484;
                4'd5: bits = 16'h4484;
                4'd6: bits = 16'h2888;
                4'd7: bits = 16'h2888;
                4'd8: bits = 16'h1050;
                4'd9: bits = 16'h1050;
                4'd10: bits = 16'h2820;
                4'd11: bits = 16'h2820;
                4'd12: bits = 16'h4450;
                4'd13: bits = 16'h4488;
                4'd14: bits = 16'h8104;
                4'd15: bits = 16'h0202;
                default: bits = 16'h0000;
            endcase
        end
        8'h93: begin  // ¶Ô
            case (row)
                4'd0: bits = 16'h0010;
                4'd1: bits = 16'h0010;
                4'd2: bits = 16'h0010;
                4'd3: bits = 16'h7E10;
                4'd4: bits = 16'h02FE;
                4'd5: bits = 16'h0210;
                4'd6: bits = 16'h2410;
                4'd7: bits = 16'h1490;
                4'd8: bits = 16'h0850;
                4'd9: bits = 16'h0850;
                4'd10: bits = 16'h1410;
                4'd11: bits = 16'h1210;
                4'd12: bits = 16'h2210;
                4'd13: bits = 16'h4010;
                4'd14: bits = 16'h0050;
                4'd15: bits = 16'h0020;
                default: bits = 16'h0000;
            endcase
        end
        8'h94: begin  // ½Ó
            case (row)
                4'd0: bits = 16'h1080;
                4'd1: bits = 16'h1040;
                4'd2: bits = 16'h13FC;
                4'd3: bits = 16'h1000;
                4'd4: bits = 16'hFD08;
                4'd5: bits = 16'h1090;
                4'd6: bits = 16'h17FE;
                4'd7: bits = 16'h1040;
                4'd8: bits = 16'h1840;
                4'd9: bits = 16'h37FE;
                4'd10: bits = 16'hD088;
                4'd11: bits = 16'h1108;
                4'd12: bits = 16'h1090;
                4'd13: bits = 16'h1060;
                4'd14: bits = 16'h5198;
                4'd15: bits = 16'h2604;
                default: bits = 16'h0000;
            endcase
        end
        8'h95: begin  // ×¢
            case (row)
                4'd0: bits = 16'h0080;
                4'd1: bits = 16'h2040;
                4'd2: bits = 16'h1000;
                4'd3: bits = 16'h17FC;
                4'd4: bits = 16'h8040;
                4'd5: bits = 16'h4040;
                4'd6: bits = 16'h4040;
                4'd7: bits = 16'h1040;
                4'd8: bits = 16'h13FC;
                4'd9: bits = 16'h2040;
                4'd10: bits = 16'hE040;
                4'd11: bits = 16'h2040;
                4'd12: bits = 16'h2040;
                4'd13: bits = 16'h2040;
                4'd14: bits = 16'h2FFE;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h96: begin  // Òâ
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h3FF8;
                4'd2: bits = 16'h0820;
                4'd3: bits = 16'h0440;
                4'd4: bits = 16'hFFFE;
                4'd5: bits = 16'h0000;
                4'd6: bits = 16'h1FF0;
                4'd7: bits = 16'h1010;
                4'd8: bits = 16'h1FF0;
                4'd9: bits = 16'h1010;
                4'd10: bits = 16'h1FF0;
                4'd11: bits = 16'h0200;
                4'd12: bits = 16'h5104;
                4'd13: bits = 16'h5112;
                4'd14: bits = 16'h9012;
                4'd15: bits = 16'h0FF0;
                default: bits = 16'h0000;
            endcase
        end
        8'h97: begin  // ËÙ
            case (row)
                4'd0: bits = 16'h0040;
                4'd1: bits = 16'h2040;
                4'd2: bits = 16'h17FC;
                4'd3: bits = 16'h1040;
                4'd4: bits = 16'h03F8;
                4'd5: bits = 16'h0248;
                4'd6: bits = 16'hF248;
                4'd7: bits = 16'h13F8;
                4'd8: bits = 16'h10E0;
                4'd9: bits = 16'h1150;
                4'd10: bits = 16'h1248;
                4'd11: bits = 16'h1444;
                4'd12: bits = 16'h1040;
                4'd13: bits = 16'h2800;
                4'd14: bits = 16'h47FE;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h98: begin  // ¶È
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h0080;
                4'd2: bits = 16'h3FFE;
                4'd3: bits = 16'h2220;
                4'd4: bits = 16'h2220;
                4'd5: bits = 16'h3FFC;
                4'd6: bits = 16'h2220;
                4'd7: bits = 16'h2220;
                4'd8: bits = 16'h23E0;
                4'd9: bits = 16'h2000;
                4'd10: bits = 16'h2FF0;
                4'd11: bits = 16'h2410;
                4'd12: bits = 16'h4220;
                4'd13: bits = 16'h41C0;
                4'd14: bits = 16'h8630;
                4'd15: bits = 16'h380E;
                default: bits = 16'h0000;
            endcase
        end
        8'h99: begin  // ×Ë
            case (row)
                4'd0: bits = 16'h4080;
                4'd1: bits = 16'h2080;
                4'd2: bits = 16'h09FC;
                4'd3: bits = 16'h1204;
                4'd4: bits = 16'h2448;
                4'd5: bits = 16'hE040;
                4'd6: bits = 16'h20A0;
                4'd7: bits = 16'h2318;
                4'd8: bits = 16'h2C06;
                4'd9: bits = 16'h0400;
                4'd10: bits = 16'hFFFE;
                4'd11: bits = 16'h0820;
                4'd12: bits = 16'h1C40;
                4'd13: bits = 16'h0380;
                4'd14: bits = 16'h0C70;
                4'd15: bits = 16'h7008;
                default: bits = 16'h0000;
            endcase
        end
        8'h9A: begin  // Ì¬
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h0100;
                4'd2: bits = 16'h7FFC;
                4'd3: bits = 16'h0100;
                4'd4: bits = 16'h0280;
                4'd5: bits = 16'h0440;
                4'd6: bits = 16'h0A20;
                4'd7: bits = 16'h3118;
                4'd8: bits = 16'hC006;
                4'd9: bits = 16'h0100;
                4'd10: bits = 16'h0888;
                4'd11: bits = 16'h4884;
                4'd12: bits = 16'h4812;
                4'd13: bits = 16'h4812;
                4'd14: bits = 16'h87F0;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h9B: begin  // ¹ì
            case (row)
                4'd0: bits = 16'h2080;
                4'd1: bits = 16'h2080;
                4'd2: bits = 16'h2080;
                4'd3: bits = 16'hFC80;
                4'd4: bits = 16'h43F0;
                4'd5: bits = 16'h5090;
                4'd6: bits = 16'h9090;
                4'd7: bits = 16'hFC90;
                4'd8: bits = 16'h1090;
                4'd9: bits = 16'h1090;
                4'd10: bits = 16'h1C90;
                4'd11: bits = 16'hF092;
                4'd12: bits = 16'h5112;
                4'd13: bits = 16'h1112;
                4'd14: bits = 16'h120E;
                4'd15: bits = 16'h1400;
                default: bits = 16'h0000;
            endcase
        end
        8'h9C: begin  // ¼£
            case (row)
                4'd0: bits = 16'h0040;
                4'd1: bits = 16'h2020;
                4'd2: bits = 16'h1020;
                4'd3: bits = 16'h17FE;
                4'd4: bits = 16'h0090;
                4'd5: bits = 16'h0090;
                4'd6: bits = 16'hF294;
                4'd7: bits = 16'h1292;
                4'd8: bits = 16'h1492;
                4'd9: bits = 16'h1110;
                4'd10: bits = 16'h1110;
                4'd11: bits = 16'h1250;
                4'd12: bits = 16'h1420;
                4'd13: bits = 16'h2800;
                4'd14: bits = 16'h47FE;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'h9D: begin  // Ò¹
            case (row)
                4'd0: bits = 16'h0200;
                4'd1: bits = 16'h0100;
                4'd2: bits = 16'hFFFE;
                4'd3: bits = 16'h0880;
                4'd4: bits = 16'h0880;
                4'd5: bits = 16'h10F8;
                4'd6: bits = 16'h1108;
                4'd7: bits = 16'h3148;
                4'd8: bits = 16'h5228;
                4'd9: bits = 16'h9510;
                4'd10: bits = 16'h1110;
                4'd11: bits = 16'h10A0;
                4'd12: bits = 16'h1040;
                4'd13: bits = 16'h10A0;
                4'd14: bits = 16'h1118;
                4'd15: bits = 16'h1606;
                default: bits = 16'h0000;
            endcase
        end
        8'h9E: begin  // ¼ä
            case (row)
                4'd0: bits = 16'h2000;
                4'd1: bits = 16'h13FC;
                4'd2: bits = 16'h1004;
                4'd3: bits = 16'h4004;
                4'd4: bits = 16'h47C4;
                4'd5: bits = 16'h4444;
                4'd6: bits = 16'h4444;
                4'd7: bits = 16'h4444;
                4'd8: bits = 16'h47C4;
                4'd9: bits = 16'h4444;
                4'd10: bits = 16'h4444;
                4'd11: bits = 16'h4444;
                4'd12: bits = 16'h47C4;
                4'd13: bits = 16'h4004;
                4'd14: bits = 16'h4014;
                4'd15: bits = 16'h4008;
                default: bits = 16'h0000;
            endcase
        end
        8'h9F: begin  // µ÷
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h47FC;
                4'd2: bits = 16'h2444;
                4'd3: bits = 16'h2444;
                4'd4: bits = 16'h05F4;
                4'd5: bits = 16'h0444;
                4'd6: bits = 16'hE444;
                4'd7: bits = 16'h27FC;
                4'd8: bits = 16'h2404;
                4'd9: bits = 16'h25F4;
                4'd10: bits = 16'h2514;
                4'd11: bits = 16'h2D14;
                4'd12: bits = 16'h35F4;
                4'd13: bits = 16'h2404;
                4'd14: bits = 16'h0414;
                4'd15: bits = 16'h0808;
                default: bits = 16'h0000;
            endcase
        end
        8'hA0: begin  // ÊÔ
            case (row)
                4'd0: bits = 16'h0028;
                4'd1: bits = 16'h2024;
                4'd2: bits = 16'h1024;
                4'd3: bits = 16'h1020;
                4'd4: bits = 16'h07FE;
                4'd5: bits = 16'h0020;
                4'd6: bits = 16'hF020;
                4'd7: bits = 16'h17E0;
                4'd8: bits = 16'h1120;
                4'd9: bits = 16'h1110;
                4'd10: bits = 16'h1110;
                4'd11: bits = 16'h1510;
                4'd12: bits = 16'h19CA;
                4'd13: bits = 16'h170A;
                4'd14: bits = 16'h0206;
                4'd15: bits = 16'h0002;
                default: bits = 16'h0000;
            endcase
        end
        8'hA1: begin  // Õı
            case (row)
                4'd0: bits = 16'h0000;
                4'd1: bits = 16'h7FFC;
                4'd2: bits = 16'h0100;
                4'd3: bits = 16'h0100;
                4'd4: bits = 16'h0100;
                4'd5: bits = 16'h0100;
                4'd6: bits = 16'h1100;
                4'd7: bits = 16'h11F8;
                4'd8: bits = 16'h1100;
                4'd9: bits = 16'h1100;
                4'd10: bits = 16'h1100;
                4'd11: bits = 16'h1100;
                4'd12: bits = 16'h1100;
                4'd13: bits = 16'h1100;
                4'd14: bits = 16'hFFFE;
                4'd15: bits = 16'h0000;
                default: bits = 16'h0000;
            endcase
        end
        8'hA2: begin  // ³£
            case (row)
                4'd0: bits = 16'h0100;
                4'd1: bits = 16'h1110;
                4'd2: bits = 16'h0920;
                4'd3: bits = 16'h7FFE;
                4'd4: bits = 16'h4002;
                4'd5: bits = 16'h8FE4;
                4'd6: bits = 16'h0820;
                4'd7: bits = 16'h0820;
                4'd8: bits = 16'h0FE0;
                4'd9: bits = 16'h0100;
                4'd10: bits = 16'h1FF0;
                4'd11: bits = 16'h1110;
                4'd12: bits = 16'h1110;
                4'd13: bits = 16'h1150;
                4'd14: bits = 16'h1120;
                4'd15: bits = 16'h0100;
                default: bits = 16'h0000;
            endcase
        end
        default: bits = 16'h0000;
    endcase
end
endmodule
