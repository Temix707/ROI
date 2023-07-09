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
  parameter               WIDTH       = 800,                 
                          HEIGHT      = 600,                 

                          BIT_DATA_O  = 8,
                          BIT_COORD   = 32, 

                          SUM_PIX     = ( ( WIDTH ) * ( HEIGHT ) )  // (HEIGHT * WIDTH) == 480_000 
)();

  logic                   clk_i;
  logic                   arst_i;

  logic [BIT_DATA_O-1:0]  tdata_i;
  logic                   tvalid_i;
  logic                   tlast_i;

  logic [BIT_COORD-1:0]   xy_0_i;
  logic [BIT_COORD-1:0]   xy_1_i;

  logic [BIT_DATA_O-1:0]  tdata_o;
  logic                   tvalid_o;
  logic                   tlast_o;


  roi_axis DUT_AXIS 
  ( 
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

  // Coordinate buffers
  logic [9:0] x0, y0;
  logic [9:0] x1, y1;

  always_comb begin
    x0 = xy_0_i[26:16];
    y0 = xy_0_i[9:0];

    x1 = xy_1_i[26:16];
    y1 = xy_1_i[9:0];
  end


  // Small area size
  logic [BIT_COORD - 1:0] SUM_PIX_SMALL_AREA;                       // example: 201 * 401 = 80601 

  always_comb begin
    if( x0 < x1 ) SUM_PIX_SMALL_AREA = (( ( x1 - x0 ) + 1 ) * ( ( y1 - y0 ) + 1 ));  
    else          SUM_PIX_SMALL_AREA = (( ( x0 - x1 ) + 1 ) * ( ( y1 - y0 ) + 1 ));
  end


  // CLK
  initial begin
    clk_i  = '0;
    forever #10 clk_i = ~clk_i;
  end

  
  trans pkt;

  initial begin
    pkt = new();
    
    // First image
    xy_0_i[31:0]  = { 6'd0, 10'd400, 6'd0, 10'd300 };               // [26:16] x0, [9:0] y0  (400, 300)
    xy_1_i[31:0]  = { 6'd0, 10'd600, 6'd0, 10'd400 };               // [26:16] x1, [9:0] y1  (600, 400)

    // RESET
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;

    tlast_i       = 0;
    tvalid_i      = 0;

    repeat (2)  @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;


    repeat (5)  @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 0;

    repeat (3)  @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;

    // Second image
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;
    xy_0_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd200 };               // [26:16] x0, [9:0] y0  (200, 200)
    xy_1_i[31:0]  = { 6'd0, 10'd600, 6'd0, 10'd400 };               // [26:16] x1, [9:0] y1  (600, 400)


    // Third image
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;
    xy_0_i[31:0]  = { 6'd0, 10'd700, 6'd0, 10'd100 };               // [26:16] x0, [9:0] y0  (700, 100)
    xy_1_i[31:0]  = { 6'd0, 10'd400, 6'd0, 10'd500 };               // [26:16] x1, [9:0] y1  (400, 500)

    // Fourth image
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;
    xy_0_i[31:0]  = { 6'd0, 10'd1, 6'd0, 10'd1     };               // [26:16] x0, [9:0] y0  (1,1)
    xy_1_i[31:0]  = { 6'd0, 10'd800, 6'd0, 10'd600 };               // [26:16] x1, [9:0] y1  (800, 600)

    // Fifth image
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 0;
    xy_0_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd300 };               // [26:16] x0, [9:0] y0  (200,300)
    xy_1_i[31:0]  = { 6'd0, 10'd900, 6'd0, 10'd700 };               // [26:16] x1, [9:0] y1  (900, 700) - invalid coordinates
  end



  ////////////////////////////////
  //// Randomization of data  ////
  ////////////////////////////////

  always_ff @( posedge clk_i ) begin
    if( (tvalid_i && !tlast_i) || (tvalid_i && tlast_i) ) begin
      pkt.randomize();
      tdata_i = pkt.random_val( pkt.pixel); 
      // pkt.print( tdata_i );
    end
    else begin
      tdata_i = 0;
    end
  end




  ///////////////////////////////////////////////
  ///// Queue check block for a LARGE area  /////
  ///////////////////////////////////////////////

  logic [2:0]               cnt_l_img;
         
  logic [BIT_DATA_O - 1:0]  cnt_data_i_que [$];           // Queue for checking data in a large area
  
  logic                     tlast_ff;
  logic                     tvalid_ff;
  
  assign tvalid_i = tvalid_ff;
  assign tlast_i  = tlast_ff;

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      cnt_data_i_que  = {};
      cnt_l_img       = 1;                                                             
    end
    else begin
      if( tvalid_i ) begin
        tvalid_ff     = 1;
        cnt_data_i_que.push_back( tdata_i );
      end

      if( cnt_data_i_que.size() == SUM_PIX ) begin
        $display  ( "SUCCESS: ALL DATA WAS RECORDED IN %0d LARGE IMAGE: \nIt should have come: %0d, \tHas come: %0d, \tTime: %0t \n"
        , cnt_l_img, SUM_PIX, cnt_data_i_que.size(), $time );
        
        cnt_l_img     = cnt_l_img + 1;
        tlast_ff      = 1;
      end
      else begin
        tlast_ff      = 0;
      end


      if( cnt_data_i_que.size() == SUM_PIX + 1 ) begin
        tvalid_ff     = 0;
        cnt_data_i_que.delete();
        //$stop();
      end
      /*else begin
        $display  ( "Not all pixels were transferred to a large area. \nInp data: %0d, \tThe amount of data recorded: %0d, \t Time: %0t \n-----------------------"
        , tdata_i, cnt_data_i_que.size(), $time );
      end*/
    end
  end






  ////////////////////////////////////////////////
  ///// A queue check block for a SMALL area /////
  ////////////////////////////////////////////////

  logic [2:0]              cnt_s_img;

  logic [BIT_DATA_O - 1:0] cnt_data_o_que [$];
  logic [BIT_DATA_O - 1:0] down_data_expected;   

  
  always_ff @( posedge clk_i or posedge arst_i) begin
    if( arst_i ) begin
      cnt_data_o_que = {};
      cnt_s_img      = 1;
    end
    else begin
      if( tvalid_o ) begin
        cnt_data_o_que.push_back( tdata_i );

        /*down_data_expected <= tdata_i;

        if( down_data_expected == tdata_o ) begin
          $display  ( "SUCCESS: The data is transmitted correctly: \nInput data to a small area: %0d, \tOutput data from a small area: %0d, \tTime: %0t\n-----------------------"
          , down_data_expected, tdata_o, $time );
        end
        else begin
          $display  ( "ERROR: The data is transmitted incorrectly: \nInput data to a small area: %0d, \tOutput data from a small area: %0d, \tTime: %0t\n-----------------------"
          , down_data_expected, tdata_o, $time );
        end*/

        if( cnt_data_o_que.size() == SUM_PIX_SMALL_AREA ) begin
            $display  ( "SUCCESS: ALL DATA FROM THE %0d SMALL IMAGE WAS TRANSMITTED: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
            , cnt_s_img, SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
        
            cnt_s_img = cnt_s_img + 1;
            cnt_data_o_que.delete();
            //$stop();
        end
      end
    end
  end

endmodule