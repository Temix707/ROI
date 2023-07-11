`timescale 1ns / 1ps

class trans; 
  rand bit [7:0] pixel;

  // Randomization of data //
  function automatic logic [7:0] random_val( logic [7:0] pixel); 
    this.pixel = pixel;  
    return this.pixel;
  endfunction

  // Print data //
  function automatic logic [7:0] print( logic [7:0] tdata_i );
    $display("Incoming Pixel = %0d", tdata_i);
  endfunction

endclass


module roi_top_tb
#(
  parameter               WIDTH       = 800,
                          HEIGHT      = 600,   

                          AXIS_DATA_W = 8,
                          APB_DATA_W  = 32, 
                          APB_ADDR_W  = 12,

                          SUM_PIX     = ( ( WIDTH ) * ( HEIGHT ) )  // (HEIGHT * WIDTH) == 480_000 
)();

  logic                   clk_i;
  logic                   arst_i;

  // AXIS
  logic [AXIS_DATA_W-1:0] tdata_i;                  
  logic                   tvalid_i;                 
  logic                   tlast_i;                  

  logic [AXIS_DATA_W-1:0] tdata_o;               
  logic                   tvalid_o;                
  logic                   tlast_o;  

  // APB
  logic [APB_DATA_W-1:0]  apb_pwdata_i;
  logic [APB_ADDR_W-1:0]  apb_paddr_i;

  logic                   apb_pwrite_i;
  logic                   apb_psel_i;
  logic                   apb_penable_i;     

  logic                   apb_pready_o;                   
  logic [APB_DATA_W-1:0]  apb_prdata_o;


  roi_top
  DUT_ROI ( 
    .clk_i          ( clk_i         ),
    .arst_i         ( arst_i        ),

    // AXIS
    .tdata_i        ( tdata_i       ),
    .tvalid_i       ( tvalid_i      ),
    .tlast_i        ( tlast_i       ),

    .tdata_o        ( tdata_o       ),
    .tvalid_o       ( tvalid_o      ),
    .tlast_o        ( tlast_o       ),

    // APB
    .apb_pwdata_i   ( apb_pwdata_i  ),
    .apb_paddr_i    ( apb_paddr_i   ),

    .apb_pwrite_i   ( apb_pwrite_i  ),
    .apb_psel_i     ( apb_psel_i    ),
    .apb_penable_i  ( apb_penable_i ),     

    .apb_pready_o   ( apb_pready_o  ),                   
    .apb_prdata_o   ( apb_prdata_o  )
  );



  ///////////
  // TASKS //
  ///////////

  // Write transfer //
  task automatic exec_apb_write_trans(
    input logic [APB_ADDR_W-1:0] paddr,
    input logic [APB_DATA_W-1:0] pwdata
  );
    // Address phase
    apb_paddr_i   <= paddr;
    apb_pwrite_i  <= 1'b1;
    apb_psel_i    <= 1'b1;
    apb_pwdata_i  <= pwdata;

    // Data phase
    @( posedge clk_i );
    apb_penable_i <= 1'b1;
    
    do begin
      @( posedge clk_i );
    end while( !apb_pready_o ); 

    // Unset penable
    apb_penable_i <= 1'b0;
    apb_psel_i    <= 1'b0;
    apb_pwdata_i  <= 32'd0;
  endtask



    // Read transfer  //
  task automatic exec_apb_read_trans(
      input  logic [APB_ADDR_W-1:0] paddr,
      output logic [APB_DATA_W-1:0] prdata
  );
    // Address phase
    apb_paddr_i   <= paddr;
    apb_psel_i    <= 1'b1;
    apb_pwrite_i  <= 1'b0;

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
    apb_psel_i    <= 1'b0;
  endtask



  /////////////////////////////////
  /////////////////////////////////
  /////////////////////////////////


  localparam ADDR_XY_0 = 12'h0;
  localparam ADDR_XY_1 = 12'h4;


  logic [APB_DATA_W-1:0] prdata;

  // Coordinate buffers
  logic [9:0] x0, y0;
  logic [9:0] x1, y1;


  logic cnt_sel_xy_0;
  logic cnt_sel_xy_1;

  //////////////
  // Stimulus //
  ////////////// 

  // CLK
  initial begin
    clk_i  = '0;
    forever #10 clk_i  = ~clk_i;
  end


  trans pkt;

  initial begin 
    pkt = new();

    tlast_i             = 0;
    tvalid_i            = 0;

    // RESET 
    arst_i = '1;
    repeat (2)  @ ( posedge clk_i );
    arst_i = '0;


    //////////////////////
    //  Write transfer  //
    //////////////////////

    // First image
    // 1st coordinates xy0
    exec_apb_write_trans( 12'h0, { 6'd0, 10'd400, 6'd0, 10'd300 } );  // [26:16] x0, [9:0] y0  (400, 300)

    // 1st coordinates xy1
    repeat (1)  @ ( posedge clk_i );
    exec_apb_write_trans( 12'h4, { 6'd0, 10'd600, 6'd0, 10'd400 } );  // [26:16] x1, [9:0] y1  (600, 400)

    repeat (1)  @ ( posedge clk_i );
    tvalid_i            = 1;



    ////////////////////////////////
    //  Read transfer first image //
    ////////////////////////////////
  
    repeat (3)  @ ( posedge clk_i );
    exec_apb_read_trans( 12'h0, prdata );

    repeat (3)  @ ( posedge clk_i );
    exec_apb_read_trans( 12'h4, prdata );



    //////////////////////
    //  Write transfer  //
    //////////////////////

    // Second image //
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );

    // 2nd coordinates xy0
    exec_apb_write_trans( 12'h0, { 6'd0, 10'd200, 6'd0, 10'd200 } );  // [26:16] x0, [9:0] y0  (200, 200)

    // 2nd coordinates xy1
    repeat (1)  @ ( posedge clk_i );
    exec_apb_write_trans( 12'h4, { 6'd0, 10'd600, 6'd0, 10'd400 } );  // [26:16] x1, [9:0] y1  (600, 400)

    repeat (1)  @ ( posedge clk_i );
    tvalid_i            = 1;



    //////////////////////////////////
    //  Read transfer second image  //
    //////////////////////////////////
    
    repeat (3)  @ ( posedge clk_i );
    exec_apb_read_trans( 12'h0, prdata );

    repeat (3)  @ ( posedge clk_i );
    exec_apb_read_trans( 12'h4, prdata );



    //////////////////////
    //  Write transfer  //
    //////////////////////

    // Third image //
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );

    // 3rd coordinates xy0
    exec_apb_write_trans( 12'h0, { 6'd0, 10'd1, 6'd0, 10'd1 } );      // [26:16] x0, [9:0] y0  (1,1)

    // 3rd coordinates xy1
    repeat (1)  @ ( posedge clk_i );
    exec_apb_write_trans( 12'h4, { 6'd0, 10'd800, 6'd0, 10'd600 } );  // [26:16] x1, [9:0] y1  (800, 600)

    repeat (1)  @ ( posedge clk_i );
    tvalid_i            = 1;



    // Fourth image //
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );

    // 4th coordinates xy0
    exec_apb_write_trans( 12'h0, { 6'd0, 10'd300, 6'd0, 10'd200 } );  // [26:16] x0, [9:0] y0  (300, 200)

    // 4th coordinates xy1
    repeat (1)  @ ( posedge clk_i );
    exec_apb_write_trans( 12'h4, { 6'd0, 10'd100, 6'd0, 10'd400 } );  // [26:16] x1, [9:0] y1  (100, 400)

    repeat (1)  @ ( posedge clk_i );
    tvalid_i            = 1;



    // Fifth image //
    repeat ( (WIDTH * HEIGHT) + 10000 ) @ ( posedge clk_i );

    // 5th coordinates xy0
    exec_apb_write_trans( 12'h0, { 6'd0, 10'd200, 6'd0, 10'd300 } );  // [26:16] x0, [9:0] y0  (200,300)

    // 5th coordinates xy1
    repeat (1)  @ ( posedge clk_i );
    exec_apb_write_trans( 12'h4, { 6'd0, 10'd900, 6'd0, 10'd700 } );  // [26:16] x1, [9:0] y1  (900, 700) - invalid coordinates

    repeat (1)  @ ( posedge clk_i );
    tvalid_i            = 1;

    repeat ( 100000 ) @ ( posedge clk_i );
    $finish;


  end



  ////////////////////////////////
  //// Randomization of data  ////
  ////////////////////////////////

  always_ff @( posedge clk_i ) begin
    if( ( tvalid_i && !tlast_i ) || ( tvalid_i && tlast_i ) ) begin
      pkt.randomize();
      tdata_i = pkt.random_val( pkt.pixel ); 
      // pkt.print( tdata_i );
    end
    else begin
      tdata_i = 0;
    end
  end



  ////////////////////////////////
  ////      APB data in       ////
  ////////////////////////////////

  assign cnt_sel_xy_0 = 0;
  assign cnt_sel_xy_1 = 0;

  always_comb begin
    if( (( apb_paddr_i == ADDR_XY_0 ) && !( cnt_sel_xy_0 )) ) begin
      x0 = apb_pwdata_i[26:16];
      y0 = apb_pwdata_i[9:0];
      cnt_sel_xy_0 = 1;
    end

    if( (( apb_paddr_i == ADDR_XY_1 ) && !( cnt_sel_xy_1 )) ) begin
      x1 = apb_pwdata_i[26:16];
      y1 = apb_pwdata_i[9:0];
      cnt_sel_xy_1 = 1;
    end

    if(  ( ( tlast_i ) )) begin
        apb_paddr_i  = 1'bx;
        cnt_sel_xy_0 = 0;
        cnt_sel_xy_1 = 0;
    end
  end

  // Small area size
  logic [APB_DATA_W - 1:0] SUM_PIX_SMALL_AREA;                       // example: 201 * 401 = 80601 

  always_comb begin
    if( x0 < x1 )  SUM_PIX_SMALL_AREA = (( ( x1 - x0 ) + 1 ) * ( ( y1 - y0 ) + 1 ));  
    else           SUM_PIX_SMALL_AREA = (( ( x0 - x1 ) + 1 ) * ( ( y1 - y0 ) + 1 ));
  end






  
  ///////////////////////////////////////////////
  ///// Queue check block for a LARGE area  /////
  ///////////////////////////////////////////////

  logic [2:0]             cnt_l_img;
         
  logic [AXIS_DATA_W-1:0] cnt_data_i_que [$];           // Queue for checking data in a large area
  
  logic                   tlast_ff;
  logic                   tvalid_ff;
  
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
        $stop();
      end
      /*else begin
        $display  ( "Not all pixels were transferred to a large area. \nInp data: %0d, \tThe amount of data recorded: %0d, \t Time: %0t \n-----------------------"
        , tdata_i, cnt_data_i_que.size(), $time );
      end  */
    end
  end






  ////////////////////////////////////////////////
  ///// A queue check block for a SMALL area /////
  ////////////////////////////////////////////////

  logic [2:0]             cnt_s_img;

  logic [AXIS_DATA_W-1:0] cnt_data_o_que [$];
  logic [AXIS_DATA_W-1:0] down_data_expected;   

  
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
        end   */

        if( cnt_data_o_que.size() == SUM_PIX_SMALL_AREA ) begin
            $display  ( "SUCCESS: ALL DATA FROM THE %0d SMALL IMAGE WAS TRANSMITTED: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
            , cnt_s_img, SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
        
            cnt_s_img = cnt_s_img + 1;
            cnt_data_o_que.delete();
            $stop();
        end
      end
    end
  end

endmodule