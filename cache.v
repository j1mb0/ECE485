//---------------------------
// ECE 485 HW 4 CACHE MODULE
// James Schiffer & Grant Cazhina
// 2-Way Set Associative Cache
// USING 
// Assignment Description:
// 
// ASSUMPTIONS:
// Seperate data and address buses.
// Address bus is 16 bits wide, data bus is 8 bits wide.
// Cache size of 256 bytes
//---------------------------

module cache(
			 // INPUTS
			 clock		,
			 reset		,
			 write		,
			 read		,
			 oe			,
			 address_bus,
			 // OUTPUTS
			 hit	,
			 // Shared Bus
			 data_bus,
			 // waveform variable 
			 state
			);

// Cache Parameters
parameter CACHE_LINES = 16;
parameter ADDRESS_BUS_WIDTH = 16;
parameter INDEX_WIDTH = 4;
parameter DATA_BUS_WIDTH = 8;
parameter BYTE_SELECT_WIDTH = 2;
parameter TAG_WIDTH = ADDRESS_BUS_WIDTH  - (INDEX_WIDTH + BYTE_SELECT_WIDTH);
// Assumption
parameter CACHE_SIZE = 2**(INDEX_WIDTH + BYTE_SELECT_WIDTH);
parameter CACHE_LINE_SIZE = CACHE_SIZE / CACHE_LINES; // 64 / 16 = 4 bytes 
// FIGURE OUT --
// I always assumed data bus determined how deep each memory location is. 
// For example, if you have a 16 bit address bus, that yields 131071 memory 
// locations. Now each memory locatation can hold a number of bytes, set by the 
// data bus. For an 8 bit data bus you have a byte memory location. 16 bits gives
// 2 bytes, and so forth. But in class he said a memory locatation should be 2 or 
// 4 bytes. Does this mean to transfer one memory locataion requires 2 clock cycles
// (at double data rate)? Do we need to code this in the state machine?

// -- Input Ports ---
input  clock, reset, write, read, oe;
input [ADDRESS_BUS_WIDTH-1:0] address_bus;

// --- Output Ports ----
output hit, state;

// ----- Bidirectional Ports -----
inout [DATA_BUS_WIDTH-1:0] data_bus;
wire [DATA_BUS_WIDTH-1:0] data_bus;

// ------ Input Ports Data Type ------
wire clock, reset, write, read, oe;
wire [ADDRESS_BUS_WIDTH-1:0] address_bus;

// ------ Output Ports Data Type ------
reg hit;

// ----- Internal Constraints -----

parameter NUMSTATES = 6;
//parameter DATA_BYTE_SIZE = 4;

//parameter CLKS_PER_TRANSFER = DATA_BYTE_SIZE;
parameter 	WAIT 		= 8'b000001,
			FETCH_DATA 	= 8'b000010,
			//READ_BUS 	= 8'b00000100,
			READ_HIT 	= 8'b000100,
			READ_MISS 	= 8'b001000,
			WRITE_HIT 	= 8'b010000,
			WRITE_MISS 	= 8'b100000;
			//OUTPUT_BUS	= 8'b10000000;

// ------ Internal Variables -------
reg	[NUMSTATES-1:0]  state; 	 // Seq part of the FSM
wire [NUMSTATES-1:0] next_state; // Combo part of FSM	
reg [INDEX_WIDTH-1:0] index;
reg [1:0] byte_select;
reg [TAG_WIDTH-1:0] tag;
integer i;
integer dumb_counter = 0;

// counter related
wire	[3:0] count;
reg 	counter_reset;
counter my_counter(clock, counter_reset, count);

reg [7:0] data_holder;	// [DATA_BYTE_SIZE-1:0]

//reg	[NUMSTATES-1:0] state; // Seq part of the FSM
//wire[NUMSTATES-1:0] next_state; // Combo part of FSM	

//cache memory related
reg  [CACHE_LINES-1:0] valid_bits;		// one valid bit per cache line
reg  [TAG_WIDTH-1:0] tags [0:CACHE_LINES-1][0:CACHE_LINE_SIZE-1];
reg  [7:0]  data_memory [0:CACHE_LINES-1][0:CACHE_LINE_SIZE-1];  //[DATA_BYTE_SIZE-1:0]


