`timescale 1ns/1ps

module async_fifo1_tb;

parameter DATASIZE = 8;
parameter ADDRSIZE = 4;
parameter DEPTH    = (1 << ADDRSIZE);

reg wclk, rclk, rst;
reg winc, rinc;
reg [DATASIZE-1:0] wdata;

wire [DATASIZE-1:0] rdata;
wire wfull, rempty;

//============================================================
// DUT
//============================================================

async_fifo1 #(
    .DATASIZE(DATASIZE),
    .ADDRSIZE(ADDRSIZE)
) dut (
    .winc  (winc),
    .wclk  (wclk),
    .rinc  (rinc),
    .rclk  (rclk),
    .rst   (rst),
    .wdata (wdata),
    .rdata (rdata),
    .wfull (wfull),
    .rempty(rempty)
);

//============================================================
// Reference FIFO
//============================================================

reg [DATASIZE-1:0] ref_fifo [0:DEPTH-1];

integer wr_ptr, rd_ptr;
integer count;
integer errors;
integer test_no;

integer accepted_writes;
integer accepted_reads;
integer rejected_writes;
integer rejected_reads;

//============================================================
// Clocks
//============================================================

initial begin
    wclk = 0;
    forever #10 wclk = ~wclk;
end

initial begin
    rclk = 0;
    forever #17 rclk = ~rclk;
end

//============================================================
// VCD
//============================================================

initial begin
    $dumpfile("async_fifo1_tb.vcd");
    $dumpvars(0, async_fifo1_tb);
end

//============================================================
// Reference queue display
//============================================================

task show_queue;
integer i, index;
begin
    $write("       Queue = [");

    if (count == 0)
        $write("EMPTY");
    else begin
        for (i = 0; i < count; i = i + 1) begin
            index = (rd_ptr + i) % DEPTH;

            if (i != 0)
                $write(" ");

            $write("%h", ref_fifo[index]);
        end
    end

    $display("]");
end
endtask

//============================================================
// Error reporting
//============================================================

task error;
input [255:0] msg;
begin
    errors = errors + 1;

    $display("ERROR @ %0t : %s", $time, msg);
    $display("       wfull=%b rempty=%b count=%0d",
             wfull, rempty, count);

    show_queue;
end
endtask

//============================================================
// Reset
//============================================================

task reset_fifo;
begin
    winc  = 0;
    rinc  = 0;
    wdata = 0;
    rst   = 1;

    repeat(3) @(posedge wclk);
    repeat(3) @(posedge rclk);

    rst = 0;

    wr_ptr = 0;
    rd_ptr = 0;
    count  = 0;

    @(negedge wclk);
    @(negedge rclk);
end
endtask

//============================================================
// Write transaction
//============================================================

task write_item;
input [DATASIZE-1:0] data;
reg accepted;
begin
    @(negedge wclk);

    wdata = data;
    winc  = 1;

    // DUT evaluates wfull at this edge.
    accepted = !wfull;

    @(posedge wclk);

    if (!rst) begin
        if (accepted) begin
            ref_fifo[wr_ptr] = data;
            wr_ptr = (wr_ptr + 1) % DEPTH;
            count = count + 1;
            accepted_writes = accepted_writes + 1;

            $display("[WRITE] ACCEPTED data=%h", data);
            show_queue;
        end
        else begin
            rejected_writes = rejected_writes + 1;
            $display("[WRITE] REJECTED (FULL) data=%h", data);
        end
    end

    @(negedge wclk);
    winc = 0;
end
endtask

//============================================================
// Read transaction
//============================================================

task read_item;
reg accepted;
reg [DATASIZE-1:0] expected;
begin
    @(negedge rclk);

    rinc = 1;

    // DUT evaluates rempty at this edge.
    accepted = !rempty;

    if (accepted)
        expected = ref_fifo[rd_ptr];

    @(posedge rclk);

    if (!rst) begin
        if (accepted) begin

            $display("[READ ] expected=%h actual=%h",
                     expected, rdata);

            if (rdata !== expected)
                error("FIFO DATA MISMATCH");

            rd_ptr = (rd_ptr + 1) % DEPTH;
            count = count - 1;
            accepted_reads = accepted_reads + 1;

            show_queue;
        end
        else begin
            rejected_reads = rejected_reads + 1;
            $display("[READ ] REJECTED (EMPTY)");
        end
    end

    @(negedge rclk);
    rinc = 0;
end
endtask

//============================================================
// Test 1 : Reset
//============================================================

task test_reset;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : RESET", test_no);

    reset_fifo;

    if (wfull !== 0)
        error("wfull not LOW after reset");

    if (rempty !== 1)
        error("rempty not HIGH after reset");

    $display("PASS");
end
endtask

//============================================================
// Test 2 : Basic operation
//============================================================

task test_basic;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : BASIC OPERATION", test_no);

    reset_fifo;

    write_item(8'h11);
    write_item(8'h22);
    write_item(8'h33);
    write_item(8'h44);

    read_item;
    read_item;
    read_item;
    read_item;

    repeat(3) @(posedge rclk);

    if (count != 0)
        error("FIFO model not empty");

    if (rempty !== 1)
        error("rempty not asserted");

    $display("PASS");
end
endtask

//============================================================
// Test 3 : Full + overflow
//============================================================

task test_full;
integer i, old_count;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : FULL + OVERFLOW", test_no);

    reset_fifo;

    for (i = 0; i < DEPTH; i = i + 1)
        write_item(i);

    @(negedge wclk);

    if (wfull !== 1)
        error("wfull did not assert");

    old_count = count;

    write_item(8'hAA);
    write_item(8'hBB);
    write_item(8'hCC);

    if (count != old_count)
        error("Overflow changed FIFO contents");

    if (wfull !== 1)
        error("wfull lost during overflow");

    $display("PASS");
end
endtask

//============================================================
// Test 4 : Empty + underflow
//============================================================

task test_empty;
integer i, old_count;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : EMPTY + UNDERFLOW", test_no);

    reset_fifo;

    for (i = 0; i < DEPTH; i = i + 1)
        write_item(8'h80 + i);

    repeat(4) @(posedge rclk);

    for (i = 0; i < DEPTH; i = i + 1)
        read_item;

    repeat(2) @(posedge rclk);

    if (rempty !== 1)
        error("rempty did not assert");

    old_count = count;

    read_item;
    read_item;
    read_item;

    if (count != old_count)
        error("Underflow changed FIFO contents");

    if (rempty !== 1)
        error("rempty lost during underflow");

    $display("PASS");
end
endtask

//============================================================
// Test 5 : Write faster than read
//============================================================
task test_write_fast;
integer wi;
integer ri;
begin
    test_no = test_no + 1;

    $display("\nTEST %0d : WRITE FASTER THAN READ", test_no);

    reset_fifo;

    fork
        begin
            for (wi = 0; wi < 35; wi = wi + 1)
                write_item(8'h40 + wi);
        end

        begin
            // Allow write pointer to propagate into read domain
            repeat(3) @(posedge rclk);

            for (ri = 0; ri < 12; ri = ri + 1) begin
                #35;
                read_item;
            end
        end
    join

    while (count > 0)
        read_item;

    repeat(4) @(posedge rclk);

    if (count != 0)
        error("FIFO model not empty");

    $display("PASS");
end
endtask
//============================================================
// Test 6 : Read faster than write
//============================================================
task test_read_fast;
integer wi;
integer ri;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : READ FASTER THAN WRITE", test_no);

    reset_fifo;

    fork
        begin
            for (wi = 0; wi < 15; wi = wi + 1) begin
                #68;
                write_item(8'h80 + wi);
            end
        end

        begin
            for (ri = 0; ri < 35; ri = ri + 1)
                read_item;
        end
    join

    repeat(4) @(posedge rclk);

    if (count != 0)
        error("FIFO model not empty");

    $display("PASS");
end
endtask

//============================================================
// Test 7 : Simultaneous read/write
//============================================================

task test_simultaneous;
integer wi;
integer ri;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : SIMULTANEOUS READ/WRITE", test_no);

    reset_fifo;

    write_item(8'h10);
    write_item(8'h11);
    write_item(8'h12);
    write_item(8'h13);
    write_item(8'h14);

    fork
        begin
            for (wi = 0; wi < 25; wi = wi + 1)
                write_item(8'h20 + wi);
        end

        begin
            for (ri = 0; ri < 25; ri = ri + 1)
                read_item;
        end
    join

    while (count > 0)
        read_item;

    repeat(4) @(posedge rclk);

    if (count != 0)
        error("FIFO model not empty");

    $display("PASS");
end
endtask

//============================================================
// Test 8 : Short randomized asynchronous traffic
//============================================================

task test_random;
integer i;
integer wseed, rseed;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : RANDOM ASYNCHRONOUS TRAFFIC", test_no);

    reset_fifo;

    wseed = 32'h2468ACE0;
    rseed = 32'hDEADBEEF;

    fork

        // Random write process
        begin
            for (i = 0; i < 50; i = i + 1) begin
                if ($random(wseed) & 1)
                    write_item($random(wseed));
                else
                    @(negedge wclk);
            end
        end

        // Random read process
        begin
            for (i = 0; i < 50; i = i + 1) begin
                if ($random(rseed) & 1)
                    read_item;
                else
                    @(negedge rclk);
            end
        end

    join

    // Drain all entries left in the reference FIFO.
    while (count > 0)
        read_item;

    repeat(5) @(posedge rclk);

    if (count != 0)
        error("FIFO model not empty");

    if (rempty !== 1)
        error("FIFO not empty after randomized traffic");

    $display("PASS");
end
endtask

//============================================================
// Test 9 : Reset during active traffic
//============================================================

task test_reset_active;
begin
    test_no = test_no + 1;
    $display("\nTEST %0d : RESET DURING ACTIVE TRAFFIC", test_no);

    reset_fifo;

    write_item(8'hA1);
    write_item(8'hA2);
    write_item(8'hA3);

    repeat(3) @(posedge rclk);

    // Assert reset asynchronously to both clocks,
    // but each domain samples it synchronously.
    #13 rst = 1;

    @(posedge wclk);
    @(posedge rclk);
    #1;

    wr_ptr = 0;
    rd_ptr = 0;
    count  = 0;

    if (wfull !== 1'b0)
        error("wfull not cleared by reset");

    if (rempty !== 1'b1)
        error("rempty not asserted by reset");

    if (count != 0)
        error("reference queue not cleared");

    if (wfull === 1'b0 && rempty === 1'b1)
        $display("Reset correctly flushed FIFO. PASS");

    rst = 0;
end
endtask

//============================================================
// MAIN
//============================================================

initial begin

    rst = 1;
    winc = 0;
    rinc = 0;
    wdata = 0;

    wr_ptr = 0;
    rd_ptr = 0;
    count = 0;

    errors = 0;
    test_no = 0;

    accepted_writes = 0;
    accepted_reads = 0;
    rejected_writes = 0;
    rejected_reads = 0;

    repeat(3) @(posedge wclk);
    repeat(3) @(posedge rclk);

    rst = 0;

    test_reset;
    test_basic;
    test_full;
    test_empty;
    test_write_fast;
    test_read_fast;
    test_simultaneous;
    test_random;
    test_reset_active;

    $display("\n================================================");
    $display("VERIFICATION SUMMARY");
    $display("================================================");
    $display("Tests              : %0d", test_no);
    $display("Accepted writes    : %0d", accepted_writes);
    $display("Accepted reads     : %0d", accepted_reads);
    $display("Rejected writes    : %0d", rejected_writes);
    $display("Rejected reads     : %0d", rejected_reads);
    $display("Remaining entries  : %0d", count);
    $display("Errors             : %0d", errors);

    if (errors == 0)
        $display("ALL TESTS PASSED");
    else
        $display("VERIFICATION FAILED");

    $finish;
end

endmodule