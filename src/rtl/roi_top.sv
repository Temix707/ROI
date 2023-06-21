module roi_top(

);


  logic [31:0] xy_0;
  logic [31:0] xy_1;

  roi_axis DUT_AXIS
  (

    .xy_0_i  ( xy_0 ),
    .xy_1_i  ( xy_1 )

  );


  roi_apb DUT_APB
  (
    .xy_0_o  ( xy_0 ),
    .xy_1_o  ( xy_1 )
  );

endmodule
