module u_baud #(
    parameter XTAL_CLK = 50000000,
    parameter BAUD     = 2400
)(
    input  wire sys_clk,
    input  wire sys_rst,
    output reg  uart_clk
);

    localparam CLK_DIV = XTAL_CLK / (BAUD * 16 * 2);
    localparam CW      = $clog2(CLK_DIV) + 1;

    reg [CW-1:0] count;

    always @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            count    <= 0;
            uart_clk <= 0;
        end
        else begin
            if (count == CLK_DIV - 1) begin
                count    <= 0;
                uart_clk <= ~uart_clk;
            end
            else
                count <= count + 1;
        end
    end

endmodule