// ------ Set initial state for outputs ---
initial begin
	hit <= 1'b0;
	counter_reset <= 1'b0;
end

// ------ Code Start Here ------

assign data_bus = (read && oe && !write) ? data_holder : 8'bz; 

// Parse Address bus for cache components.
//always@(address_bus)
//begin
//	tag = address_bus[(ADDRESS_BUS_WIDTH):INDEX_WIDTH + 2];
//	index = address_bus[(ADDRESS_BUS_WIDTH - TAG_WIDTH):2];
//	byte_select = address_bus[2:0];
//end

assign next_state = cache_fsm(state, read, write, count);

// ----- Function for Combo Logic -------
function [NUMSTATES-1:0] cache_fsm;
	//inputs 
	input [NUMSTATES-1:0] 	curstate;
	input read;
	input write;
	input [3:0]	the_count;
	
	case(curstate)
		WAIT:
		begin
			$display("WAIT STATE");
			if(read == 1'b1 && write == 1'b0)
			begin
				//$display("read value = %b", read);
				cache_fsm = FETCH_DATA;
				//$display("next state = %b", cache_fsm);
			end
			else if(read == 1'b0 && write == 1'b1)
			begin
				//$display("write value = %b", write);
				//dumb_counter = 0;
				cache_fsm = FETCH_DATA;
			end
			else
			begin
				$display("Waiting...");
				cache_fsm = WAIT;
			end
		end
		FETCH_DATA:
		begin
			$display("FETCH DATA STATE");
			tag = address_bus[ADDRESS_BUS_WIDTH-1:INDEX_WIDTH + BYTE_SELECT_WIDTH];
			index = address_bus[(ADDRESS_BUS_WIDTH - TAG_WIDTH):BYTE_SELECT_WIDTH];
			byte_select = address_bus[BYTE_SELECT_WIDTH-1:0];
			if(read == 1'b1 && write == 1'b0)	//read logic
			begin
				$display("READ");
				$display("Checking for data with index = %b, tag = %b, and valid bit = %b", index, tags[index][byte_select], valid_bits[index]);
				if(~valid_bits[index])	// cache miss
				begin
					cache_fsm = READ_MISS;
				end
				else if (tags[index][byte_select] == tag) // tag bits match (HIT!)
				begin
					cache_fsm = READ_HIT;
				end
				else // another miss, occupied by another 
				begin
					cache_fsm = READ_MISS;
				end
			end
			else if(read == 1'b0 && write == 1'b1)	//write logic
			begin
				$display("WRITE");
				if(valid_bits[index])	//if Valid bit set /* slot occupied */
				begin
					$display("Testing tags[index] %b == tag %b", tags[index][byte_select], tag);
					if (tags[index][byte_select] == tag) //if Tag bits match /* cache hit! */
					begin
						cache_fsm = WRITE_HIT;
					end
					else //else /* occupied by another */
					begin
						cache_fsm = WRITE_MISS;
					end
				end
				else /* slot empty */
				begin
					cache_fsm = WRITE_MISS;
				end
			end 
			else
			begin
				$display("BACK TO WAIT");
				cache_fsm = WAIT;
				end
		end
//		READ_BUS:
//		begin
//			
//			//cache_fsm = READ_BUS;
//			 //dumb_counter = dumb_counter + 1; //if(count == 1'b0011)
//			 //$display("COUNTER value = %d", dumb_counter);
//			 if (dumb_counter == 3)
//			 begin
//				cache_fsm = FETCH_DATA;
//			 end
//		end
		READ_HIT:
		begin
			$display("READ HIT");
			// deliver data to CPU
			cache_fsm = WAIT;
		end
		READ_MISS:
		begin
			$display("READ MISS");
			cache_fsm = WAIT;
		end
		WRITE_HIT:
		begin
			//write data to cache
			$display("WRITE HIT");
			cache_fsm = WAIT;
		end
		WRITE_MISS:
		begin
			$display("WRITE MISS");
			//$display("the_count = %b", the_count);
			cache_fsm = WAIT;
		end
