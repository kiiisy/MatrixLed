//////////////////////////////////////////////////////////////
// モジュール :matrix_pg
// 概要      :マトリクスLEDのパターンジェネレーター
// 内容      :アニメーションするデータを生成
// 変更履歴   :2023/3/21 kiiisy 新規作成
/////////////////////////////////////////////////////////////
module matrix_pg (
    input   wire        clk_9m,
    input   wire        rst,
    input   wire        send_done,
    output  wire        en,
    output  wire [63:0] data [7:0]
);
    localparam COL_CNT_MAX  = 4'd7;
    localparam ROW_CNT_MAX  = 32'd32;
    localparam MASK         = 32'hffffffff;
    localparam DELAY_MAX    = 30'd300000;  // 111.11ns * 300000 = 33333000ns(約30Hz)

    typedef enum logic [2:0] {
        WAIT         = 3'b000,
        PACKING      = 3'b001,
        DELAY        = 3'b010
    } state_t;

    state_t      sts;
    reg   [31:0] row_cnt;
    reg   [31:0] cnt;
    wire  [31:0] masked_data;
    reg          en_r;
    reg   [ 3:0] col_cnt;
    reg   [ 3:0] addr_cnt;
    reg          send_done_r;
    wire         send_done_rise;
    reg   [63:0] data_r [7:0];
    reg   [29:0] delay_cnt;
    wire         delay_done;
    reg          paking_done_r;
    wire         paking_done;

    
    //////////////////////////////////////////////////////////////
    // ステートマシン
    // WAIT     :送信完了待ち状態
    // PACKING  :送信データ詰め中
    // DELAY    :en信号の出力待ち状態
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            sts <= WAIT;
        end else begin
            case(sts)
            WAIT: begin
                if(send_done) begin
                    sts <= PACKING;
                end
            end
            PACKING: begin
                if(paking_done) begin
                    sts <= DELAY;
                end
            end
            DELAY: begin
                if(delay_done) begin
                    sts <= WAIT;
                end
            end 
            default: begin
                sts <= WAIT;
            end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////
    // 送信データ生成
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            data_r[0] <= 64'd0;
            data_r[1] <= 64'd0;
            data_r[2] <= 64'd0;
            data_r[3] <= 64'd0;
            data_r[4] <= 64'd0;
            data_r[5] <= 64'd0;
            data_r[6] <= 64'd0;
            data_r[7] <= 64'd0;
        end else begin
            if(sts == PACKING) begin
                data_r[col_cnt] <= fix_data(addr_cnt, masked_data);
            end
        end
    end

    //////////////////////////////////////////////////////////////
    // 送信データ生成
    //////////////////////////////////////////////////////////////
    function [63:0] fix_data(
        input reg [ 3:0] addr_cnt,
        input reg [31:0] data
    );
        fix_data = {{{4'd0, addr_cnt[3:0]}, data[31:24]},
                    {{4'd0, addr_cnt[3:0]}, data[23:16]},
                    {{4'd0, addr_cnt[3:0]}, data[15:8]},
                    {{4'd0, addr_cnt[3:0]}, data[7:0]}};
    endfunction

    assign masked_data = MASK & row_cnt;

    //////////////////////////////////////////////////////////////
    // 送信データカウンタ(行)
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            row_cnt <= 32'd1;
            cnt     <= 32'd0; 
        end else begin
            if(send_done_rise) begin
                if(cnt == ROW_CNT_MAX) begin
                    row_cnt <= 32'd1;
                    cnt     <= 32'd0;
                end else begin
                    // 左にアニメーションしたいため左1シフトを行う
                    row_cnt <= row_cnt << 1'd1;
                    cnt     <= cnt + 1'd1;
                end
            end
        end
    end

    //////////////////////////////////////////////////////////////
    // 送信データカウンタ(列)
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            col_cnt  <= 4'd0;
            // マトリクスLEDはcolが1〜8なため
            addr_cnt <= 4'd1;
        end else begin
            if(sts == PACKING) begin
                if(col_cnt == COL_CNT_MAX) begin
                    col_cnt  <= 4'd0;
                    addr_cnt <= 4'd1;
                end else begin
                    col_cnt  <= col_cnt + 4'd1;
                    addr_cnt <= addr_cnt + 4'd1;
                end
            end
        end
    end

    //////////////////////////////////////////////////////////////
    // pack完了信号生成
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            paking_done_r <= 1'd0;
        end else begin
            if(sts == PACKING) begin
                if(col_cnt == COL_CNT_MAX) begin
                    paking_done_r <= 1'd1;
                end
            end else begin
                paking_done_r <= 1'd0;
            end
        end
    end

    assign paking_done = paking_done_r;

    //////////////////////////////////////////////////////////////
    // delay信号生成
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            delay_cnt <= 30'd0;
        end else begin
            if(sts == DELAY) begin
                if(delay_cnt == DELAY_MAX) begin
                    delay_cnt <= 30'd0;
                end else begin
                    delay_cnt <= delay_cnt + 30'd1;
                end
            end
        end
    end

    assign delay_done = (delay_cnt == DELAY_MAX) ? 1'd1 : 1'd0;

    //////////////////////////////////////////////////////////////
    // send_doneの立ち上がりエッジ検出
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            send_done_r <= 1'd0;
        end else begin
            send_done_r <= send_done;
        end
    end

    assign send_done_rise = ~send_done_r & send_done;

    //////////////////////////////////////////////////////////////
    // 出力
    //////////////////////////////////////////////////////////////
    assign en    = delay_done ? 1'd1 : 1'd0;
    assign data  = data_r;

endmodule