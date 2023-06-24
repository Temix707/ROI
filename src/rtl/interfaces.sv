interface interfaces
#(
  parameter                 BIT_D  = 8,
                            BIT_C  = 32
);

  logic             clk_i;
  logic             arst_i;

  logic [BIT_D-1:0] tdata_i;                      //  incoming pixels in a large area
  logic             tvalid_i;                     //  signal of readiness for data transfer to a large area
  logic             tlast_i;                      //  signal signaling the last piece of data of a large area

  logic [BIT_C-1:0] xy_0_i;                       //  x0[26:16] y0[9:0]  the register responsible for the coordinate of the first point
  logic [BIT_C-1:0] xy_1_i;                       //  x1[26:16] y1[9:0]  the register responsible for the coordinate of the second point

  logic [BIT_D-1:0] tdata_o;                      //  exiting pixels from a small area
  logic             tvalid_o;                     //  signal of readiness for data transmission from a small area
  logic             tlast_o;                      //  signal signaling the last piece of data of a small area


  modport dut_axis (
    input   clk_i,
            arst_i,

            tdata_i,
            tvalid_i,
            tlast_i,

            xy_0_i,
            xy_1_i,

    output  tdata_o,
            tvalid_o,
            tlast_o
  );

endinterface