//		OUTPUT_BUS:
//		begin
//			// ASSUMPTION: Data depth is 4 bytes. Needs 4 clock cycles for each transfer.
//			//data_bus = data_holder[count];
//			// if count is three, the data transfer is complete. Go back to WAIT state. 
//			if(count == 1'b0011)
//			begin
//				cache_fsm = WAIT;
//			end
//		end
		default:
		begin
			cache_fsm = WAIT;
		end
	endcase
endfunction
		
// ----- Seq Logic ------
always @ (posedge clock or posedge reset)
begin
	if (reset == 1'b1) 
	begin
		state <= WAIT;
	end else 
	begin
		state <= next_state;
	end
end

// ---- Output/Input Logic ----
always @ (posedge clock)
begin : OUTPUT_LOGIC
	case(state)
		WAIT:
		begin
			data_holder = 8'hBA;
		end
		FETCH_DATA:
		begin
			
			data_holder = data_bus;
			$display("FETCHING tag %b for index %b with byte select %b and data %b", tag, index, byte_select, data_holder);
			counter_reset = 1'b1;
			// $display("read %b off the bus ", data_holder);
		end
//		READ_BUS:
//		begin
//			data_holder = data_bus;
//			
//			// make sure the counter reset is turned off.
//			if(counter_reset == 1'b1)
//			begin
//			
//				counter_reset <= 1'b0;
//			end
//			// If the counter reached 4, the data transfer is complete
//			// so reset the counter
//			if(count == 1'b0011)
//			begin
//				$display("RESETING COUNTER");
//				counter_reset <= 1'b1;
//			end
//		end
		READ_HIT:
		begin
			// deliver data to CPU
			data_holder <= data_memory[index][byte_select];
			//for(i = 0; i < 4; i = i +1)
			//begin
			//	data_holder[i] <= data_memory[i][index];
			//end
			hit <= 1'b1;
		end
		READ_MISS:
		begin
 			hit <= 1'b0;
 			// stall CPU
 			// cast out existing cache line (“victim”)
 			// read cache line from memory ???
 			// write Tag bits
 			//tags[index] = tag;
 			// deliver data to CPU
 			//data_holder = data_memory[index];
		end
		WRITE_HIT:
		begin
			hit <= 1'b1;
			//write data to cache
			data_memory[index][byte_select] <= data_holder;
			//for(i = 0; i < 4; i = i +1)
			//begin
			//	data_memory[i][index] <= data_holder[i];
			//end
			//data_memory[index] = data_holder; 
			//write data to memory - or - set “dirty” bit 
		end
		WRITE_MISS:
		begin
			hit <= 1'b0;
			//if(counter_reset == 1'b1)
			//begin
			//	counter_reset = 1'b0;
			//end
			//$display("count is %b", count);
			//stall CPU
			//cast out existing cache line (“victim”)
			// ASSUMPTION: Write Through policy - Memory is up-to-date
			//read cache line from memory
			//write Tag bits
			$display("In WRITE MISS, saving tag and data");
			tags[index][byte_select] = tag;
			//write data to cache
			data_memory[index][byte_select] = data_holder; 
			// set valid bit
			valid_bits[index] = 1'b1;
			//write data to memory - or - set “dirty” bit
		end
//		OUTPUT_BUS:
//		begin
//			// ASSUMPTION: Data depth is 4 bytes. Needs 4 clock cycles for each transfer.
//			// data_bus = data_holder[count];
//			// make sure the counter reset is turned off.
//			if(counter_reset == 1'b1)
//			begin
//				counter_reset <= 1'b0;
//			end
//			// If the counter reached 4, the data transfer is complete
//			// so reset the counter
//			if(count == 1'b0011)
//			begin
//				$display("RESETING COUNTER");
//				counter_reset = 1'b1;
//			end
		//end
		default:
		begin
		end
	endcase
end

endmodule


