// Top level wrapper
//
// Asynchronous FIFO
//
// Architecture:
// - Independent write and read clock domains
// - Gray-coded pointers for clock-domain crossing
// - Two-flop synchronizers for cross-domain pointers
// - Common synchronous active-high reset
// - FIFO depth = 2^ADDRSIZE
// - ADDRSIZE must be >= 2
//
//
module async_fifo1
#(
  parameter DATASIZE = 8,
  parameter ADDRSIZE = 4
 )
(
  input   winc, wclk,//winc write enable signal
  input   rinc, rclk,//rinc read enable signal
  input rst, // common synchronous active high reset
  input   [DATASIZE-1:0] wdata,

  output  [DATASIZE-1:0] rdata,
  output  wfull,
  output  rempty
);

  wire [ADDRSIZE-1:0] waddr, raddr;
  wire [ADDRSIZE:0] wptr, rptr, wq2_rptr, rq2_wptr;

  generate
    if (ADDRSIZE < 2) begin : gen_invalid_addrsize
        initial begin
            $display("ERROR: ADDRSIZE must be >= 2");
            $finish;
        end
    end
endgenerate

  sync_r2w #(.ADDRSIZE(ADDRSIZE)) u_sync_r2w (.wclk(wclk),.rst(rst),.rptr(rptr), .wq2_rptr(wq2_rptr));

  sync_w2r #(.ADDRSIZE(ADDRSIZE)) u_sync_w2r (.rclk(rclk),.rst(rst),.wptr(wptr), .rq2_wptr(rq2_wptr));
  
  fifomem #(.DATASIZE(DATASIZE),.ADDRSIZE(ADDRSIZE)) u_fifomem (.winc(winc),.rst(rst),.wfull(wfull),.wclk(wclk),.waddr(waddr),.raddr(raddr),.wdata(wdata),.rdata (rdata));
  
  rptr_empty #(.ADDRSIZE(ADDRSIZE)) u_rptr_empty (.rinc(rinc),.rclk(rclk),.rst(rst),.rq2_wptr(rq2_wptr),.rempty(rempty),.raddr(raddr),.rptr(rptr));
  
  wptr_full #(.ADDRSIZE(ADDRSIZE)) u_wptr_full (.winc(winc),.wclk(wclk),.rst(rst),.wq2_rptr(wq2_rptr),.wfull(wfull),.waddr(waddr),.wptr(wptr));

endmodule