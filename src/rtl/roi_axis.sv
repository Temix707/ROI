module roi_axis
#(
  parameter                 WIDTH  = 800,                 //  width of the large area   800
                            HEIGHT = 600,                 //  height of a large area    600

                            BIT_D  = 8,
                            BIT_C  = 32
)
(
  input   logic             clk_i,
  input   logic             arst_i,

  input   logic [BIT_D-1:0] tdata_i,                      //  incoming pixels in a large area
  input   logic             tvalid_i,                     //  signal of readiness for data transfer to a large area
  input   logic             tlast_i,                      //  signal signaling the last piece of data of a large area

  input   logic [BIT_C-1:0] xy_0_i,                       //  x0[26:16] y0[9:0]  the register responsible for the coordinate of the first point
  input   logic [BIT_C-1:0] xy_1_i,                       //  x1[26:16] y1[9:0]  the register responsible for the coordinate of the second point

  output  logic [BIT_D-1:0] tdata_o,                      //  exiting pixels from a small area
  output  logic             tvalid_o,                     //  signal of readiness for data transmission from a small area
  output  logic             tlast_o                       //  signal signaling the last piece of data of a small area
);


  logic [BIT_D-1:0] pixel;                                // buffer for data

  //  X (width) and Y (height) coordinate counters for a large area
  logic [$clog2( WIDTH  )-1:0]  cnt_l_x;
  logic [$clog2( HEIGHT )-1:0]  cnt_l_y;

  // X (width) and Y (height) coordinate counters for a small area (to check)
  logic [$clog2( WIDTH  )-1:0]  cnt_s_x;
  logic [$clog2( HEIGHT )-1:0]  cnt_s_y; 

  // buffers for finding points
  logic                         find_x0, find_y0;
  logic                         find_x1, find_y1;


  typedef enum logic [1:0] { 
                      IDLE    = 0,
                      FIND    = 1,
                      TRANS   = 2,
                      FORGET  = 3       
                   }  type_enum;
   
  type_enum state, next_st;




  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      state <= IDLE;    
    end 
    else begin
      state <= next_st;
    end
  end


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin

    end
    else begin
      case( state )
        IDLE: begin
        
        end

        FIND: begin
        
        end

        TRANS: begin
        
        end

        FORGET: begin
        
        end

        default: begin
        
        end
      endcase
    end
  end





  
endmodule









/*
  //logic [7:0] mem_l [HEIGHT-1:0][WIDTH-1:0];
  //logic [7:0] mem_l [(HEIGHT*WIDTH)-1:0];

  // X (width) and Y (height) coordinate counters
  logic [15:0] cnt_x;                                     // 16 bits,
  logic [15:0] cnt_y;

  logic        wr_full, rd_empty;
  logic [18:0] cnt_quan_data;                             //  data quantity counter (log2 (480000) = 19 bit)       

  always_comb begin
    wr_full   = ( cnt_quan_data == HEIGHT*WIDTH );
    rd_empty  = ( cnt_quan_data == 0 );
  end

  typedef enum logic [0:0] { 
                      IDLE  = 0,
                      TRANS = 1       
                   }  type_enum;
   
  type_enum state, next_st;

    // State Change Block / Block for State
  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      state <= IDLE;    
    end 
    else begin
      state <= next_st;
    end
  end


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if( arst_i ) begin
      tdata_o       <= 0;
      tvalid_o      <= 0;
      tlast_o       <= 0;

      cnt_quan_data <= 0;
    end
    else begin
      case( state )

        IDLE: begin
          if( tvalid_i ^ tlast_i ) begin    // tlast ?
            next_st       <= TRANS;
            cnt_quan_data <= cnt_quan_data + 1'd1;
          end
          else begin
            next_st       <= IDLE;
            cnt_quan_data <= 0;
          end
        end

        TRANS: begin
          next_st       <= TRANS;

          if( cnt_quan_data ==  )

        end

      endcase
    end

  end
*/