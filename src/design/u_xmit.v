module u_xmit #(
    parameter W = 8
)(
    input  wire         sys_clk,
    input  wire         sys_rst,
    input  wire         uart_clk,
    input  wire         xmitH,
    input  wire [W-1:0] xmit_dataH,
    output reg          uart_XMIT,
    output reg          xmit_doneH,
    output reg          xmit_active
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0]   state, next_state;
    reg [W-1:0] shift_reg;
    reg [3:0]   baud_cnt;
    reg [3:0]   bit_cnt;


    always @(posedge uart_clk or negedge sys_rst) begin
        if (!sys_rst) state <= IDLE;
        else         state <= next_state;
    end


    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (xmitH)                                    next_state = START;
            START: if (baud_cnt == 4'd15)                        next_state = DATA;
            DATA:  if (baud_cnt == 4'd15 && bit_cnt == W - 1)   next_state = STOP;
            STOP:  if (baud_cnt == 4'd15)                        next_state = IDLE;
        endcase
    end


    always @(*) begin
       
        uart_XMIT   = 1'b1;
        xmit_doneH  = 1'b0;
        xmit_active = 1'b0;

        case (state)
            IDLE: begin
                uart_XMIT   = 1'b1;
                xmit_doneH  = 1'b1;  
                xmit_active = 1'b0;
            end
            START: begin
                uart_XMIT   = 1'b0;
                xmit_doneH  = 1'b0;
                xmit_active = 1'b1;
            end
            DATA: begin
                uart_XMIT   = shift_reg[0];
                xmit_doneH  = 1'b0;
                xmit_active = 1'b1;
            end
            STOP: begin
                uart_XMIT   = 1'b1;
                xmit_doneH  = 1'b0;
                xmit_active = 1'b1;
            end
        endcase
    end

    always @(posedge uart_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            shift_reg <= 0;
            baud_cnt  <= 4'd0;
            bit_cnt   <= 4'd0;
            
        end
        else begin
            case (state)
                IDLE: begin
                    baud_cnt <= 4'd0;
                    bit_cnt  <= 4'd0;
                    if (xmitH)
                        shift_reg <= xmit_dataH;
                end
                START: begin
                    if (baud_cnt == 4'd15)
                        baud_cnt <= 4'd0;
                    else
                        baud_cnt <= baud_cnt + 1;
                end
                DATA: begin
                    if (baud_cnt == 4'd15) begin
                        baud_cnt  <= 4'd0;
                        shift_reg <= shift_reg >> 1;
                        if (bit_cnt == W - 1)
                            bit_cnt <= 4'd0;
                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                    else
                        baud_cnt <= baud_cnt + 1;
                end
                STOP: begin
                    if (baud_cnt == 4'd15)
                        baud_cnt <= 4'd0;
                    else
                        baud_cnt <= baud_cnt + 1;
                end
            endcase
        end
    end

endmodule
