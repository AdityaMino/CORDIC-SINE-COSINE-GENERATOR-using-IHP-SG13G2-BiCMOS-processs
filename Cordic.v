// Code your design here
`timescale 1ns/100ps

module sine_cosine #(
    parameter DATA_WIDTH  = 16,        // bit width of input/output (Xin, Yin, Xout, Yout)
    parameter ANGLE_WIDTH = 32,        // angle resolution in bits
    parameter ITER        = 16         // number of CORDIC iterations (≤ ANGLE_WIDTH)
)(
    input  wire                          clock,
    input  wire signed [ANGLE_WIDTH-1:0] angle,
    input  wire signed [DATA_WIDTH-1:0]  Xin,
    input  wire signed [DATA_WIDTH-1:0]  Yin,
    output wire signed [DATA_WIDTH:0]    Xout,
    output wire signed [DATA_WIDTH:0]    Yout
);

    // --------------------------------------------
    // Arctan lookup table
    // --------------------------------------------
    // Pre-computed atan(2^-i) values scaled to ANGLE_WIDTH
    // (This example keeps constants at 32-bit, but could be regenerated externally for ANGLE_WIDTH)
    reg signed [ANGLE_WIDTH-1:0] atan_table [0:ITER-1];
    initial begin
        atan_table[0]  = 32'b00100000000000000000000000000000; // atan(2^0)   ~ 45°
        atan_table[1]  = 32'b00010010111001000000010100011101; // atan(2^-1)  ~ 26.565°
        atan_table[2]  = 32'b00001001111110110011100001011011; // atan(2^-2)  ~ 14.036°
        atan_table[3]  = 32'b00000101000100010001000111010100; 
        atan_table[4]  = 32'b00000010100010110000110101000011;
        atan_table[5]  = 32'b00000001010001011101011111100001;
        atan_table[6]  = 32'b00000000101000101111011000011110;
        atan_table[7]  = 32'b00000000010100010111110001010101;
        atan_table[8]  = 32'b00000000001010001011111001010011;
        atan_table[9]  = 32'b00000000000101000101111100101110;
        atan_table[10] = 32'b00000000000010100010111110011000;
        atan_table[11] = 32'b00000000000001010001011111001100;
        atan_table[12] = 32'b00000000000000101000101111100110;
        atan_table[13] = 32'b00000000000000010100010111110011;
        atan_table[14] = 32'b00000000000000001010001011111001;
        atan_table[15] = 32'b00000000000000000101000101111101;
        // Extend further if ITER > 16
    end

    // --------------------------------------------
    // Registers for pipeline stages
    // --------------------------------------------
    reg signed [DATA_WIDTH:0] X [0:ITER-1];
    reg signed [DATA_WIDTH:0] Y [0:ITER-1];
    reg signed [ANGLE_WIDTH-1:0] Z [0:ITER-1];

    // --------------------------------------------
    // Stage 0 : Quadrant handling
    // --------------------------------------------
    wire [1:0] quadrant = angle[ANGLE_WIDTH-1:ANGLE_WIDTH-2];

    always @(posedge clock) begin
        case (quadrant)
            2'b00, 2'b11: begin
                X[0] <= Xin;
                Y[0] <= Yin;
                Z[0] <= angle;
            end
            2'b01: begin
                X[0] <= -Yin;
                Y[0] <= Xin;
                Z[0] <= {2'b00, angle[ANGLE_WIDTH-3:0]}; // subtract pi/2
            end
            2'b10: begin
                X[0] <= Yin;
                Y[0] <= -Xin;
                Z[0] <= {2'b11, angle[ANGLE_WIDTH-3:0]}; // add pi/2
            end
        endcase
    end

    // --------------------------------------------
    // Iterative stages
    // --------------------------------------------
    genvar i;
    generate
        for (i = 0; i < ITER-1; i=i+1) begin : cordic_stage
            wire signed [DATA_WIDTH:0] X_shr = X[i] >>> i;
            wire signed [DATA_WIDTH:0] Y_shr = Y[i] >>> i;
            wire Z_sign = Z[i][ANGLE_WIDTH-1]; // sign of angle

            always @(posedge clock) begin
                X[i+1] <= Z_sign ? X[i] + Y_shr : X[i] - Y_shr;
                Y[i+1] <= Z_sign ? Y[i] - X_shr : Y[i] + X_shr;
                Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
            end
        end
    endgenerate

    // --------------------------------------------
    // Outputs
    // --------------------------------------------
    assign Xout = X[ITER-1];
    assign Yout = Y[ITER-1];

endmodule
