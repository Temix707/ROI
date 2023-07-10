`timescale 1ns / 1ps

module roi_apb_tb
#(
  parameter                     APB_DATA_W = 32,
                                APB_ADDR_W = 12     // APB slaves are 4KB by default 
)();

  logic                   clk_i;
  logic                   arst_i;

  logic [APB_DATA_W-1:0]  apb_pwdata_i;                
  logic [APB_ADDR_W-1:0]  apb_paddr_i;                  
  
  logic                   apb_pwrite_i;            
  logic                   apb_psel_i;
  logic                   apb_penable_i;  //   

  logic  [APB_DATA_W-1:0] apb_prdata_o;   //
  logic                   apb_pready_o;   //                

  logic  [APB_DATA_W-1:0] xy_0_o;
  logic  [APB_DATA_W-1:0] xy_1_o;



  roi_apb DUT_APB 
  (
    .clk_i          ( clk_i         ),
    .arst_i         ( arst_i        ),

    .apb_pwdata_i   ( apb_pwdata_i  ),
    .apb_paddr_i    ( apb_paddr_i   ),

    .apb_pwrite_i   ( apb_pwrite_i  ),
    .apb_psel_i     ( apb_psel_i    ),
    .apb_penable_i  ( apb_penable_i ),

    .apb_prdata_o   ( apb_prdata_o  ),
    .apb_pready_o   ( apb_pready_o  ),


    .xy_0_o         ( xy_0_o        ),
    .xy_1_o         ( xy_1_o        )
  );




  ///////////
  // TASKS //
  ///////////


  //  Write transfer  //

  task automatic exec_apb_write_trans(
    input logic [APB_ADDR_W-1:0] paddr,
    input logic [APB_DATA_W-1:0] pwdata
  );
    // Address phase
    apb_paddr_i   <= paddr;
    apb_psel_i    <= 1'b1;
    apb_pwrite_i  <= 1'b1;
    apb_pwdata_i  <= pwdata;

    // Data phase
    @( posedge clk_i );
    apb_penable_i <= 1'b1;
    
    do begin
      @( posedge clk_i );
    end while( !apb_pready_o ); 

    // Unset penable
    apb_penable_i <= 1'b0;
  endtask



  // Read transfer  //

  task automatic exec_apb_read_trans(
      input  bit [31:0] paddr,
      output bit [31:0] prdata
  );
    // Address phase
    apb_paddr_i  <= paddr;
    apb_psel_i   <= 1'b1;
    apb_pwrite_i <= 1'b0;

    // Data phase
    @( posedge clk_i );
    apb_penable_i <= 1'b1;

    do begin
      @( posedge clk_i );
    end while( !apb_pready_o ); 

    // Save data
    prdata = apb_prdata_o;
    // Unset penable
    apb_penable_i <= 1'b0;
  endtask










   // CLK
  initial begin
    clk_i  = '0;
    forever #10 clk_i  = ~clk_i;
  end


  initial begin
   // RESET 
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;

    exec_apb_write_trans( 12'h0, { 6'd0, 10'd200, 6'd0, 10'd200 } );



    repeat (20)  @ ( posedge clk_i );
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;

    exec_apb_write_trans( 12'h0, { 6'd0, 10'd400, 6'd0, 10'd200 } );
  end






endmodule














/*
  initial begin
    /*apb_psel_i          = 1;
    apb_pwrite_i        = 1;

    apb_paddr_i         = 12'h0;

    apb_pwdata_i[31:0]  <= { 6'd0, 10'd200, 6'd0, 10'd200 };    
    //apb_pwdata_i[63:32] = { 6'd0, 10'd600, 6'd0, 10'd400 };
  end*/