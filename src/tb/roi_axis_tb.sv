`timescale 1ns / 1ps

class trans; 
  rand bit [7:0]                            pixel;

  function automatic logic [7:0] random_val( logic [7:0] pixel); 
    this.pixel = pixel;  
    return this.pixel;
  endfunction

  function automatic logic [7:0] print( logic [7:0] tdata_i );
    $display("Incoming Pixel = %0d", tdata_i);
  endfunction
endclass

module roi_axis_tb
#(
  parameter               WIDTH  = 800,                 
                          HEIGHT = 600,                 

                          BIT_D  = 8,
                          BIT_C  = 32
)();

  logic                   clk_i;
  logic                   arst_i;

  logic       [BIT_D-1:0] tdata_i;
  logic                   tvalid_i;
  logic                   tlast_i;

  logic       [BIT_C-1:0] xy_0_i;
  logic       [BIT_C-1:0] xy_1_i;

  logic       [BIT_D-1:0] tdata_o;
  logic                   tvalid_o;
  logic                   tlast_o;


  roi_axis  
  # ( WIDTH, HEIGHT, BIT_D, BIT_C )
  DUT ( 
    .clk_i    ( clk_i     ),
    .arst_i   ( arst_i    ),

    .tdata_i  ( tdata_i   ),
    .tvalid_i ( tvalid_i  ),
    .tlast_i  ( tlast_i   ),

    .xy_0_i   ( xy_0_i    ),
    .xy_1_i   ( xy_1_i    ),

    .tdata_o  ( tdata_o   ),
    .tvalid_o ( tvalid_o  ),
    .tlast_o  ( tlast_o   )
  );


  initial begin
    clk_i  = '0;
    forever #10 clk_i  = ~clk_i;
  end

  initial begin
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;
  end

  trans pkt;

  initial begin 
    pkt = new();
    $display("Start of data submission");

    tlast_i   = 0;
    tvalid_i  = 1;

    // Set coordinates to points
    xy_0_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd200};    // [26:16] x0, [9:0] y0
    xy_1_i[31:0]  = { 6'd0, 10'd600, 6'd0, 10'd400};    // [26:16] x1, [9:0] y1

  end



  // Randomization of data
  always_ff @( posedge clk_i ) begin
    //if( tvalid_i ) begin
      pkt.randomize();
      tdata_i <= pkt.random_val( pkt.pixel); 
      pkt.print( tdata_i );
    //end
    //else begin
      //tdata_i <= 0;
    //end
  end


endmodule









/*

  always_ff @( posedge clk_i ) begin
    if( cnt_q_pxl == ( HEIGHT * WIDTH ) ) begin
      tlast_i <= 1;
    end
    else begin
      tlast_i <= 0;
    end
  end

  // Validity of data in a large area
  always_ff @( posedge clk_i ) begin
    if( tlast_i ) begin
      tvalid_i <= 0;
    end
    else begin
      tvalid_i = 1;
    end
  end

  // Randomization of data
  always_ff @( posedge clk_i ) begin
    if( tvalid_i ) begin
      pkt.randomize();
      tdata_i <= pkt.random_val( pkt.pixel); 
      pkt.print( tdata_i );
    end
    else begin
      tdata_i <= 0;
    end
  end

  // Adding a counter
  always_ff @( posedge clk_i ) begin
    if( tvalid_i ) begin
      cnt_q_pxl <= cnt_q_pxl + 1;
    end
  end

*/
