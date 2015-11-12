// A counter that either counts or is reset to 0 for the gas pump module
// ECE 485 HW1
// James Schiffer
// sources: http://www.bitweenie.com/listings/verilog-counter/

module counter(
	input clock, 
	input reset,
	output [3:0] count
);

//--------------------------------------------------------------
// signal definitions
//--------------------------------------------------------------

reg [3:0] count_internal;

//--------------------------------------------------------------
// counter
//--------------------------------------------------------------

// counter
always @(posedge clock)
begin
	if (reset) begin
		// initialize counters on reset
		count_internal <= 4'b0;
	end
	else begin
		//count up

		//$display("The value of the counter is: %b", count_internal);
		count_internal <= count_internal + 1;
	end

end

//--------------------------------------------------------------
// outputs
//--------------------------------------------------------------

// module output wires
assign count = count_internal;

endmodule