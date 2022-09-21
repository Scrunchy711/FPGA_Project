`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module labkit(
    input clk_100mhz,
    input [7:0] switch,
	 
    input btn_up,       // buttons, depress = high
    input btn_enter,
    input btn_left,
    input btn_down,
    input btn_right,
	 
    output [7:0] seg,   //output 0->6 = seg A->G ACTIVE LOW, 
                        //output 7 = decimal point, all active low
								
    output [3:0] dig,   //selects digits 0-3, ACTIVE LOW
    output [7:0] led,   // 1 turns on leds
	 
    output [2:0] vgaRed,
    output [2:0] vgaGreen,
    output [2:1] vgaBlue,
    output hsync,
    output vsync,
	 
    inout [7:0] ja,
    inout [7:0] jb,
    inout [7:0] jc,
    input [7:0] jd,
    inout [19:0] exp_io_n,
    inout [19:0] exp_io_p
    );

    // all unused outputs must be assigned
    assign vgaRed = 3'b111;
	 assign vgaGreen = 3'b111;
	 assign vgaBlue = 2'b11;
	 assign hsync = 1'b1;
	 assign vsync = 1'b1;
	 
	 
  ////////////////////////////////////////////////////////////////////////////
	// EDIT FROM HERE

	//assign led = 7'b000_0000;

	parameter c_CNT_2ms  = 200000; //number of clocks for 2 milliseconds with 100MHz clock
	reg [31:0] r_CNT_2ms = 0; //counter for 2ms
	reg [1:0] TOGGLE_2ms = 2'b00;  //used for multiplexing 4 seven segments
	  
	parameter c_CNT_1sec  = 100000000; //number of clocks for 1 second with 100MHz clock
	parameter c_CNT_1sec2  = 100000000;
	parameter c_CNT_1sec3  = 100000000;
	parameter day = 86400; //number of seconds in a day
	parameter hour = 3600; //number of seconds in an hour
 	parameter min = 60; //number of seconds in a minute
	reg [31:0] r_CNT_1sec = 0; //counter for 1second
	reg [31:0] r_CNT_1sec2 = 0; //counter for 1second
	reg [31:0] r_CNT_1sec3 = 0; //counter for 1second
	
	parameter c_CNT_4Hz = 12500000;
	reg [31:0] r_CNT_4Hz = 0;
	reg r_TOGGLE_4Hz = 1'b0;

	
	
	//reg [1:0] button_old;
	//reg [1:0] button_raise;
	//reg [1:0] button_down_old;
	reg upPressed, upPrev;
	wire up_button;
	reg rightPressed, rightPrev;
	wire right_button;
	reg enterPressed, enterPrev;
	wire enter_button;
	reg [1:0] hor_shift; //values of 0-3 to shift between segments
	reg [15:0] set_number_seg1;
	reg [15:0] set_number_seg2;
	reg [15:0] set_number_seg3;
	reg [15:0] set_number_seg4;
	reg [15:0] set_number_seg1_alarm;
	reg [15:0] set_number_seg2_alarm;
	reg [15:0] set_number_seg3_alarm;
	reg [15:0] set_number_seg4_alarm;
      
      
   reg [31:0] seconds_day;
	reg [31:0] seconds_day_alarm;
	reg [31:0] set_seconds_day;
	reg [31:0] set_seconds_day_alarm;
	reg [31:0] set_seconds_hour;
	reg [31:0] set_seconds_day_out;	
	reg [31:0] seconds_day_output;
	wire set_seconds_latch;
	reg [15:0] seconds_hour;
	reg [3:0] segment_pattern_24hr;
	reg [3:0] segment_pattern_hr;
	reg [3:0] segment_pattern_set;
	reg [3:0] segment_pattern_set_alarm;
   reg [3:0] segment_pattern;
	reg [3:0] dig;  
   reg [7:0] seg;
	
	reg [15:0] timer_seconds;
	reg trigger_alarm = 1'b0;
	reg trigger_alarm2 = 1'b0;

    // count r_CNT_2ms    0      ->    1        ->    2      ->    3
    // activates      segment 1    segment 2      segment 3     segment 4
    // and repeat				 
	always @ (posedge clk_100mhz) //handle 2ms increment, for changing segment display time  
    begin
      if (r_CNT_2ms == c_CNT_2ms-1) // -1, since counter starts at 0
        begin    
			 r_CNT_2ms    <= 0; //2ms has successfully passed, r_cnt_2ms to be zero again
			 if (TOGGLE_2ms == 3) //when TOGGLE_2ms is 11, loop through multiplexing 4 seven segments completed
				TOGGLE_2ms <=0; //revert back to zero 
			 else 
				TOGGLE_2ms <=TOGGLE_2ms+1; // loop through multiplexing 4 seven segments        
        end
      else
        r_CNT_2ms <= r_CNT_2ms + 1; //since not yet 2ms, counter increment to reach 2ms in RT
    end 
	 
	 // 1 second clock counting down
	always @ (posedge clk_100mhz)
	begin
		if (r_CNT_1sec3 == c_CNT_1sec3-1) // -1, since counter starts at 0
			begin        
				 if(timer_seconds <= 30)
				 begin
					if (timer_seconds <= 0)
					begin
						trigger_alarm2 <= 1'b1;
						timer_seconds <= 0;
					end
					else
					timer_seconds <= timer_seconds - 1;
					r_CNT_1sec3 <= 0;
				 end
			end
		else
			r_CNT_1sec3 <= r_CNT_1sec3 + 1;	
	end



	always @ (posedge clk_100mhz) //handle seconds for the day
    begin
		if (enterPressed)
			seconds_day <= set_seconds_day;
		//seconds_day <= seconds_day_output;
      if (r_CNT_1sec == c_CNT_1sec-1) // -1, since counter starts at 0, 1s RT has elapsed
        begin
		    if (seconds_day < day)
			   seconds_day <= seconds_day + 1;   
			 else
				seconds_day <= 0;//displaying number
            r_CNT_1sec <= 0;
        end
      else
        r_CNT_1sec <= r_CNT_1sec + 1;
    end
	 
	 
	 always @ (posedge clk_100mhz) //handle seconds for an hour
    begin
		if (enterPressed)
			seconds_hour <= set_seconds_hour;
      if (r_CNT_1sec == c_CNT_1sec-1) // -1, since counter starts at 0, 1s RT has elapsed
        begin
		    if (seconds_hour < hour)
			   seconds_hour <= seconds_hour + 1;   
			 else
				seconds_hour <= 0;//displaying number
            r_CNT_1sec <= 0;
        end
      else
        r_CNT_1sec <= r_CNT_1sec + 1;
    end
	 
	 always @ (posedge clk_100mhz) //Clock signal to toggle blinking of seven segment display
    begin
      if (r_CNT_4Hz == c_CNT_4Hz-1) 
        begin
		    r_TOGGLE_4Hz <= !r_TOGGLE_4Hz;
			 r_CNT_4Hz <= 0;
        end
      else
        r_CNT_4Hz <= r_CNT_4Hz + 1;
    end
	 

	 
	 
	 debounce db1(btn_up, clk_100mhz,up_button);
	 debounce db2(btn_right, clk_100mhz,right_button);
	 debounce db3(btn_enter, clk_100mhz,enter_button);
	 debounce db4(btn_down, clk_100mhz,down_button);
	 always @ (posedge clk_100mhz)
		begin
			upPrev <= up_button;
			rightPrev <= right_button;
			enterPrev <= enter_button;
			//downPrev <= btn_button
		if(up_button&&!upPrev)
			upPressed <= 1;
		else
			upPressed <= 0;
		if(right_button&&!rightPrev)
			rightPressed <= 1;
		else
			rightPressed <= 0;
		if(enter_button&&!enterPrev)
			enterPressed <= 1;
		else
			enterPressed <= 0;
		//if(down_button&&!downPrev)
			//downPressed <= 1;
		//else
			//downPressed <= 0;
			
		if (hor_shift > 3)
				hor_shift <=0;
		if (rightPressed)
				hor_shift <= hor_shift + 1;
		if ({switch[0],switch[1]} == 2'b01)
		begin			
		case (hor_shift)
		2'b00: begin
			if (set_number_seg1 > 2)
				set_number_seg1 <=0;
			if (upPressed)
				set_number_seg1 <= set_number_seg1 + 1;
		end
		2'b01: begin
			if (set_number_seg1 > 1)
			begin
			if (set_number_seg2 > 3)
				set_number_seg2 <=0;
			end
			else
			begin
			if (set_number_seg2 > 9)
				set_number_seg2 <= 0;
			end
			if (upPressed)
				set_number_seg2 <= set_number_seg2 + 1;
		end
		2'b10: begin
			if (set_number_seg3 > 5)
				set_number_seg3 <=0;
			if (upPressed)
				set_number_seg3 <= set_number_seg3 + 1;
		end
		2'b11: begin
			if (set_number_seg4 > 9)
				set_number_seg4 <=0;
			if (upPressed)
				set_number_seg4 <= set_number_seg4 + 1;
		end
		endcase
		end
		if ({switch[0],switch[1]} == 2'b11)
		begin
		case (hor_shift)
		2'b00: begin
			if (set_number_seg1_alarm > 2)
				set_number_seg1_alarm <=0;
			if (upPressed)
				set_number_seg1_alarm <= set_number_seg1_alarm + 1;
		end
		2'b01: begin
			if (set_number_seg1_alarm > 1)
			begin
			if (set_number_seg2_alarm > 3)
				set_number_seg2_alarm <=0;
			end
			else
			begin
			if (set_number_seg2_alarm > 9)
				set_number_seg2_alarm <= 0;
			end
			if (upPressed)
				set_number_seg2_alarm <= set_number_seg2_alarm + 1;
		end
		2'b10: begin
			if (set_number_seg3_alarm > 5)
				set_number_seg3_alarm <=0;
			if (upPressed)
				set_number_seg3_alarm <= set_number_seg3_alarm + 1;
		end
		2'b11: begin
			if (set_number_seg4_alarm > 9)
				set_number_seg4_alarm <=0;
			if (upPressed)
				set_number_seg4_alarm<= set_number_seg4_alarm + 1;
		end
		endcase
		end
		end
		
		always @ (*)
		begin
		if ({switch[0],switch[1]} == 2'b01)
		begin
		set_seconds_day <=  ((set_number_seg1*10 +  set_number_seg2)*3600)+(( set_number_seg3*10+ set_number_seg4)*60);
		set_seconds_hour <= ( set_number_seg3*10+ set_number_seg4)*60;
		end
		if ({switch[0],switch[1]} == 2'b11)
		set_seconds_day_alarm <=  ((set_number_seg1_alarm*10 +  set_number_seg2_alarm)*3600)+(( set_number_seg3_alarm*10+ set_number_seg4_alarm)*60);
		//if (downbutton)
		//set_timer_seconds_hour <= (( set_number_seg1*10+ set_number_seg2)*60)+ (set_number_seg3*10+set_number_seg4)
		end
		
		always @ (posedge clk_100mhz)
		begin
		if (set_seconds_day_alarm == seconds_day || trigger_alarm == 1)
			trigger_alarm <= 1'b1;
		seconds_day_alarm <= set_seconds_day_alarm + 10;
		if (seconds_day > seconds_day_alarm)
			trigger_alarm <= 1'b0;
		end
		

	 
				always @(TOGGLE_2ms) //initiate when TOGGLE_2MS changes
					begin
						case(TOGGLE_2ms) //TOGGLE_2ms
						2'b00: begin
							dig = 4'b0111; //activate first seven segment and deactivate other 3 seven segments
					      segment_pattern_24hr = (seconds_day/hour)/10; //the first digit of the displaying number (extract second digit of hour)
                  end
						2'b01: begin
							dig = 4'b1011; //activate second seven segment and deactivate other 3 seven segments
					      segment_pattern_24hr = (seconds_day/hour)%10 ; //the second digit of the displaying number (extract second digit of hour)
						end
						2'b10: begin
							dig = 4'b1101; //activate third seven segment and deactivate other 3 seven segments
							segment_pattern_24hr = ((seconds_day%hour)/min)/10; //the third digit of the displaying number ("%" is the modulo operator, e.g., 13%10 = 3, 555%100 = 55)
						end
						2'b11: begin
							dig = 4'b1110; //activate forth seven segment and deactivate other 3 seven segments
							segment_pattern_24hr = ((seconds_day%hour)/min)%10; //the fourth digit of the displaying number ("%" is the modulo operator, e.g., 13%10 = 3, 555%100 = 55)
						end
						endcase
					end
	
			
				always @(TOGGLE_2ms) //initiate when TOGGLE_2MS changes
					begin
						case(TOGGLE_2ms) //TOGGLE_2ms
						2'b00: begin
					    dig = 4'b0111;
					    segment_pattern_hr = seconds_hour/600;
                  end
						2'b01: begin
					    dig = 4'b1011;
					    segment_pattern_hr = (seconds_hour % 600)/60;
						end
						2'b10: begin
					    dig = 4'b1101;
					    segment_pattern_hr = (seconds_hour % 60)/10;
						end
						2'b11: begin
							dig = 4'b1110;
							segment_pattern_hr = ((seconds_hour % 1000)% 100)%10;
						end
						endcase
					end
					
					always @(TOGGLE_2ms) //initiate when TOGGLE_2MS changes
					begin
						case(TOGGLE_2ms) //TOGGLE_2ms
						2'b00: begin
					    dig = 4'b0111; //7
						 if (hor_shift === 0)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set = 10;
						 1'b1: segment_pattern_set = set_number_seg1;
						 endcase
						 end
						 else
						 segment_pattern_set = set_number_seg1;
                  end
						2'b01: begin
					    dig = 4'b1011;
						 if (hor_shift === 1)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set = 10;
						 1'b1: segment_pattern_set = set_number_seg2;
						 endcase
						 end
						 else
						 segment_pattern_set = set_number_seg2;
						end
						2'b10: begin
					    dig = 4'b1101;
						 if (hor_shift === 2)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set = 10;
						 1'b1: segment_pattern_set = set_number_seg3;
						 endcase
						 end
						else
						segment_pattern_set = set_number_seg3;
						end
						2'b11: begin
							dig = 4'b1110;
						if (hor_shift === 3)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set = 10;
						 1'b1: segment_pattern_set = set_number_seg4;
						 endcase
						 end
						else
						segment_pattern_set = set_number_seg4;
						end
						endcase
					end
					
					always @(TOGGLE_2ms) //initiate when TOGGLE_2MS changes
					begin
						case(TOGGLE_2ms) //TOGGLE_2ms
						2'b00: begin
					    dig = 4'b0111; //7
						 if (hor_shift === 0)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set_alarm = 10;
						 1'b1: segment_pattern_set_alarm = set_number_seg1_alarm;
						 endcase
						 end
						 else
						 segment_pattern_set_alarm = set_number_seg1_alarm;
                  end
						2'b01: begin
					    dig = 4'b1011;
						 if (hor_shift === 1)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set_alarm = 10;
						 1'b1: segment_pattern_set_alarm = set_number_seg2_alarm;
						 endcase
						 end
						 else
						 segment_pattern_set_alarm = set_number_seg2_alarm;
						end
						2'b10: begin
					    dig = 4'b1101;
						 if (hor_shift === 2)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set_alarm = 10;
						 1'b1: segment_pattern_set_alarm = set_number_seg3_alarm;
						 endcase
						 end
						else
						segment_pattern_set_alarm = set_number_seg3_alarm;
						end
						2'b11: begin
							dig = 4'b1110;
						if (hor_shift === 3)
						 begin
						 case (r_TOGGLE_4Hz)
						 1'b0: segment_pattern_set_alarm = 10;
						 1'b1: segment_pattern_set_alarm = set_number_seg4_alarm;
						 endcase
						 end
						else
						segment_pattern_set_alarm = set_number_seg4_alarm;
						end
						endcase
					end
					
				always @ (*)
				begin
				case({switch[0],switch[1]})
				2'b00: segment_pattern <= segment_pattern_24hr;
				2'b10: segment_pattern <= segment_pattern_hr;
				2'b01: segment_pattern <= segment_pattern_set;
				2'b11: segment_pattern <= segment_pattern_set_alarm;
				endcase
				end
			
	 
     
    always @(segment_pattern) // Cathode patterns of the 7-segment display
    begin
        case(segment_pattern)
        4'b0000: seg = 8'b11000000; // "0"     
        4'b0001: seg = 8'b11111001; // "1" 
        4'b0010: seg = 8'b10100100; // "2" 
        4'b0011: seg = 8'b10110000; // "3" 
        4'b0100: seg = 8'b10011001; // "4" 
        4'b0101: seg = 8'b10010010; // "5" 
        4'b0110: seg = 8'b10000010; // "6" 
        4'b0111: seg = 8'b11111000; // "7" 
        4'b1000: seg = 8'b10000000; // "8"     
        4'b1001: seg = 8'b10011000; // "9" 
        default: seg = 8'b11111111; // "off seven segment display"
        endcase
    end

clock_divider u0(.fast_clock(clk_100mhz), .slow_clock(slow_clock));
knight_rider_Alarm krA_1(trigger_alarm, slow_clock, led[7:0]);

	 
 
endmodule

module DFF(
	input Clk,
	input D, 
	output reg Q,
	output reg Qbar
	);
	
	always @ (posedge Clk)
		begin
		Q <=D;
		Qbar=~D;
		end
endmodule

module debounce (
	input pb, clk_in, 
	output btn);
	
wire clk_out;
wire Q1, Q2, Q2_bar;

parameter c_CNT_4Hz = 12500000;
reg [31:0] r_CNT_4Hz = 0;
reg r_TOGGLE_4Hz = 1'b0;

always @ (posedge clk_in)
	begin
		if (r_CNT_4Hz == c_CNT_4Hz-1)
			begin
				r_TOGGLE_4Hz <= !r_TOGGLE_4Hz;
				r_CNT_4Hz <= 0;
			end
		else
			r_CNT_4Hz <= r_CNT_4Hz + 1;
	end

DFF d1(r_TOGGLE_4Hz, pb, Q1);
DFF d2(r_TOGGLE_4Hz, Q1, Q2);

assign Q2_bar = ~Q2;
assign btn = Q1 & Q2_bar;

endmodule

module knight_rider_Alarm(
	input en, 
	input knight_clk,
	output [7:0] led_out
    );
     
    parameter LEDS_INIT = 10'b1100000000;
    parameter DIR_INIT = 1;
     
    reg [9:0] leds = LEDS_INIT; // register for led output
    reg [3:0] position = DIR_INIT*8; // state counter 0-15 
    reg direction = DIR_INIT;   // direction indicator


    always @ (posedge knight_clk) 
		 begin
			  if (direction == 0)
					leds <= leds << 1;  // bit-shift leds register
			  else 
					leds <= leds >> 1;  // bit-shift leds register
			  
			  position <= position + 1;
		 end
 
    always @ (*)                  // change direction 
		 begin        
			  if (position < 8)       // in the second half 
					direction = 0;
			  else 
					direction = 1;
			  
		 end
 
    assign led_out = leds[8:1]*en; // wire output and leds register
endmodule


module clock_divider(
	input fast_clock,
	output slow_clock
	);
	
	parameter COUNTER_SIZE = 24; // 2^24 times slower
	parameter COUNTER_MAX_COUNT = (2 ** COUNTER_SIZE) - 1;
	reg [COUNTER_SIZE-1:0] count;

	always @ (posedge fast_clock)
	begin
		 if(count >= COUNTER_MAX_COUNT)
			  count <= 24'b0;
		 else
			  count <= count + 1'b1;
	end

   assign slow_clock = count[COUNTER_SIZE-1];
endmodule

