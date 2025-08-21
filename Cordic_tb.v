`timescale 1 ns/100 ps

module cordic_test;

localparam SZ = 16; // bits of accuracy

reg  signed [SZ-1:0] Xin, Yin;
reg  signed [31:0] angle;   // signed angle for -π .. +π
wire signed [SZ:0] Xout, Yout;
reg         CLK_100MHZ;

//
// Waveform generator constants
//
localparam FALSE = 1'b0;
localparam TRUE  = 1'b1;

localparam real CORDIC_GAIN = 1.646760258;
localparam VALUE = 32000 / CORDIC_GAIN; // reduce by exact CORDIC gain

reg signed [63:0] i;
reg start;

initial begin
   //  VCD dump setup
   $dumpfile("cordic_test.vcd");
   $dumpvars(0, cordic_test);

   start = FALSE;
   $display("Starting simulation...");
   CLK_100MHZ = 1'b0;
   angle = 0;
   Xin   = VALUE;  // Xout = VALUE*cos(angle)
   Yin   = 0;      // Yout = VALUE*sin(angle)
   i     = 0;

   #1000;
   @(posedge CLK_100MHZ);
   start = TRUE;

   // Sweep angles -180° to +180° in 30° steps
   for (i = -180; i <= 180; i = i + 30) begin
      @(posedge CLK_100MHZ);
      start = FALSE;

      // Map degrees (-180..+180) → signed 32-bit fraction of circle (-π..+π)
      // Saturate +180° to +π - 1 LSB to avoid wrap ambiguity
      if (i == 180)
         angle = 32'sh7FFF_FFFF;
      else
         angle = $signed( ( (64'sd1 << 31) * i ) / 180 );

      // wait full pipeline depth for convergence
      repeat (SZ) @(posedge CLK_100MHZ);

      $display("Angle = %4d deg | angle_hex = %h | Xout (cos) = %d | Yout (sin) = %d", 
               i, angle, $signed(Xout), $signed(Yout));
   end

   #500;
   $display("Simulation has finished");
   $finish;
end

// Correct instantiation of generic sine_cosine module
sine_cosine #(
    .DATA_WIDTH(SZ),     // input/output width
    .ANGLE_WIDTH(32),    // angle width
    .ITER(SZ)            // number of iterations
) uut (
    .clock(CLK_100MHZ),
    .angle(angle),
    .Xin(Xin),
    .Yin(Yin),
    .Xout(Xout),
    .Yout(Yout)
);

//
// 100 MHz Clock generator
//
parameter CLK100_SPEED = 10;  // 100 MHz -> 10 ns

initial begin
  CLK_100MHZ = 1'b0;
  $display ("CLK_100MHZ started");
  #5;
  forever begin
    #(CLK100_SPEED/2) CLK_100MHZ = ~CLK_100MHZ;
  end
end

endmodule
