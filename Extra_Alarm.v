
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//lab2.2
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
	assign vgaRed = 3'b111;
	assign vgaGreen = 3'b111;
	assign vgaBlue = 2'b11;
	assign hsync = 1'b1;
	assign vsync = 1'b1;
	 
	assign seg = 8'b11111111;
	assign dig = 4'b1111;

    // all unused outputs must be assigned    VERY IMPORTANT!!!!!!
	parameter c_CNT_1sec  = 100000000; //number of clocks for 1 second with 100MHz clock
	reg [31:0] r_CNT_1sec = 0;
	reg [31:0] countdown_Num = 10;    //counting number to be displayed
	reg [31:0] countdown_Store = 0;
	reg trigger_alarm = 1'b0;
	 // 1 second clock counting down
	always @ (posedge clk_100mhz)
	begin
		if (r_CNT_1sec == c_CNT_1sec-1) // -1, since counter starts at 0
			begin        
				 if(countdown_Store < countdown_Num)
					begin
						//trigger_alarm <= 1'b0;
						countdown_Store <= countdown_Store + 1;
					end
				 else
					begin
						countdown_Store <= 0;
						countdown_Num <= 0;
						//trigger_alarm <= 1'b1;
					end
				 r_CNT_1sec <= 0;
			end
		else
			begin
				//trigger_alarm <= 1'b0;
				r_CNT_1sec <= r_CNT_1sec + 1;
			end
	end

	always @ (*)
		begin
			case(countdown_Store)
				32'b0:
					begin
						if (countdown_Num != 0 && trigger_alarm == 1)
							trigger_alarm <= 0;
					end
					
				default: trigger_alarm <= 1;
			endcase
		end
	//

	clock_divider u0(.fast_clock(clk_100mhz), .slow_clock(slow_clock));
	knight_rider_Alarm krA_1(!trigger_alarm * switch[2], slow_clock, led[7:0]);
	//assign led[0] = !trigger_alarm;
 
endmodule

module alarm(
	input en, 
	input clk, 
	input cnt_Keeper,
	input time_Up,
	output reg flag);
	
	always @ (posedge clk)
	begin
		if(en == 0)
			flag <= 1'b0;
		else if(cnt_Keeper == time_Up)
			flag <=1;
		else 
		   flag <=0;
   end	
	
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