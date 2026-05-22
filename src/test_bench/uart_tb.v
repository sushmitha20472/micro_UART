`timescale 1ns/1ps

module uart_tb;

parameter N = 8;
parameter baud_rate = 2400;
parameter XTAL_CLK  = 50000000;

reg sys_clk;
reg sys_rst_l;

reg xmitH;
reg [N-1:0] xmit_dataH;

wire uart_XMIT_dataH;
wire xmit_doneH;
wire xmit_active;

wire rec_readyH;
wire rec_busy;
wire [N-1:0] rec_dataH;

wire uart_wire;

reg [7:0]i;

assign uart_wire = uart_XMIT_dataH;

///////////////////////////////////////////////////////////
// DUT
///////////////////////////////////////////////////////////

uart #(
    .W(N),
    .BAUD(baud_rate),
    .XTAL_CLK(XTAL_CLK)
) dut (
    .sys_clk(sys_clk),
    .sys_rst(sys_rst_l),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_XMIT(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active),

    .uart_clk(),

    .uart_REC_dataH(uart_wire),

    .rec_dataH(rec_dataH),
    .rec_readyH(rec_readyH),
    .rec_busy(rec_busy)
);

///////////////////////////////////////////////////////////
// CLOCK GENERATION
///////////////////////////////////////////////////////////

initial begin
    sys_clk = 0;
    forever #10 sys_clk = ~sys_clk;
end

///////////////////////////////////////////////////////////
// RESET TASK
///////////////////////////////////////////////////////////

task dut_reset;
begin

    sys_rst_l  = 0;
    xmitH      = 0;
    xmit_dataH = 0;

    #200;

    sys_rst_l = 1;

    repeat(20) @(posedge sys_clk);

end
endtask

///////////////////////////////////////////////////////////
// SCOREBOARD
///////////////////////////////////////////////////////////

task scoreboard;
input [N-1:0] sent_data;
begin

    repeat(20) @(posedge dut.uart_clk);

    if(rec_dataH === sent_data)
        $display("PASS : SENT=%h RECEIVED=%h",
                 sent_data,
                 rec_dataH);
    else
        $display("FAIL : SENT=%h RECEIVED=%h",
                 sent_data,
                 rec_dataH);

end
endtask

///////////////////////////////////////////////////////////
// DRIVER
///////////////////////////////////////////////////////////

task driver;
input [N-1:0] data;
begin

    @(posedge sys_clk);

    xmit_dataH <= data;
    xmitH      <= 1'b1;

    repeat(2) @(posedge dut.uart_clk);

    xmitH <= 1'b0;

    wait(xmit_active == 1'b1);

    wait(xmit_active == 1'b0);

    repeat(30) @(posedge dut.uart_clk);

    scoreboard(data);

end
endtask

///////////////////////////////////////////////////////////
// MAIN TEST
///////////////////////////////////////////////////////////

initial begin

    ///////////////////////////////////////////////////////
    // RESET
    ///////////////////////////////////////////////////////

    dut_reset;

    ///////////////////////////////////////////////////////
    // DIRECTED TESTS
    ///////////////////////////////////////////////////////

    driver(8'h55);
    driver(8'hAA);

    driver(8'h00);
    driver(8'hFF);

    driver(8'h0F);
    driver(8'hF0);

    driver(8'h33);
    driver(8'hCC);

    driver(8'h01);
    driver(8'h80);

    driver(8'h7E);
    driver(8'h81);

    ///////////////////////////////////////////////////////
    // RANDOM TESTS
    ///////////////////////////////////////////////////////

    for(i = 0; i < 50; i = i + 1)
        driver($random);

    ///////////////////////////////////////////////////////
    // BACK TO BACK TRANSFERS
    ///////////////////////////////////////////////////////

    repeat(20) begin

        @(posedge sys_clk);

        xmit_dataH <= $random;
        xmitH      <= 1'b1;

        @(posedge dut.uart_clk);

        xmitH <= 1'b0;

        wait(xmit_doneH);

    end

    ///////////////////////////////////////////////////////
    // RESET DURING TX START
    ///////////////////////////////////////////////////////

    @(posedge sys_clk);

    xmit_dataH <= 8'h55;
    xmitH      <= 1'b1;

    repeat(1) @(posedge dut.uart_clk);

    sys_rst_l <= 0;

    #100;

    sys_rst_l <= 1;

    xmitH <= 0;

    repeat(50) @(posedge sys_clk);

    ///////////////////////////////////////////////////////
    // RESET DURING MID TRANSMISSION
    ///////////////////////////////////////////////////////

    @(posedge sys_clk);

    xmit_dataH <= 8'hAA;
    xmitH      <= 1'b1;

    repeat(60) @(posedge dut.uart_clk);

    sys_rst_l <= 0;

    #100;

    sys_rst_l <= 1;

    xmitH <= 0;

    repeat(100) @(posedge sys_clk);

    ///////////////////////////////////////////////////////
    // RX FALSE START BIT
    // Covers CENTER -> IDLE transition
    ///////////////////////////////////////////////////////

    force uart_wire = 1'b0;

    repeat(2) @(posedge dut.uart_clk);

    force uart_wire = 1'b1;

    repeat(20) @(posedge dut.uart_clk);

    release uart_wire;

    ///////////////////////////////////////////////////////
    // RX GLITCHES
    // Covers sync_prev conditions
    ///////////////////////////////////////////////////////

    force uart_wire = 1'b0;
    @(posedge dut.uart_clk);

    force uart_wire = 1'b1;
    @(posedge dut.uart_clk);

    force uart_wire = 1'b0;
    @(posedge dut.uart_clk);

    release uart_wire;

    repeat(20) @(posedge dut.uart_clk);

    ///////////////////////////////////////////////////////
    // FORCE ILLEGAL RX FSM STATE
    ///////////////////////////////////////////////////////

    force dut.rec_inst.state = 3'b111;

    repeat(5) @(posedge dut.uart_clk);

    release dut.rec_inst.state;

    repeat(20) @(posedge dut.uart_clk);

    ///////////////////////////////////////////////////////
    // FORCE ILLEGAL TX FSM STATE
    ///////////////////////////////////////////////////////

    force dut.xmit_inst.state = 3'b111;

    repeat(5) @(posedge dut.uart_clk);

    release dut.xmit_inst.state;

    repeat(20) @(posedge dut.uart_clk);

    ///////////////////////////////////////////////////////
    // NOISE INJECTION
    ///////////////////////////////////////////////////////

    repeat(10) begin

        force uart_wire = $random;

        @(posedge dut.uart_clk);

        release uart_wire;

        @(posedge dut.uart_clk);

    end

    ///////////////////////////////////////////////////////
    // LONG RANDOM STRESS
    ///////////////////////////////////////////////////////

    for(i = 0; i < 100; i = i + 1)
        driver($random);

    ///////////////////////////////////////////////////////
    // FINAL TESTS
    ///////////////////////////////////////////////////////

    driver(8'hFF);

    scoreboard(8'h00);
///////////////////////////////////////////////////////
// TOGGLE COVERAGE BOOST
///////////////////////////////////////////////////////

driver(8'h00);
driver(8'hFF);

driver(8'h7F);
driver(8'h80);

driver(8'h40);
driver(8'hBF);

driver(8'h20);
driver(8'hDF);

driver(8'h10);
driver(8'hEF);

driver(8'h08);
driver(8'hF7);

driver(8'h04);
driver(8'hFB);

driver(8'h02);
driver(8'hFD);

driver(8'h01);
driver(8'hFE);

///////////////////////////////////////////////////////
// EXTRA RANDOMS
///////////////////////////////////////////////////////

for(i = 0; i < 200; i = i + 1)
    driver($urandom);
    #1000;

    $display("======================================");
    $display("      SIMULATION COMPLETED");
    $display("======================================");
	

    $finish;

end

endmodule
