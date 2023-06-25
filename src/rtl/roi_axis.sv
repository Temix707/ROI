module roi_axis
#(
  parameter                 WIDTH  = 800,                           //  width of the large area   800
                            HEIGHT = 600,                           //  height of a large area    600

                            BIT_D  = 8,
                            BIT_C  = 32
)
(
  input   logic             clk_i,
  input   logic             arst_i,

  input   logic [BIT_D-1:0] tdata_i,                                //  incoming pixels in a large area
  input   logic             tvalid_i,                               //  signal of readiness for data transfer to a large area
  input   logic             tlast_i,                                //  signal signaling the last piece of data of a large area

  input   logic [BIT_C-1:0] xy_0_i,                                 //  x0[26:16] y0[9:0]  the register responsible for the coordinate of the first point
  input   logic [BIT_C-1:0] xy_1_i,                                 //  x1[26:16] y1[9:0]  the register responsible for the coordinate of the second point

  output  logic [BIT_D-1:0] tdata_o,                                //  exiting pixels from a small area
  output  logic             tvalid_o,                               //  signal of readiness for data transmission from a small area
  output  logic             tlast_o                                 //  signal signaling the last piece of data of a small area
);


  logic [$clog2( HEIGHT * WIDTH )-1:0]  cnt_quan_pxl;               //  data quantity counter (log2 (480000) = 19 bit)

  //  X (width) and Y (height) coordinate counters for a LARGE area
  logic [$clog2( WIDTH  )-1:0]          cnt_l_x;
  logic [$clog2( HEIGHT )-1:0]          cnt_l_y;

  // X (width) and Y (height) coordinate counters for a SMALL area (to check)
  logic [$clog2( WIDTH  )-1:0]          cnt_s_x;
  //logic [$clog2( HEIGHT )-1:0]          cnt_s_y; 

  // Ñcoordinate buffers
  logic [9:0]                           x0, y0;
  logic [9:0]                           x1, y1;

  // Buffers for finding points
  logic                                 find_xy0, find_xy1;

  // Counters of fullness and emptiness
  logic                                 wr_full, rd_empty;


  always_comb begin
    wr_full   = ( cnt_quan_pxl == ((HEIGHT + 1) * (WIDTH + 1)) );   // ((HEIGHT + 1) * (WIDTH + 1)) == 481401 values (0-600,0-800)
    rd_empty  = ( cnt_quan_pxl == 0 );

    x0        = xy_0_i[26:16];
    y0        = xy_0_i[9:0];

    x1        = xy_1_i[26:16];
    y1        = xy_1_i[9:0];

    find_xy0  = ( cnt_l_x == x0 ) && ( ( cnt_l_y == y0 ) );
    find_xy1  = ( cnt_l_x == x1 ) && ( ( cnt_l_y == y1 ) );
  end


  typedef enum logic [0:0] { 
                      IDLE      = 0,
                      AREA_PH   = 1     
                   }  type_enum;
   
  type_enum state, next_st;



  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      next_st <= IDLE;    
    end 
    else begin
      state <= next_st;
    end
  end


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      tdata_o       <= 0; tvalid_o      <= 0; tlast_o       <= 0; 
      cnt_l_x       <= 0; cnt_l_y       <= 0;
      cnt_s_x       <= 0; //cnt_s_y       <= 0;
      cnt_quan_pxl  <= 0;
    end
    else begin
      case( state )
        IDLE:     begin
          if( tvalid_i ^ tlast_i ) begin
            next_st <= AREA_PH;
          end
          else begin
            next_st <= IDLE;
          end
        end

        AREA_PH:  begin
          
          if( !(tvalid_i ^ tlast_i) ) next_st   <= IDLE;
          else                        next_st   <= AREA_PH;
        
          //////// Large area counters ////////
          // Counting the width and height counter for a large area
          if( cnt_l_x !== WIDTH ) begin
            cnt_l_x   <= cnt_l_x + 1;
          end
          else begin
            cnt_l_x   <= 0;
            cnt_l_y   <= cnt_l_y + 1;
          end

          // Zeroing the height counter when the maximum height of a large area is reached
          if( cnt_l_y == (HEIGHT + 1) )   cnt_l_y     <= 0;

          // Counting the count of the amount of data
          if( cnt_l_y !== (HEIGHT + 1) )  cnt_quan_pxl <= cnt_quan_pxl + 1;
          else                            cnt_quan_pxl <= 0;

          // If the counter is full in a large area
          if( cnt_quan_pxl == ((HEIGHT + 1) * (WIDTH + 1)) ) begin
            cnt_l_x   <= 0;
            cnt_l_y   <= 0;
          end
          /////////////////////////////////////


          ////// Selections a small area //////
          if( ( cnt_l_x >= (x0) ) && ( cnt_l_x <= (x1-1) ) && ( cnt_l_y > (y0-1) ) && ( cnt_l_y < (y1+1) )) begin
            tvalid_o  <= tvalid_i;
            tdata_o   <= tdata_i;

            cnt_s_x   <= cnt_s_x + 1;
          end
          else begin
            tvalid_o  <= 0;
            tdata_o   <= 0;
            
            cnt_s_x   <= 0;
          end

          if( find_xy1 ) begin
            tlast_o   <= 1;
          end

        end

        default: begin
          next_st <= IDLE;
        end
      endcase
    
    end

  end

endmodule