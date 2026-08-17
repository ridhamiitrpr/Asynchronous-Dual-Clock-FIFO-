module rptr_empty
#(
  parameter ADDRSIZE = 4
)
(
  input   rinc, rclk, rst,
  input   [ADDRSIZE :0] rq2_wptr,
  output reg  rempty,
  output  [ADDRSIZE-1:0] raddr,
  output reg [ADDRSIZE :0] rptr
);

  reg [ADDRSIZE:0] rbin;
  wire [ADDRSIZE:0] rgraynext, rbinnext;
  wire rempty_val;

  //-------------------
  // GRAYSTYLE2 pointer
  //-------------------
   always @(posedge rclk) begin
    if (rst) begin
      rbin <= {ADDRSIZE+1{1'b0}};
      rptr <= {ADDRSIZE+1{1'b0}};
      rempty <= 1'b1;
    end
    else begin
      rbin <= rbinnext;
      rptr<= rgraynext;
      rempty <= rempty_val;
    end
   end

  // Memory read-address pointer (okay to use binary to address memory)
  assign raddr = rbin[ADDRSIZE-1:0];
  assign rbinnext = rbin + (rinc & ~rempty);
  assign rgraynext = (rbinnext>>1) ^ rbinnext;

  //---------------------------------------------------------------
  // FIFO empty when the next rptr == synchronized wptr or on reset
  //---------------------------------------------------------------
  assign rempty_val = (rgraynext == rq2_wptr);

endmodule