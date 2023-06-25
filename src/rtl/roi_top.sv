module roi_top
#(
  parameter                 WIDTH  = 800, 
                            HEIGHT = 600,

                            BIT_D  = 8,
                            BIT_C  = 32 
)
(
  // AXIS
  input   logic             clk_i,
  input   logic             arst_i,

  input   logic [BIT_D-1:0] tdata_i,                      //  incoming pixels in a large area
  input   logic             tvalid_i,                     //  signal of readiness for data transfer to a large area
  input   logic             tlast_i,                      //  signal signaling the last piece of data of a large area

  output  logic [BIT_D-1:0] tdata_o,                      //  exiting pixels from a small area
  output  logic             tvalid_o,                     //  signal of readiness for data transmission from a small area
  output  logic             tlast_o, 

  // APB
  input   logic [BIT_C-1:0] apb_pwdata_i,
  input   logic             apb_paddr_i,

  input  logic              apb_pwrite_i,
  input  logic              apb_psel_i,
    
  input  logic              apb_penable_i

  //output logic              apb_pslverr_o
  //output logic [BIT_C-1:0] apb_prdata_o,                  
  //output logic             apb_pready_o,
);


  logic [BIT_C-1:0] xy_0;
  logic [BIT_C-1:0] xy_1;

  roi_axis
  # ( WIDTH, HEIGHT, BIT_D, BIT_C )
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


  roi_apb 
  # ( WIDTH, HEIGHT, BIT_D, BIT_C )
  DUT_APB
  (
    .clk_i          ( clk_i         ),
    .arst_i         ( arst_i        ),

    .apb_pwdata_i   ( apb_pwdata_i  ),
    .apb_paddr_i    ( apb_paddr_i   ),

    .apb_pwrite_i   ( apb_pwrite_i  ),
    .apb_psel_i     ( apb_psel_i    ),
    .apb_penable_i  ( apb_penable_i ),

    .xy_0_o         ( xy_0          ),
    .xy_1_o         ( xy_1          )
  );

endmodule
