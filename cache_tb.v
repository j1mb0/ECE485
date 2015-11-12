//---------------------------
// ECE 485 HW 4 TEST BENCH / CPU SIMULATOR
// James Schiffer 
// A memory module for the cache
// USING 
// Assignment Description:
// 
// ASSUMPTIONS:
// Seperate data and address buses.

module cache_tb;

//input variables
reg clock, reset, write, read, oe;
reg [15:0] address_bus;
reg [7:0] data_holder;
//output variables
wire hit;
//bidirectional variables
wire [7:0] data_bus;
// For waveform purposes
wire [5:0] state;
//wire [3:0] count;
//wire [3:0] count;

cache our_cache(
				clock,
				reset,
				write,
				read,
				oe,
				address_bus,
				hit,
				data_bus,
				state
			   );


//intialize inputs
initial
begin
	clock 		= 1'b0;
	reset 	 	= 1'b0; 
	write 	= 1'b0; 
	read		= 1'b0;
	oe = 1'b0;
	address_bus	= 4'h0000;
end

assign data_bus = (!read && !oe && write) ? data_holder : 8'bz; 

//generate the clock
always
	#5 clock = ~clock;
	
	
//test things
initial
  begin
	#1 reset = 1'b1;
	#6 reset = 1'b0;
	#1 oe = 1'b0;
	#1 address_bus = 4'h0001;
	#1 data_holder = 8'b11111111;
	#4 write = 1'b1;
	//#4 data_holder = 8'b00010001;
	//#10 data_holder = 8'b00100010;
	//#10 data_holder = 8'b00110011;
	#10 write = 1'b0;
	
	#15 oe = 1'b1;
	#1 address_bus = 4'h0001;
	#1 read = 1'b1;
	
	#20 oe = 1'b0;
	#200 $finish;
  end
  
endmodule