//////////////////////////////////////////////////////////////
// モジュール :matrix_core
// 概要      :マトリクスLEDのドライバー
// 内容      :マトリクスLEDに対してデータを送信する
// 変更履歴   :2023/3/21 kiiisy 新規作成
/////////////////////////////////////////////////////////////
module matrix_core(
    input   wire        clk_9m,
    input   wire        rst,
    input   wire        en,
    input   wire [63:0] din [7:0],
    output  wire        send_done,
    output  wire        cs,
    output  wire        dout
);
    localparam REG_NO_DECODE      = 16'h0900; // No decode for digits 7-0 
    localparam REG_INTENSITY      = 16'h0a04; // 輝度 15/32
    localparam REG_DISPLAY_DIGITS = 16'h0b07; // Display digits 0 1 2 3 4 5 6 7
    localparam REG_NORMAL_OP      = 16'h0c01; // Normal Operation
    localparam INIT_SENDING       = 1'b0;
    localparam IDLE_SENDING       = 1'b1;
    localparam INIT_DATA_MAX      = 4'd3;
    localparam IDLE_DATA_MAX      = 4'd7;

    typedef enum logic [3:0] {
        INIT         = 4'b0000,
        IDLE         = 4'b0001,
        SETTING      = 4'b0010,
        SENDING      = 4'b0100
    } state_t;

    state_t     sts;
    reg         cs_r;
    reg         sending_type;
    reg  [63:0] dout_buffer [7:0];
    reg  [ 3:0] col_cnt;
    reg  [ 3:0] col_cnt_max;
    wire        col_cnt_max_flg;
    reg         one_line_done_r;
    wire        one_line_done;
    reg         dout_r;
    reg  [ 3:0] col;
    reg  [ 7:0] row;
    reg         send_done_r;

    //////////////////////////////////////////////////////////////
    // ステートマシン
    // INIT     :初期化状態
    // IDLE     :遊休状態
    // SETTING  :送信データの用意中
    // SENDING  :送信中
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            sts <= INIT;
        end else begin
            case(sts)
                INIT: begin
                    sts <= SETTING;
                end
                IDLE: begin
                    if(en) begin
                        sts <= SETTING;
                    end
                end
                SETTING: begin
                    if(col_cnt_max_flg) begin
                        sts <= SENDING;
                    end
                end
                SENDING: begin
                    if(send_done) begin
                        sts <= IDLE;
                    end
                end
                default: begin
                    sts <= INIT;
                end
            endcase
        end
    end

   //////////////////////////////////////////////////////////////
   // ステートマシン処理部
   //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            dout_r       <= 1'd0;
            col_cnt_max  <= INIT_DATA_MAX;
            sending_type <= INIT_SENDING;
        end else begin
            case(sts)
                INIT: begin
                    sending_type <= INIT_SENDING;
                    col_cnt_max  <= INIT_DATA_MAX;
                end
                IDLE: begin
                    sending_type <= IDLE_SENDING;
                    col_cnt_max  <= IDLE_DATA_MAX;
                end
                SETTING: begin
                    // 起動時のデータ初期設定
                    if(sending_type == INIT_SENDING) begin
                        case(col_cnt)
                            5'd0: begin
                                dout_buffer[col_cnt] <= {REG_NO_DECODE, REG_NO_DECODE, REG_NO_DECODE, REG_NO_DECODE};
                            end
                            5'd1: begin
                                dout_buffer[col_cnt] <= {REG_INTENSITY, REG_INTENSITY, REG_INTENSITY, REG_INTENSITY};
                            end
                            5'd2: begin
                                dout_buffer[col_cnt] <= {REG_DISPLAY_DIGITS, REG_DISPLAY_DIGITS, REG_DISPLAY_DIGITS, REG_DISPLAY_DIGITS};
                            end
                            5'd3: begin
                                dout_buffer[col_cnt] <= {REG_NORMAL_OP, REG_NORMAL_OP, REG_NORMAL_OP, REG_NORMAL_OP};
                            end
                            default: begin
                                dout_buffer[0] <= 64'd0;
                                dout_buffer[1] <= 64'd0;
                                dout_buffer[2] <= 64'd0;
                                dout_buffer[3] <= 64'd0;
                                dout_buffer[4] <= 64'd0;
                                dout_buffer[5] <= 64'd0;
                                dout_buffer[6] <= 64'd0;
                                dout_buffer[7] <= 64'd0;
                            end
                        endcase
                    // 通常時のデータ設定
                    end else begin
                        dout_buffer[col_cnt] <= din[col_cnt];
                    end
                end
                SENDING: begin
                    dout_r <= dout_buffer[col][row];
                end
                default: begin
                    dout_r <= 1'd0;
                end
            endcase
        end
    end

    //////////////////////////////////////////////////////////////
    // cs信号
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            cs_r <= 1'd1;
        end else begin
            if(sts == SENDING) begin
                // 全データ又は1ライン送信後にcsをアサート
                if(send_done || one_line_done) begin
                    cs_r   <= 1'd1;
                end else begin
                    cs_r   <= 1'd0;
                end
            end else begin
                cs_r <= 1'd1;
            end
        end
    end

    //////////////////////////////////////////////////////////////
    // 送信データカウンタ(MSBファースト)
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            col <= 4'd0;
            row <= 8'd63;
        end else begin
            if(sts == SENDING) begin
                // 全てのデータを送信した場合
                if(col == col_cnt_max && row == 8'd0) begin
                    col <= 4'd0;
                    row <= 8'd63;
                // 1ライン送信した場合
                end else if(row == 8'd0) begin
                    row <= 8'd63;
                    col <= col + 4'd1;
                // 1ライン送信中の場合
                end else begin
                    row <= row - 8'd1;
                end
            end
        end
    end

    //////////////////////////////////////////////////////////////
    // 1ライン完了信号
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            one_line_done_r <= 1'd0;
        end else begin
            if(row == 8'd0) begin
                one_line_done_r <= 1'd1;
            end else begin
                one_line_done_r <= 1'd0;
            end
        end
    end

    assign one_line_done = one_line_done_r;

    //////////////////////////////////////////////////////////////
    // columnカウンタ(SETTING状態時)
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            col_cnt = 4'd0;
        end else begin
            if(sts == SETTING) begin
                if(col_cnt == col_cnt_max) begin
                    col_cnt <= 4'd0;
                end else begin
                    col_cnt <= col_cnt + 4'd1;
                end
            end
        end
    end

    assign col_cnt_max_flg = (col_cnt == col_cnt_max) ? 1'd1 : 1'd0;

    //////////////////////////////////////////////////////////////
    // 全データ送信完了信号
    //////////////////////////////////////////////////////////////
    always @(posedge rst or posedge clk_9m) begin
        if(rst) begin
            send_done_r <= 1'd0;
        end else begin
            if(col == col_cnt_max && row == 8'd0) begin
                send_done_r <= 1'd1;
            end else begin
                send_done_r <= 1'd0;
            end
        end
    end

    assign send_done = send_done_r;

    //////////////////////////////////////////////////////////////
    // 出力
    //////////////////////////////////////////////////////////////
    assign dout            = cs_r ? 1'b0 : dout_r;
    assign cs              = cs_r;

endmodule