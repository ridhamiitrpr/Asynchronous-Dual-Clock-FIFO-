module wptr_full
#(
  parameter ADDRSIZE = 4
)
(
  input   winc, wclk, rst,
  input   [ADDRSIZE :0] wq2_rptr,
  output reg  wfull,
  output  [ADDRSIZE-1:0] waddr,
  output reg [ADDRSIZE :0] wptr
);

   reg [ADDRSIZE:0] wbin;
  wire [ADDRSIZE:0] wgraynext, wbinnext;
  wire wfull_val;

  // GRAYSTYLE2 pointer
  always @(posedge wclk) begin
    if (rst) begin
      wbin <= {ADDRSIZE+1{1'b0}};
      wptr <= {ADDRSIZE+1{1'b0}};
      wfull<=1'b0;
    end
    else begin
        wbin  <= wbinnext;
        wptr  <= wgraynext;
        wfull <= wfull_val;
    end
  end

  // Memory write-address pointer (okay to use binary to address memory)
  assign waddr = wbin[ADDRSIZE-1:0];
  assign wbinnext = wbin + (winc & ~wfull);
  assign wgraynext = (wbinnext>>1) ^ wbinnext;

  assign wfull_val = (wgraynext=={~wq2_rptr[ADDRSIZE:ADDRSIZE-1], wq2_rptr[ADDRSIZE-2:0]});


endmodule