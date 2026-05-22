module u_rec #(
    parameter W = 8
)(
    input  wire         sys_clk,
    input  wire         sys_rst,
    input  wire         uart_clk,
    input  wire         uart_REC_dataH,
    output reg  [W-1:0] rec_dataH,
    output reg          rec_readyH,
    output reg          rec_busy
);

    localparam IDLE   = 2'd0;
    localparam CENTER = 2'd1;
    localparam DATA   = 2'd2;
    localparam STOP   = 2'd3;

    reg sync_ff1, sync_ff2, sync_prev;

    reg [1:0]   state, next_state;
    reg [W-1:0] shift_reg;
    reg [3:0]   baud_cnt;
    reg [3:0]   bit_cnt;


    always @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            sync_ff1 <= 1'b1;
            sync_ff2 <= 1'b1;
        end
        else begin
            sync_ff1 <= uart_REC_dataH;
            sync_ff2 <= sync_ff1;
        end
    end


    always @(posedge uart_clk or negedge sys_rst) begin
        if (!sys_rst) state <= IDLE;
        else         state <= next_state;
    end


    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (sync_prev == 1'b1 && sync_ff2 == 1'b0) next_state = CENTER;
            CENTER: if (baud_cnt == 4'd7)                       next_state = DATA;
            DATA:   if (baud_cnt == 4'd15 && bit_cnt == W - 1) next_state = STOP;
            STOP:   if (baud_cnt == 4'd15)                      next_state = IDLE;
        endcase
    end



    always @(*) begin

    
    rec_readyH = 1'b0;
    rec_busy   = 1'b0;

    case (state)

        
        IDLE: begin
            rec_readyH = 1'b1;
            rec_busy   = 1'b0;
        end

        
        CENTER: begin
            rec_readyH = 1'b0;
            rec_busy   = 1'b1;
        end

        
        DATA: begin
            rec_readyH = 1'b0;
            rec_busy   = 1'b1;
        end

       
        STOP: begin
            rec_busy = 1'b1;

            
            if (baud_cnt == 4'd15)
                rec_readyH = 1'b1;
            else
                rec_readyH = 1'b0;
        end

    endcase
end

    always @(posedge uart_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            shift_reg <= 0;
            rec_dataH <= 0;
            baud_cnt  <= 4'd0;
            bit_cnt   <= 4'd0;
            sync_prev <= 1'b1;
           
        end
        else begin
            sync_prev <= sync_ff2;

            case (state)

                IDLE: begin
                    baud_cnt <= 4'd0;
                    bit_cnt  <= 4'd0;
                end

                CENTER: begin
                    if (baud_cnt == 4'd7)
                        baud_cnt <= 4'd0;
                    else
                        baud_cnt <= baud_cnt + 1;
                end

                DATA: begin
                    if (baud_cnt == 4'd15) begin
                        baud_cnt  <= 4'd0;
                        shift_reg <= {sync_ff2, shift_reg[W-1:1]};
                        if (bit_cnt == W - 1)
                            bit_cnt <= 4'd0;
                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                    else
                        baud_cnt <= baud_cnt + 1;
                end

                STOP: begin
                    if (baud_cnt == 4'd15) begin
                        baud_cnt  <= 4'd0;
                        rec_dataH <= shift_reg;
                    end
                    else
                        baud_cnt <= baud_cnt + 1;
                end

            endcase
        end
    end

endmodule
