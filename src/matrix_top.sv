//////////////////////////////////////////////////////////////
// モジュール :matrix_top
// 概要      :マトリクスLEDのトップモジュール
// 内容      :パターンジェネレーター部とコア部を管理
// 変更履歴   :2023/3/21 kiiisy 新規作成
/////////////////////////////////////////////////////////////
module matrix_top(
    input   wire        clk_9m,
    input   wire        pll_rst,
    output  wire        cs,
    output  wire        dout
);
    wire        en;
    wire        send_done;
    wire [63:0] data [7:0];

    matrix_pg U_matrix_pg(
        .clk_9m     ( clk_9m     ), // in
        .rst        ( pll_rst    ), // in
        .send_done  ( send_done  ), // in
        .en         ( en         ), // out
        .data       ( data       )  // out
    );

    matrix_core U_matrix_core(
        .clk_9m     ( clk_9m     ), // in
        .rst        ( pll_rst    ), // in
        .en         ( en         ), // in
        .din        ( data       ), // in
        .send_done  ( send_done  ), // out
        .cs         ( cs         ), // out
        .dout       ( dout       )  // out
    );

endmodule