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
	 
    output reg [7:0] seg,   //output 0->6 = seg A->G ACTIVE LOW, 
									//output 7 = decimal point, all active low
	 //output reg [3:0] an,    // turn on all 4 display on the 7seg
								
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
	
	
	//internal var
	reg [3:0] LED_Counter=4'b0000; 
	//assign an =4'h0; // all 4 seven-segment display is on. h means hexadecimal
	
	reg [3:0] Digit_selector= 3'b000;
	reg [3:0] knight_rider_digit_selector= 3'b000;
	reg [3:0] dig = 4'b0000;
	
	 // all unused outputs must be assigned    VERY IMPORTANT!!!!!!
	assign vgaRed = 3'b111;
	assign vgaGreen = 3'b111;
	assign vgaBlue = 2'b11;
	assign hsync = 1'b1;
	assign vsync = 1'b1;
	 
	//assign seg = 8'b00000000;
	//assign dig = 4'b0000; //initially b1111
	 
	///////////////////////////////////////////////////////////////
	// Implement the project from here
	
	//input clock or built-in clock = 100MHz
	parameter c_CNT_1HZ   = 5000000; // blink every 1 sec = 50000000
	parameter c_CNT_2HZ   = 25000000; // blink every 0.5 sec
	
	reg [31:0] custom_clock = 50000000;

	reg [31:0] r_CNT_1HZ = 0;
	reg [31:0] r_CNT_2HZ = 0;
	
	reg  r_TOGGLE_1HZ  = 1'b0;
	reg  r_TOGGLE_2HZ  = 1'b0;
	
	
	
	
	// custom clock ///////////////////////////////////////////////////////////UNFINISHED
	
	/*
	 always @ (posedge clk_100mhz)
begin
	 
	 if (btn_left) begin
	 assign led [7] = 1'b1
	 end
	 
end
	
	*/
	
	
	
	
	//// One bit select
	reg        two_mux_out;
  
	always @ (posedge clk_100mhz)
begin
		
	 if (r_CNT_1HZ == c_CNT_1HZ-1) // -1, since counter starts at 0
	 begin        
	 r_TOGGLE_1HZ <= !r_TOGGLE_1HZ; // if counter reach value, then toggle it on
	 r_CNT_1HZ    <= 0;   				// reset the clock
	 end
	 
	 else
		  r_CNT_1HZ <= r_CNT_1HZ + 1;   
end
	 
	 
	always @ (posedge clk_100mhz)
begin
		if (r_CNT_2HZ == c_CNT_2HZ-1) // -1, since counter starts at 0
		  begin        
			 r_TOGGLE_2HZ <= !r_TOGGLE_2HZ;
			 r_CNT_2HZ    <= 0;
		  end
		else
		  r_CNT_2HZ <= r_CNT_2HZ + 1;
end
	
	always @ (*)
begin
		case(switch[0])
			1'b0: two_mux_out <= r_TOGGLE_1HZ;
			1'b1: two_mux_out <= r_TOGGLE_2HZ;
		endcase
end
	 
	assign led[6:1] = 6'b000000; //originally led 7:1 and 7 bit, led 7 not assigned
	
	//assign led[0] = 1'b1 & switch[1];
   assign led[0] = two_mux_out & switch[1];
	
	
	//assign led[7] = switch[7];



// led counter test
	always @ (posedge two_mux_out)
	if (switch[7]) begin
	begin
	
	if (LED_Counter == 6) begin
		LED_Counter <= 0;
		end
	
	else begin
	LED_Counter <= LED_Counter + 1'b1;
	end
	end
	end


// 7seg scroller digit selector addition
	always @ (posedge two_mux_out)
	if (switch[6]) begin
	begin
	
	if (LED_Counter == 6) begin
		Digit_selector <= Digit_selector + 1;
		
	if (Digit_selector == 8) begin
		Digit_selector <= 0;
	end
		end
		end
		end
		
// 7seg scroller digit selector // this selects which figure 8 on the led board is active
	always @(posedge two_mux_out)
	if (switch[6]) begin
	case(Digit_selector)
	3'b000 : dig = 4'b0001;  //0
	3'b001 : dig = 4'b0010;  //1
	3'b010 : dig = 4'b0100;  //2
	3'b011 : dig = 4'b1000;  //3
	3'b100 : dig = 4'b0111;  //4
	3'b101 : dig = 4'b1011;  //5
	3'b110 : dig = 4'b1101;  //6
	3'b111 : dig = 4'b1110;  //7
	
	endcase
	end

// 7seg display scroller
	always @(posedge two_mux_out)
	
	if (switch[7]) begin
	case(LED_Counter)
	
	4'b0000 : seg = 8'b11111110;        //0
	
	4'b0001 : begin							//1
	seg = 8'b11111101;
	end    										// another way of writing case syntax
	
	4'b0010 : seg = 8'b11111011;			//2
	4'b0011 : seg = 8'b11110111;			//3
	4'b0100 : seg = 8'b11101111;			//4
	4'b0101 : seg = 8'b11011111;			//5
	4'b0110 : seg = 8'b11111110;			//6
	endcase
	end


	



/*
// 7 seg to say grp 3

	always @(posedge clk_100mhz)
	
	if (switch[5]) begin
	assign dig = 4'b1110;
	assign seg = 8'b01011110;
	
	
	end
	*/


/*
// knight rider 7seg
module knightrider (
    input clk_100mhz,
    input [7:0] switch,
	 
    input btn_up,       // buttons, depress = high
    input btn_enter,
    input btn_left,
    input btn_down,
    input btn_right,
	 
    output reg [7:0] seg,   //output 0->6 = seg A->G ACTIVE LOW, 
									//output 7 = decimal point, all active low
	 //output reg [3:0] an,    // turn on all 4 display on the 7seg
								
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

	always @ (posedge r_TOGGLE_1HZ)
	if (switch[5]) begin
	begin
	
	if (LED_Counter == 6) begin
		knight_rider_digit_selector <= knight_rider_digit_selector + 1;
		
	if (knight_rider_digit_selector == 8) begin
		knight_rider_digit_selector <= 0;
	end
		end
		end
		end
		
// 7seg scroller digit selector // this selects which figure 8 on the led board is active
	always @(posedge r_TOGGLE_1HZ)
	if (switch[4]) begin
	case(knight_rider_digit_selector)
	3'b000 : dig = 4'b0001;  //0
	3'b001 : dig = 4'b0010;  //1
	3'b010 : dig = 4'b0100;  //2
	3'b011 : dig = 4'b1000;  //3
	3'b100 : dig = 4'b0111;  //4
	3'b101 : dig = 4'b1011;  //5
	3'b110 : dig = 4'b1101;  //6
	3'b111 : dig = 4'b1110;  //7
	
	endcase
	end



*/

	assign led[7] = LED_Counter;
	
	
	
 
endmodule
