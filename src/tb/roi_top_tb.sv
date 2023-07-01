`timescale 1ns / 1ps

class trans; 
  rand bit [7:0] pixel;

  function automatic logic [7:0] random_val( logic [7:0] pixel); 
    this.pixel = pixel;  
    return this.pixel;
  endfunction

  function automatic logic [7:0] print( logic [7:0] tdata_i );
    $display("Incoming Pixel = %0d", tdata_i);
  endfunction
endclass


module roi_top_tb
#(
  parameter                     WIDTH             = 800,
                                HEIGHT            = 600,   

                                BIT_DATA_O        = 8,
                                BIT_COORD         = 32, 

                                APB_DATA_I_WIDTH  = 64,
                                APB_ADDR_WIDTH    = 12,

                                SUM_PIX     = ( WIDTH + 1 ) * ( HEIGHT + 1 )  // Example (0...800) *  (0...600)
)();

  logic                         clk_i;
  logic                         arst_i;

  // AXIS
  logic [BIT_DATA_O-1:0]        tdata_i;                  
  logic                         tvalid_i;                 
  logic                         tlast_i;                  

  logic [BIT_DATA_O-1:0]        tdata_o;               
  logic                         tvalid_o;                
  logic                         tlast_o;  

  // APB
  logic [APB_DATA_I_WIDTH-1:0]  apb_pwdata_i;
  logic [APB_ADDR_WIDTH-1:0]    apb_paddr_i;

  logic                         apb_pwrite_i;
  logic                         apb_psel_i;


  roi_top
  DUT_ROI ( 
    .clk_i        ( clk_i         ),
    .arst_i       ( arst_i        ),

    // AXIS
    .tdata_i      ( tdata_i       ),
    .tvalid_i     ( tvalid_i      ),
    .tlast_i      ( tlast_i       ),

    .tdata_o      ( tdata_o       ),
    .tvalid_o     ( tvalid_o      ),
    .tlast_o      ( tlast_o       ),

    // APB
    .apb_pwdata_i ( apb_pwdata_i  ),
    .apb_paddr_i  ( apb_paddr_i   ),

    .apb_pwrite_i ( apb_pwrite_i  ),
    .apb_psel_i   ( apb_psel_i    )
  );


  // CLK
  initial begin
    clk_i  = '0;
    forever #10 clk_i  = ~clk_i;
  end

  // RESET
  initial begin
    arst_i = '1;
    repeat (1)  @ ( posedge clk_i );
    arst_i = '0;
  end

  // APB
  initial begin
    apb_psel_i          = 1;
    apb_pwrite_i        = 1;

    apb_paddr_i         = 12'h0;
  end



  // AXIS
  // Coordinate buffers
  logic [9:0] x0, y0;
  logic [9:0] x1, y1;

  trans pkt;

  initial begin 
    pkt = new();

    tlast_i             = 0;
    tvalid_i            = 1;

    apb_pwdata_i[31:0]  = { 6'd0, 10'd200, 6'd0, 10'd200 };     // [26:16] x0, [9:0] y0  (200,200)
    apb_pwdata_i[63:32] = { 6'd0, 10'd600, 6'd0, 10'd400 };     // [26:16] x1, [9:0] y1  (600,400)

    x0                  = apb_pwdata_i[25:16];
    y0                  = apb_pwdata_i[9:0];

    x1                  = apb_pwdata_i[57:48];
    y1                  = apb_pwdata_i[41:32];

    repeat ( (( HEIGHT + 1 ) * ( WIDTH + 1 )) + 2 ) @ ( posedge clk_i );
    tlast_i             = 1;
  end

  
  ////////////////////////////////
  //// Randomization of data  ////
  ////////////////////////////////
  
  always_ff @( posedge clk_i ) begin
    if( tvalid_i && !tlast_i ) begin
      pkt.randomize();
      tdata_i <= pkt.random_val( pkt.pixel);
      // pkt.print( tdata_i );
    end
    else begin
      tdata_i <= 0;
    end
  end
  ////////////////////////////////




  ////////////////////////////////////////////////
  ///// Queue check block for a large area  //////
  ////////////////////////////////////////////////

  logic [BIT_DATA_O - 1:0] data_i_que [$];                      // Queue for checking data in a large area      
  
  logic [1:0]         cnt_delay;                                // Input data delay counter

  
  always_ff @( posedge clk_i or posedge arst_i) begin
    if( arst_i ) begin
      data_i_que  = {};                         
      cnt_delay = 0;                                      
    end
    else begin
      if( tvalid_i ) begin
        data_i_que.push_back ( tdata_i );
      end

      // Avoid delays with the first data received (2 cycles)
      if( !(cnt_delay == 1) ) begin
        if( data_i_que.size() == 3 ) begin
          data_i_que.delete();
          cnt_delay = cnt_delay + 1;
        end
      end      
      
      if( data_i_que.size() == SUM_PIX ) begin
        $display  ( "ALL DATA WAS RECORDED OVER A LARGE AREA: \nIt should have come: %0d, \t Has come: %0d, \t Time: %0t \n"
        , SUM_PIX, data_i_que.size(), $time );
      end
      else if( data_i_que.size() == 0 ) begin
        $display  ( "There are no transmitted pixels" );
      end
      else if( data_i_que.size() > SUM_PIX ) begin
        $display  ( "All pixels have already been transferred" );
      end
      else begin
        $display  ( "Not all pixels were transferred to a large area. \nInp data: %0d, \t The amount of data that has been recorded: %0d, \t Time: %0t \n-----------------------"
                  , tdata_i, data_i_que.size(), $time );
      end
    end
  end
  ////////////////////////////////////////////////  
  




  ////////////////////////////////////////////////
  ///// A queue check block for a small area /////
  ////////////////////////////////////////////////

  logic [BIT_DATA_O - 1:0] data_o_que [$];                      // Queue for receiving and displaying data
  logic [BIT_DATA_O - 1:0] cnt_data_o_que [$];                  // Queue for counting the amount of data issued from a small area

  logic [BIT_DATA_O - 1:0] down_data_expected;   

  // Small area size
  logic [BIT_COORD - 1:0] SUM_PIX_SMALL_AREA;
  assign SUM_PIX_SMALL_AREA = (( x1 - x0 + 1) * ( y1 - y0 + 1));

  
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

      if( down_data_expected == tdata_o ) begin
        $display  ( "SUCCESS: The data is transmitted correctly: \nThe data is not transmitted correctly: %0d, \tOutput data from a small area: %0d, \tTime: %0t\n-----------------------"
        , down_data_expected, tdata_o, $time );

        if( cnt_data_o_que.size() == SUM_PIX_SMALL_AREA ) begin
            $display  ( "SUCCESS: ALL DATA FROM A SMALL AREA WAS TRANSMITTED: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
            , SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
        end
        else begin
          $display  ( "ERROR: Not all data from a small area was transmitted: \nIt should have come: %0d, Has come: %0d, \tTime: %0t \n-----------------------"
          , SUM_PIX_SMALL_AREA, cnt_data_o_que.size() , $time );
        end
      end
      else begin
        $display  ( "ERROR: Small area not found. \nThe data is not transmitted correctly: \nInput data for a small area: %0d, \tOutput data for a small area: %0d, \tTime: %0t\n-----------------------"
        , down_data_expected, tdata_o, $time );
      end

    end
  end
  ////////////////////////////////////////////////

endmodule
