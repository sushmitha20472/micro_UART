module uart #(
    parameter W        = 8,
    parameter BAUD     = 2400,
    parameter XTAL_CLK = 50000000
)(
    input  wire         sys_clk,
    input  wire         sys_rst,
    input  wire         xmitH,
    input  wire [W-1:0] xmit_dataH,
    output wire         uart_XMIT,
    output wire         xmit_doneH,
    output wire         xmit_active,
    output wire         uart_clk,
    input  wire         uart_REC_dataH,
    output wire [W-1:0] rec_dataH,
    output wire         rec_readyH,
    output wire         rec_busy
);

    u_baud #(
        .XTAL_CLK (XTAL_CLK),
        .BAUD     (BAUD)
    ) baud_inst (
        .sys_clk  (sys_clk),
        .sys_rst  (sys_rst),
        .uart_clk (uart_clk)
    );

    u_xmit #(
        .W (W)
    ) xmit_inst (
        .sys_clk    (sys_clk),
        .sys_rst    (sys_rst),
        .uart_clk   (uart_clk),
        .xmitH      (xmitH),
        .xmit_dataH (xmit_dataH),
        .uart_XMIT  (uart_XMIT),
        .xmit_doneH (xmit_doneH),
        .xmit_active(xmit_active)
    );

    u_rec #(
        .W (W)
    ) rec_inst (
        .sys_clk        (sys_clk),
        .sys_rst        (sys_rst),
        .uart_clk       (uart_clk),
        .uart_REC_dataH (uart_REC_dataH),
        .rec_dataH      (rec_dataH),
        .rec_readyH     (rec_readyH),
        .rec_busy       (rec_busy)
    );

endmodule
