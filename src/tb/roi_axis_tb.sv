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
  end


  // Set coordinates to points 
  initial begin                                   
    xy_0_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd200 };    // [26:16] x0, [9:0] y0  (200,200)
    xy_1_i[31:0]  = { 6'd0, 10'd600, 6'd0, 10'd400 };    // [26:16] x1, [9:0] y1  (600,400)

    x0            = xy_0_i[26:16];
    y0            = xy_0_i[9:0];

    x1            = xy_1_i[26:16];
    y1            = xy_1_i[9:0];
  end





  trans pkt;

  initial begin 
    pkt = new();

    repeat (2)  @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 0;

    repeat (2)  @ ( posedge clk_i );
    tlast_i       = 0;
    tvalid_i      = 1;

  end





  // Small area size
  logic [BIT_COORD - 1:0] SUM_PIX_SMALL_AREA;
  assign SUM_PIX_SMALL_AREA = (( x1 - x0 + 1) * ( y1 - y0 + 1));  // 201 * 401 = 80601 values => 0...80600




  //// Randomization of data  ////
  always_ff @( posedge clk_i ) begin
    if( tvalid_i && !tlast_i ) begin
      pkt.randomize();
      tdata_i = pkt.random_val( pkt.pixel); 
      // pkt.print( tdata_i );
    end
    else begin
      tdata_i = 0;
    end
  end



  logic [BIT_DATA_O-1:0]    data_ff_1, data_ff_2, data_ff_3;
  logic [BIT_DATA_O - 1:0]  data_show;

  logic                     tlast_ff;
  logic                     tvalid_ff;


  logic [BIT_DATA_O - 1:0]  data_i_que     [$];       // Queue for checking data in a large area   
  logic [BIT_DATA_O - 1:0]  cnt_data_i_que [$]; 
  
  logic [1:0]               cnt_delay;                // Input data delay counter


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      cnt_data_i_que  = {};                         
      cnt_delay       = 0;                                      
    end
    else begin
      
      if( tvalid_i ) begin
        data_ff_1   <= tdata_i;
        data_ff_2   <= data_ff_1;
        data_ff_3   <= data_ff_2;
        cnt_data_i_que.push_back( data_ff_3 );
      end

      // Avoid delays with the first data received (2 cycles)
      if( !(cnt_delay == 1) ) begin
        if( cnt_data_i_que.size() == 2 ) begin
          cnt_data_i_que.delete();
          cnt_delay = cnt_delay + 1;
        end
      end 

      if( cnt_data_i_que.size() == SUM_PIX ) begin
        $display  ( "ALL DATA WAS RECORDED OVER A LARGE AREA: \nIt should have come: %0d, \t Has come: %0d, \t Time: %0t \n"
        , SUM_PIX, cnt_data_i_que.size(), $time );
        
        tvalid_ff = 0;
        tlast_ff  = 1;
        $stop();
      end
      else begin
        $display  ( "Not all pixels were transferred to a large area. \nInp data: %0d, \tThe amount of data recorded: %0d, \t Time: %0t \n-----------------------"
        , data_ff_2, cnt_data_i_que.size(), $time );
      end

    end
  end

  assign tvalid_i = tvalid_ff;
  assign tlast_i  = tlast_ff;



/*
  ///// Queue check block for a large area  /////
  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      data_i_que  = {};                         
      cnt_delay   = 0;                                      
    end
    else begin
      if( tvalid_i ) begin
        data_i_que.push_back( tdata_i );
      end

      // Avoid delays with the first data received (2 cycles)
      if( !(cnt_delay == 1) ) begin
        if( data_i_que.size() == 2 ) begin
          data_i_que.delete();
          cnt_delay = cnt_delay + 1;
        end
      end      
      
      if( data_i_que.size() == SUM_PIX ) begin
        $display  ( "ALL DATA WAS RECORDED OVER A LARGE AREA: \nIt should have come: %0d, \t Has come: %0d, \t Time: %0t \n"
        , SUM_PIX, data_i_que.size(), $time );
        //$stop();
      end
      else if( data_i_que.size() == 0 ) begin
        $display  ( "There are no transmitted pixels" );
      end
      else if( data_i_que.size() > SUM_PIX ) begin
        $display  ( "All pixels have already been transferred" );
      end
      else begin
        $display  ( "Not all pixels were transferred to a large area. \nInp data: %0d, \tThe amount of data recorded: %0d, \t Time: %0t \n-----------------------"
                  , tdata_i, data_i_que.size(), $time );
      end
      
    end
  end
  ////////////////////////////////////////////////  
*/






  ///// A queue check block for a small area /////
  logic [BIT_DATA_O - 1:0] data_o_que [$];
  logic [BIT_DATA_O - 1:0] cnt_data_o_que [$];

  logic [BIT_DATA_O - 1:0] down_data_expected;   

  
  always_ff @( posedge clk_i or posedge arst_i) begin
    if( arst_i ) begin
      data_o_que      = {}; 
      cnt_data_o_que  = {};
    end
    else begin

      if( tvalid_o ) begin
        cnt_data_o_que.push_back(tdata_i);

        data_o_que.push_back(tdata_i);
        down_data_expected <= data_o_que.pop_back();
      end

     /* if( down_data_expected == tdata_o ) begin
        $display  ( "SUCCESS: The data is transmitted correctly: \nThe data is not transmitted correctly: %0d, \tOutput data from a small area: %0d, \tTime: %0t\n-----------------------"
        , down_data_expected, tdata_o, $time );*/

        if( cnt_data_o_que.size() == SUM_PIX_SMALL_AREA ) begin
            $display  ( "SUCCESS: ALL DATA FROM A SMALL AREA WAS TRANSMITTED: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
            , SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
            cnt_data_o_que.delete();
            //$stop();
        end
        /*else begin
          $display  ( "ERROR: Not all data from a small area was transmitted: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
          , SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
        end*/
     // end
     /* else begin
        $display  ( "ERROR: Small area not found. \nThe data is not transmitted correctly: \nInput data for a small area: %0d, \tOutput data for a small area: %0d, \tTime: %0t\n-----------------------"
        , down_data_expected, tdata_o, $time );
      end*/

    end
  end
  ////////////////////////////////////////////////




endmodule