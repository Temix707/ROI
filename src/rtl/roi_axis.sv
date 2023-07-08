module roi_axis
#(
  parameter                       WIDTH       = 800,                                  
                                  HEIGHT      = 600,                   

                                  BIT_DATA_O  = 8,
                                  BIT_COORD   = 32
)
(
  input   logic                   clk_i,
  input   logic                   arst_i,

  input   logic [BIT_DATA_O-1:0]  tdata_i,                                //  incoming pixels in a large area
  input   logic                   tvalid_i,                               //  signal of readiness for data transfer to a large area
  input   logic                   tlast_i,                                //  signal signaling the last piece of data of a large area

  input   logic [BIT_COORD-1:0]   xy_0_i,                                 //  x0[26:16] y0[9:0]  the register responsible for the coordinate of the first point
  input   logic [BIT_COORD-1:0]   xy_1_i,                                 //  x1[26:16] y1[9:0]  the register responsible for the coordinate of the second point

  output  logic [BIT_DATA_O-1:0]  tdata_o,                                //  exiting pixels from a small area
  output  logic                   tvalid_o,                               //  signal of readiness for data transmission from a small area
  output  logic                   tlast_o                                 //  signal signaling the last piece of data of a small area
);


  localparam X0_L = 0;
  localparam X0_R = 1;

  logic [$clog2( HEIGHT * WIDTH )-1:0]  cnt_quan_pxl;                     //  data quantity counter (log2 (480000) = 19 bit)

  logic [$clog2( WIDTH  )-1:0]          cnt_last_val;

  //  X (width) and Y (height) coordinate counters for a LARGE area
  logic [$clog2( WIDTH  )-1:0]          cnt_l_x;
  logic [$clog2( HEIGHT )-1:0]          cnt_l_y;

  // X (width) and Y (height) coordinate counters for a SMALL area (to check) and also counts all pixels in a small area
  logic [$clog2( HEIGHT * WIDTH )-1:0]  cnt_s_x_pxl;
  //logic [$clog2( HEIGHT )-1:0]        cnt_s_y; 

  // Coordinate buffers
  logic [9:0]                           x0, y0;
  logic [9:0]                           x1, y1;

  // Buffers for finding points
  logic                                 find_xy0_l, find_xy1_r;
  logic                                 find_xy0_r, find_xy1_l;

  // Counters of fullness and emptiness
  logic                                 wr_full, rd_empty;

  // Registers for input data (remove the delay)
  logic [BIT_DATA_O-1:0]                data_ff_1, data_ff_2, data_ff_3;

  // Verification data
  logic [BIT_DATA_O-1:0]                data_check;


  always_comb begin
    // Full block and empty block counters
    wr_full   = ( cnt_quan_pxl == ((HEIGHT) * (WIDTH)) );         // HEIGHT * WIDTH = 600 * 800 = 480_000 data
    rd_empty  = ( cnt_quan_pxl == 0 );

    // Assigning coordinates
    x0        = xy_0_i[26:16];
    y0        = xy_0_i[9:0];

    x1        = xy_1_i[26:16];
    y1        = xy_1_i[9:0];
  end

  // Finding points
  always_comb begin
    if ( x0 < x1 ) begin                                                  // if the point xy0 is to the left of the point xy1
      find_xy0_l  = ( cnt_l_x == x0 ) &&  ( cnt_l_y == y0 );
      find_xy1_r  = ( cnt_l_x == x1 ) &&  ( cnt_l_y == y1 );
    end 
    else begin                                                            // if point xy1 is to the left of point xy0
      find_xy0_r  = ( cnt_l_x == x0 ) &&  ( cnt_l_y == y0 );
      find_xy1_l  = ( cnt_l_x >= x1 ) &&  ( cnt_l_y >= y1 );              // Из-за того, что x0 находился правее, дописал знак (>=) для того, чтобы счетчик  
    end                                                                   // досчитывал до последних данных в маленькой области и отправлял сигнал tlast_o.
  end


  typedef enum logic [0:0] { 
                      IDLE      = 0,
                      AREA_PH   = 1     
  }  type_state;
   
  type_state state, next_st;
   


  ////////////////////////////////////////
  // States of the finite state machine //
  ////////////////////////////////////////

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i )                          state <= IDLE;    
    else                                  state <= next_st;
  end


  always_comb begin
    next_st = IDLE;

    case( state )
      IDLE: begin
        // Checking coordinates beyond the limit of a large area
        if( !(( x0 > WIDTH ) || ( y0 > HEIGHT ) || ( x1 > WIDTH ) || ( y1 > HEIGHT )) ) begin   
          if( tvalid_i && !tlast_i )      next_st = AREA_PH;
          else                            next_st = IDLE;
        end
        else begin
                                          next_st = IDLE;
        end
      end

      AREA_PH: begin
          if( !( tvalid_i && !tlast_i ) ) next_st = IDLE;
          else                            next_st = AREA_PH;
      end

      default:                            next_st = IDLE;
    endcase
  end



  /////////////////////////////////////////////
  // Logic of a combinational finite machine //
  /////////////////////////////////////////////

  always_comb begin    
    tdata_o     = 0; 
    tvalid_o    = 0; 
    tlast_o     = 0;

    data_check  = 0;

    case ( state )
      AREA_PH:  begin
        data_check = data_ff_3;
        case( x0 > x1 )
          X0_L: begin
            if( ( cnt_l_x > ( x0 - 1 ) ) && ( cnt_l_x < ( x1 + 1 ) ) && ( cnt_l_y > ( y0 - 1 ) ) && ( cnt_l_y < ( y1 + 1 ) )) begin
              tvalid_o    = tvalid_i;
              tdata_o     = data_ff_3;
            end
            else begin
              tvalid_o    = 0;
              tdata_o     = 0;
            end

            if( find_xy1_r ) begin
              tlast_o     = 1;
            end
          end

          X0_R: begin
            if( ( cnt_l_x <= ( x0 - 1 ) ) && ( cnt_l_x >= ( x1 ) ) && ( cnt_l_y > ( y0 - 1 ) ) && ( cnt_l_y < ( y1 + 1 ) )) begin
              tvalid_o    = tvalid_i;
              tdata_o     = tdata_i;
            end
            else begin
              tvalid_o    = 0;
              tdata_o     = 0;
            end

            if( find_xy1_l) begin
              if( cnt_last_val == ( x0 - x1 ) ) begin
                tlast_o   = 1;
              end
            end
          end
        endcase
      end

    endcase
  end



  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( tvalid_i && !tlast_i ) begin
      data_ff_1   <= tdata_i;
      data_ff_2   <= data_ff_1;
      data_ff_3   <= data_ff_2;
    end
  end


  ////////////////////////////////////////////
  // Sequential logic of a finite automaton //
  ////////////////////////////////////////////

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin 
      cnt_l_x       <= 0;   cnt_l_y       <= 1;
      cnt_s_x_pxl   <= 0;
      cnt_quan_pxl  <= 0;   cnt_last_val  <= 0;
      data_ff_1     <= 0;   data_ff_2     <= 0;   data_ff_3 <= 0;
    end
    else begin
      case( state )
        AREA_PH:  begin

          /////////////////////////////////////
          //////// Large area counters ////////
          /////////////////////////////////////

          // Counting the width and height counter for a large area
          if( cnt_l_x !== WIDTH ) begin
            cnt_l_x       <= cnt_l_x + 1;
          end
          else begin
            cnt_l_x       <= 1;
            cnt_l_y       <= cnt_l_y + 1;
          end

          // Counting the count of the amount of data
          if( cnt_l_y !== HEIGHT + 1 )  begin
            cnt_quan_pxl  <= cnt_quan_pxl + 1;
          end
          else begin                           
            cnt_quan_pxl  <= 1;
            cnt_l_y       <= 1;
          end

          // If the counter is full in a large area
          if( cnt_quan_pxl == ( HEIGHT * WIDTH ) ) begin
            cnt_quan_pxl  <= 0;
            cnt_l_x       <= 0;
            cnt_l_y       <= 0;
          end



          /////////////////////////////////////
          ////// Selections a small area //////
          /////////////////////////////////////

            case( x0 > x1 )
              X0_L: begin
                if( ( cnt_l_x > ( x0 - 1 ) ) && ( cnt_l_x < ( x1 + 1 ) ) && ( cnt_l_y > ( y0 - 1 ) ) && ( cnt_l_y < ( y1 + 1 ) )) begin
                  cnt_s_x_pxl <= cnt_s_x_pxl + 1;              
                end
                else begin
                  cnt_s_x_pxl     <= cnt_s_x_pxl;
                end
              end


              X0_R: begin
                if( ( cnt_l_x <= ( x0 - 1 ) ) && ( cnt_l_x >= ( x1 ) ) && ( cnt_l_y > ( y0 - 1 ) ) && ( cnt_l_y < ( y1 + 1 ) )) begin
                  cnt_s_x_pxl     <= cnt_s_x_pxl + 1;
                end
                else begin
                  cnt_s_x_pxl     <= cnt_s_x_pxl;
                end

                if( find_xy1_l) begin
                  if( cnt_last_val == ( x0 - x1 ) ) begin
                    cnt_last_val  <= 0;
                  end
                  else begin
                    cnt_last_val  <= cnt_last_val + 1;
                  end
                end

              end
            endcase
          end
      endcase
    end
  end
  

endmodule