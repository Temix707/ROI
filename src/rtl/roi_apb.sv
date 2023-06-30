module roi_apb
#(
  parameter                             APB_DATA_I_WIDTH = 64,
                                        APB_DATA_O_WIDTH = 32,

                                        APB_ADDR_WIDTH   = 12     // APB slaves are 4KB by default 
)
(
  input   logic                         clk_i,
  input   logic                         arst_i,

  input   logic [APB_DATA_I_WIDTH-1:0]  apb_pwdata_i,                
  input   logic [APB_ADDR_WIDTH-1:0]    apb_paddr_i,                   
  
  input   logic                         apb_pwrite_i,             // Always in the recording state
  input   logic                         apb_psel_i,                   

  output  logic  [APB_DATA_O_WIDTH-1:0] xy_0_o,
  output  logic  [APB_DATA_O_WIDTH-1:0] xy_1_o
);

  // Local declarations
  localparam ADDR_ROI = 12'h0;                                    // Slave Device Address (ROI)

  logic                         apb_write;
  logic                         apb_sel_roi_val;

  logic [APB_DATA_I_WIDTH-1:0]  xy_val_ff;  

  // APB decoding
  always_comb begin
    apb_write       = apb_psel_i & apb_pwrite_i;

    apb_sel_roi_val = ( apb_paddr_i == ADDR_ROI );                // Choosing a peripheral device (ROI)
  end


  // APB data out
  logic [APB_DATA_I_WIDTH-1:0] apb_dout_ff;
  logic [APB_DATA_I_WIDTH-1:0] apb_dout_next;

  // Input reg values xy
  always_ff @( posedge clk_i or posedge arst_i ) begin
    if ( arst_i ) xy_val_ff   <= '0;
    else          xy_val_ff   <= apb_pwdata_i;
  end

  // Output reg values
  always_ff @( posedge clk_i or posedge arst_i ) begin
    if ( arst_i ) apb_dout_ff <= '0;
    else          apb_dout_ff <= apb_dout_next;
  end

  assign apb_dout_next = apb_sel_roi_val ? ( xy_val_ff ) : ( '0 );

  assign xy_0_o = apb_dout_ff [31:0];
  assign xy_1_o = apb_dout_ff [63:32];

endmodule

















/*    
  input  logic                          apb_penable_i,              // (2d cycle)

  output logic [BIT_C-1:0]              apb_prdata_o,
  output logic                          apb_pready_o,
  output logic                          apb_pslverr_o,
*/