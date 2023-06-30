`timescale 1ns / 1ps

module roi_apb_tb
#(
  parameter                     APB_DATA_I_WIDTH = 64,
                                APB_DATA_O_WIDTH = 32,

                                APB_ADDR_WIDTH = 12     // APB slaves are 4KB by default 
)();

  logic                         clk_i;
  logic                         arst_i;

  logic [APB_DATA_I_WIDTH-1:0]  apb_pwdata_i;     
  logic [APB_ADDR_WIDTH-1:0]    apb_paddr_i;          
  
  logic                         apb_pwrite_i;         
  logic                         apb_psel_i;           

  logic [APB_DATA_O_WIDTH-1:0]  xy_0_o;
  logic [APB_DATA_O_WIDTH-1:0]  xy_1_o;


  roi_apb 
  # ( APB_DATA_I_WIDTH, APB_DATA_O_WIDTH, APB_ADDR_WIDTH )
  APB_ROI (
    .clk_i        ( clk_i         ),
    .arst_i       ( arst_i        ),

    .apb_pwdata_i ( apb_pwdata_i  ),
    .apb_paddr_i  ( apb_paddr_i   ),

    .apb_pwrite_i ( apb_pwrite_i  ),
    .apb_psel_i   ( apb_psel_i    ),

    .xy_0_o       ( xy_0_o        ),
    .xy_1_o       ( xy_1_o        )
  );


   // CLK
  initial begin
    clk_i  = '0;
    forever #10 clk_i  = ~clk_i;
  end


// RESET
  initial begin
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;
    repeat (20)  @ ( posedge clk_i );
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;
  end


  initial begin
    apb_psel_i   = 1;
    apb_pwrite_i = 1;

    apb_paddr_i = 12'h0;

    apb_pwdata_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd200 };    
    apb_pwdata_i[63:32] = { 6'd0, 10'd600, 6'd0, 10'd400 };
  end



endmodule
