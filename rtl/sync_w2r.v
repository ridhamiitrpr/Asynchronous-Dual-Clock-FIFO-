module sync_w2r
#(
  parameter ADDRSIZE = 4
)
(
  input   rclk, rst,
  input   [ADDRSIZE:0] wptr,
  output reg [ADDRSIZE:0] rq2_wptr
);

  reg [ADDRSIZE:0] rq1_wptr;

   always @(posedge rclk) begin
    if (rst) begin
      rq1_wptr <= {ADDRSIZE+1{1'b0}};
      rq2_wptr <= {ADDRSIZE+1{1'b0}};
    end
    else begin
      rq2_wptr <= rq1_wptr;
      rq1_wptr<=wptr;
   end
   end

endmodule