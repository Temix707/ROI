module roi_top
#(
  parameter                       WIDTH       = 800,      //  width of the large area   800
                                  HEIGHT      = 600,      //  height of a large area    600

                                  AXIS_DATA_W = 8,
                                  APB_DATA_W  = 32, 
                                  APB_ADDR_W  = 12
)
(
  input   logic                   clk_i,
  input   logic                   arst_i,

  // AXIS
  input   logic [AXIS_DATA_W-1:0] tdata_i,                  //  incoming pixels in a large area
  input   logic                   tvalid_i,                 //  signal of readiness for data transfer to a large area
  input   logic                   tlast_i,                  //  signal signaling the last piece of data of a large area

  output  logic [AXIS_DATA_W-1:0] tdata_o,                  //  exiting pixels from a small area
  output  logic                   tvalid_o,                 //  signal of readiness for data transmission from a small area
  output  logic                   tlast_o,  

  // APB
  input   logic [APB_DATA_W-1:0] apb_pwdata_i,
  input   logic [APB_ADDR_W-1:0] apb_paddr_i,

  input   logic                  apb_pwrite_i,
  input   logic                  apb_psel_i,
  input   logic                  apb_penable_i,     

  output  logic                  apb_pready_o,                   
  output  logic [APB_DATA_W-1:0] apb_prdata_o
);

  // Wire
  logic [APB_DATA_W-1:0] xy_0;                              //  x0[26:16] y0[9:0]  the register responsible for the coordinate of the first point
  logic [APB_DATA_W-1:0] xy_1;                              //  x1[26:16] y1[9:0]  the register responsible for the coordinate of the second point


  // AXIS
  roi_axis
  # ( WIDTH, HEIGHT, AXIS_DATA_W, APB_DATA_W )
  DUT_AXIS 
  (
    .clk_i          ( clk_i         ),
    .arst_i         ( arst_i        ),

    .tdata_i        ( tdata_i       ),
    .tvalid_i       ( tvalid_i      ),
    .tlast_i        ( tlast_i       ),

    .xy_0_i         ( xy_0          ),
    .xy_1_i         ( xy_1          ),

    .tdata_o        ( tdata_o       ),
    .tvalid_o       ( tvalid_o      ),
    .tlast_o        ( tlast_o       )
  );


  // APB
  roi_apb 
  # ( APB_DATA_W, APB_ADDR_W )
  DUT_APB
  (
    .clk_i          ( clk_i         ),
    .arst_i         ( arst_i        ),

    .apb_pwdata_i   ( apb_pwdata_i  ),
    .apb_paddr_i    ( apb_paddr_i   ),

    .apb_pwrite_i   ( apb_pwrite_i  ),
    .apb_psel_i     ( apb_psel_i    ),
    .apb_penable_i  ( apb_penable_i ),     

    .apb_pready_o   ( apb_pready_o  ),                   
    .apb_prdata_o   ( apb_prdata_o  ), 

    .xy_0_o         ( xy_0          ),
    .xy_1_o         ( xy_1          )
  );

endmodule
