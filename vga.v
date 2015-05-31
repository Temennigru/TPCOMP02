module clockdiv(
	input wire clk,		//master clock: 50MHz
	output wire dclk		//pixel clock: 25MHz
	);

// 17-bit counter variable
reg [16:0] q;

// Clock divider --
// Each bit in q is a clock signal that is
// only a fraction of the master clock.
always @(posedge clk)
begin
	q <= q + 1;
end

// 50Mhz ÷ 2^1 = 25MHz
assign dclk = q[0];

endmodule
  
module vga_sync_(clk, vga_h_sync, vga_v_sync, blank, CounterX, CounterY);
	input clk;
	output vga_h_sync, vga_v_sync, blank;
	output reg[9:0] CounterX; // max: 800
	output reg[9:0] CounterY; //max: 528
	
	wire CounterXMaxed = (CounterX==10'd800);
	wire CounterYMaxed = (CounterY==10'd528);

	always @(posedge clk)
      begin
        if (CounterXMaxed) CounterX <= 0;
        else CounterX <= CounterX + 1;
        if (CounterYMaxed) CounterY <= 0;
        else if (CounterXMaxed) CounterY <= CounterY + 1;
      end
    
    reg auxHS, auxVS;
    always @(posedge clk)
       begin
         auxHS <= (CounterX > 139 && CounterX < 779);
         auxVS <= (CounterY > 33 && CounterY < 513);	
       end
         
    assign blank = (auxHS && auxVS);
    
    assign vga_h_sync = ~auxHS;
    assign vga_v_sync = ~auxVS;


endmodule

/* MAIN */

module vga(CLOCK_50, VGA_CLK, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, VGA_BLANK, VGA_SYNC, outaddr);

input CLOCK_50;
output wire VGA_HS, VGA_VS, VGA_BLANK, VGA_CLK;
output reg [9:0]VGA_R;
output reg [9:0]VGA_B;
output reg [9:0]VGA_G;
output wire VGA_SYNC = 0;

output [18:0] outaddr ;

wire CLOCK_25;
wire [9:0] CounterX;
wire [9:0] CounterY;
wire [18:0] address ;
wire PIXEL ; /* tem que usar poucos bits devido uma limitação na placa*/

clockdiv clk_50_to_25(CLOCK_50, CLOCK_25);
vga_sync_ teste(CLOCK_25, VGA_HS, VGA_VS, VGA_BLANK, CounterX, CounterY);

assign address = CounterX  + 800*CounterY;
MEM M1(address, CLOCK_25, 10'b0000000000, 0, PIXEL);

assign outaddr = address ;

assign VGA_CLK = CLOCK_25;
always @(posedge CLOCK_25) // olha se fica bom
 begin
   if (PIXEL == 1) begin
     VGA_R = 10'b1111111111;
     VGA_G = 10'b1111111111;
     VGA_B = 10'b1111111111;
  end
  else
    begin
     VGA_R = 0;
     VGA_G = 0;
     VGA_B = 0;
  	end
 end

endmodule
  