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
	clock 		= 1'b1;
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
	// each write/read takes 3 CLK cycles
	// pos edge clock happens at any multiple of ten
	#1 reset = 1'b1; 
	#15 reset = 1'b0;
	#1 oe = 1'b0;					//7
	#1 address_bus = 16'h0001;		//8
	data_holder = 8'b11111111;				
	#1 write = 1'b1;				// 9 1st write
	#30 address_bus = 16'h1010;	
	data_holder = 8'b00010001; 		// 39 2nd write
	#30 address_bus = 16'h0220;
	data_holder = 8'b00100010;	// 69 3rd Write
	//#10 data_holder = 8'b00110011;
	#15 write = 1'b0;				// 84 end writes
	#2 oe = 1'b1;					// 87 start reads
	#1 address_bus = 16'h0001;		// 88 1st read
	#1 read = 1'b1;					// 89 
	#30 address_bus = 16'h1010;		// 119 2nd read
	#30 address_bus = 16'h0220;		// 119 2nd read
	#60 oe = 1'b0;
	#200 $finish;
  end
  
endmodule