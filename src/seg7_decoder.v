module seg7(
    input [3:0]data_in,
    output reg [7:0]display_out,
    output [7:0]AN
    );

assign AN = 8'b11111110;

always @(*) begin
    case (data_in)
        4'b0000:
            display_out = 8'b11000000;  //zero
        4'b0001:
            display_out = 8'b11111001;  //one
        4'b0010:
            display_out = 8'b10100100;  //two
        4'b0011:
            display_out = 8'b10110000;  //three
        4'b0100:
            display_out = 8'b10011001;  //four
        4'b0101:
            display_out = 8'b10010010;  //five
        4'b0110:
            display_out = 8'b10000010;  //six
        4'b0111:
            display_out = 8'b11111000;  //seven
        4'b1000:
            display_out = 8'b10000000;  //eight
        4'b1001:
            display_out = 8'b10010000;  //nine
        default:
            display_out = 8'b11111111;  //blank
    endcase
end
endmodule

