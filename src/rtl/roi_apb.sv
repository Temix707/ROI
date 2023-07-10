module roi_apb
#(
  parameter                       APB_DATA_W = 32,
                                  APB_ADDR_W = 12 
)
(
  input   logic                   clk_i,
  input   logic                   arst_i,

  input   logic [APB_DATA_W-1:0]  apb_pwdata_i,                
  input   logic [APB_ADDR_W-1:0]  apb_paddr_i,                   
  
  input   logic                   apb_pwrite_i,            
  input   logic                   apb_psel_i,
  input   logic                   apb_penable_i,     

  output  logic                   apb_pready_o,                   
  output  logic  [APB_DATA_W-1:0] apb_prdata_o,   
  
  output  logic  [APB_DATA_W-1:0] xy_0_o,
  output  logic  [APB_DATA_W-1:0] xy_1_o
);


  localparam ADDR_XY_0    = 12'h0;
  localparam ADDR_XY_1    = 12'h4;


  logic                   apb_write;
  logic                   apb_read;


  // Address selection
  logic                   apb_sel_xy_0_o;
  logic                   apb_sel_xy_1_o;


  // Registers
  // Input data
  logic [APB_DATA_W-1:0]  data_i_ff;
  logic [APB_DATA_W-1:0]  data_i_next;
  logic                   data_i_en;

  // Output coordinates xy0
  logic [APB_DATA_W-1:0]  data_xy_0_o_ff;
  //logic [APB_DATA_W-1:0]  data_xy_0_o_next;
  //logic                   data_xy_0_o_en;     ?

  // Output coordinates xy1
  logic [APB_DATA_W-1:0]  data_xy_1_o_ff;
  //logic [APB_DATA_W-1:0]  data_xy_1_o_next;
  //logic                   data_xy_1_o_en;     ?

  // PRDATA
  logic [APB_DATA_W-1:0]  apb_dout_ff;
  logic [APB_DATA_W-1:0]  apb_dout_next;
  logic                   apb_dout_en;

  //  PREADY
  logic                   apb_ready_ff;
  logic                   apb_ready_next;
  logic                   apb_ready_en;



  //////////////////////////
  /////  APB decoding  /////
  //////////////////////////

  always_comb begin
    apb_write      =   apb_psel_i &  apb_pwrite_i;
    apb_read       =   apb_psel_i & ~apb_pwrite_i;

    apb_sel_xy_0_o = ( apb_paddr_i == ADDR_XY_0  );
    apb_sel_xy_1_o = ( apb_paddr_i == ADDR_XY_1  );
  end




  //////////////////////////
  ///  Data in register  ///
  //////////////////////////

  // Data in

  assign data_i_en = apb_write;

  assign data_i_next = apb_pwdata_i;

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if    ( arst_i    ) data_i_ff <= '0;
    else  ( data_i_en ) data_i_ff <= data_i_next;
  end




  //////////////////////////
  /////  APB data out  /////
  //////////////////////////

  //  PRDATA  //

  assign apb_dout_en   = apb_read;

  assign apb_dout_next = apb_sel_xy_0_o ? APB_DATA_W'( data_i_ff )
                       : apb_sel_xy_1_o ? APB_DATA_W'( data_i_ff )   
                       :                  '0;


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if      ( arst_i      )   apb_dout_ff <= '0;
    else if ( apb_dout_en )   apb_dout_ff <= apb_dout_next;
  end

  assign apb_prdata_o  = apb_dout_ff;



  //  XY0  //

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if      ( arst_i )    data_xy_0_o_ff <= '0;
    else /*if ( ? ) */    data_xy_0_o_ff <= apb_dout_next;
  end

  assign xy_0_o = data_xy_0_o_ff;




  //  XY1  //

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if      ( arst_i )    data_xy_1_o_ff <= '0;
    else /*if ( ? ) */    data_xy_1_o_ff <= apb_dout_next;
  end

  assign xy_1_o = data_xy_0_o_ff;






  ///////////////////////////
  //////   APB ready   //////
  ///////////////////////////

  assign apb_ready_en   = ( apb_psel_i & apb_penable_i ) | apb_ready_ff;

  assign apb_ready_next = ( apb_psel_i & apb_penable_i ) & ~apb_ready_ff;


  always_ff @( posedge clk_i or posedge arst_i ) begin
    if      ( arst_i       )    apb_ready_ff <= '0;
    else if ( apb_ready_en )    apb_ready_ff <= apb_ready_next;
  end

  assign apb_pready_o  = apb_ready_ff;



endmodule




















///////////////////////////////////////////////////
/////////////////   OLD  //////////////////////////
///////////////////////////////////////////////////

/*
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

/////////


  // APB data out
  logic [APB_DATA_I_WIDTH-1:0] apb_dout_ff;
  logic [APB_DATA_I_WIDTH-1:0] apb_dout_next;

  // Input reg values xy
  always_ff @( posedge clk_i or posedge arst_i ) begin
    if ( arst_i ) xy_val_ff   <= '0;
    else          xy_val_ff   <= apb_pwdata_i;
  end



  // Output reg values
  assign apb_dout_next = apb_sel_roi_val ? ( xy_val_ff ) : ( '0 );

  always_ff @( posedge clk_i or posedge arst_i ) begin
    if ( arst_i ) apb_dout_ff <= '0;
    else          apb_dout_ff <= apb_dout_next;
  end


  assign xy_0_o        = apb_dout_ff [31:0];
  assign xy_1_o        = apb_dout_ff [63:32];

endmodule

*/
