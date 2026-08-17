//
// Read pointer to write clock synchronizer
//
module sync_r2w
#(
  parameter ADDRSIZE = 4
)
(
  input   wclk, rst,
  input   [ADDRSIZE:0] rptr,
  output reg  [ADDRSIZE:0] wq2_rptr//readpointer with write side
);

  reg [ADDRSIZE:0] wq1_rptr;

   always @(posedge wclk) begin
    if (rst) begin
     wq1_rptr <= {ADDRSIZE+1{1'b0}};
     wq2_rptr <= {ADDRSIZE+1{1'b0}};
    end
    else begin
     wq1_rptr <= rptr;
     wq2_rptr <= wq1_rptr;
    end
    end

endmodule