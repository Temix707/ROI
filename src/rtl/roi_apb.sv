module roi_apb
#(
  parameter                         WIDTH  = 800, 
                                    HEIGHT = 600,

                                    BIT_D  = 8,
                                    BIT_C  = 32 
)
(
  input   logic                     clk_i,
  input   logic                     arst_i,

  input   logic [(BIT_C * 2)-1:0]   apb_pwdata_i,
  input   logic                     apb_paddr_i,
  
  input   logic                     apb_pwrite_i,
  input   logic                     apb_psel_i,
    
  input   logic                     apb_penable_i,

  //output logic [BIT_C-1:0]  apb_prdata_o,
  //output logic              apb_pready_o,
  //output logic              apb_pslverr_o,

  output  logic  [BIT_C-1:0]        xy_0_o,
  output  logic  [BIT_C-1:0]        xy_1_o
);

/*
  if ( addr_apb_i == 0 ) begin
    xy_0_o <= data_apb_i; 
  end 
  else if ( addr_apb_i == 1 ) begin 
    xy_1_o <= <= data_apb_i; 
  end

  always_comb begin
    ...
    xy_0_o [BIT_C-1:0] =  apb_pwdata_i [BIT_C-1:0]                // [31:0]
    xy_1_o [BIT_C-1:0] =  apb_pwdata_i [(BIT_C * 2)-1:BIT_C]      // [63:32]
    ...
  end
*/



endmodule