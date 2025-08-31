`timescale 1ns/100ps
`default_nettype none
// Synthesizable CORDIC (ASIC/OpenLane friendly)
// Verilog-2005 compatible version (no SystemVerilog 'int'/'automatic')

module cordic_board #(
    parameter integer DATA_WIDTH  = 16,  // Xin/Yin/Xout/Yout base width
    parameter integer ANGLE_WIDTH = 32,  // angle phase accumulator width
    parameter integer ITER        = 16   // iterations (<= ANGLE_WIDTH)
)(
    input  wire                          clock,
    input  wire signed [ANGLE_WIDTH-1:0] angle,
    input  wire signed [DATA_WIDTH-1:0]  Xin,
    input  wire signed [DATA_WIDTH-1:0]  Yin,
    output wire signed [DATA_WIDTH:0]    Xout,
    output wire signed [DATA_WIDTH:0]    Yout
);

    // ----------------------------
    // Constants (compile-time)
    // ----------------------------
    // π/2 in fixed-point where 2π == 2^ANGLE_WIDTH -> 2^(ANGLE_WIDTH-2)
    localparam signed [ANGLE_WIDTH-1:0] PI_OVER_2 =
        ({{(ANGLE_WIDTH-1){1'b0}},1'b1}) <<< (ANGLE_WIDTH-2);

    // ----------------------------
    // Arctan LUT as a pure constant function (no initial blocks)
    // Verilog-2005 style function (no 'automatic' / 'int')
    // ----------------------------
    function signed [ANGLE_WIDTH-1:0] atan_lut;
        input integer idx;
        begin
            case (idx)
                0 : atan_lut = 32'sb00100000000000000000000000000000; // ~45°
                1 : atan_lut = 32'sb00010010111001000000010100011101; // ~26.565°
                2 : atan_lut = 32'sb00001001111110110011100001011011; // ~14.036°
                3 : atan_lut = 32'sb00000101000100010001000111010100;
                4 : atan_lut = 32'sb00000010100010110000110101000011;
                5 : atan_lut = 32'sb00000001010001011101011111100001;
                6 : atan_lut = 32'sb00000000101000101111011000011110;
                7 : atan_lut = 32'sb00000000010100010111110001010101;
                8 : atan_lut = 32'sb00000000001010001011111001010011;
                9 : atan_lut = 32'sb00000000000101000101111100101110;
                10: atan_lut = 32'sb00000000000010100010111110011000;
                11: atan_lut = 32'sb00000000000001010001011111001100;
                12: atan_lut = 32'sb00000000000000101000101111100110;
                13: atan_lut = 32'sb00000000000000010100010111110011;
                14: atan_lut = 32'sb00000000000000001010001011111001;
                15: atan_lut = 32'sb00000000000000000101000101111101;
                default: atan_lut = {ANGLE_WIDTH{1'b0}};
            endcase
        end
    endfunction

    // ----------------------------
    // Pipeline state
    // ----------------------------
    // Unpacked arrays of signed packed regs are synthesizable in Yosys/OpenLane.
    reg signed [DATA_WIDTH:0]     X [0:ITER-1];
    reg signed [DATA_WIDTH:0]     Y [0:ITER-1];
    reg signed [ANGLE_WIDTH-1:0]  Z [0:ITER-1];

    // ----------------------------
    // Stage 0: quadrant handling
    // ----------------------------
    always @(posedge clock) begin
        if (angle >  PI_OVER_2) begin
            X[0] <= -Yin;
            Y[0] <=  Xin;
            Z[0] <= angle - PI_OVER_2;
        end else if (angle < -PI_OVER_2) begin
            X[0] <=  Yin;
            Y[0] <= -Xin;
            Z[0] <= angle + PI_OVER_2;
        end else begin
            X[0] <= Xin;
            Y[0] <= Yin;
            Z[0] <= angle;
        end
    end

    // ----------------------------
    // Iterative stages (pipeline)
    // ----------------------------
    genvar i;
    generate
        for (i = 0; i < ITER-1; i = i + 1) begin : cordic_stage
            // Bind a per-stage constant so no run-time ROM access is needed.
            localparam signed [ANGLE_WIDTH-1:0] ATAN_I = atan_lut(i);

            wire signed [DATA_WIDTH:0] X_shr = X[i] >>> i;
            wire signed [DATA_WIDTH:0] Y_shr = Y[i] >>> i;
            wire                        Z_sign = Z[i][ANGLE_WIDTH-1];

            always @(posedge clock) begin
                X[i+1] <= Z_sign ? X[i] + Y_shr : X[i] - Y_shr;
                Y[i+1] <= Z_sign ? Y[i] - X_shr : Y[i] + X_shr;
                Z[i+1] <= Z_sign ? Z[i] + ATAN_I : Z[i] - ATAN_I;
            end
        end
    endgenerate

    // ----------------------------
    // Outputs (last stage)
    // ----------------------------
    assign Xout = X[ITER-1];
    assign Yout = Y[ITER-1];

endmodule

`default_nettype wire
