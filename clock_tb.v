`timescale 1ns/1ps
module clock_tb;

    // Inputs
    reg clk, reset_n;

    // Outputs
    wire [5:0] second, minute;
    wire [4:0] hour;
	wire [27:0] sec_count;

    // Instantiate the Unit Under Test (UUT)
    clock uut (
        .clk (clk),
		.reset_n (reset_n),
		.second (second),
		.minute (minute),
		.hour (hour),
		.sec_count (sec_count)
    );
    
    initial clk = 0;

    always #5 clk = ~clk;  //Every 100 nanosec toggle the clock.
    
	initial begin
        reset_n = 1'b1;
        // Wait 100 ns for global reset to finish
        #100;
        reset_n = 0;  
    end
      
endmodule
