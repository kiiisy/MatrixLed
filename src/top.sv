//////////////////////////////////////////////////////////////
// モジュール :top
// 概要      :トップモジュール
// 内容      :トップモジュール
// 変更履歴   :2023/3/21 kiiisy 新規作成
/////////////////////////////////////////////////////////////
module top(
    input   wire  CLK_27M,
    input   wire  RST_N,
    output  wire  CS,
    output  wire  CLK_9M,
    output  wire  DOUT
);
    wire        pll_rst;
    reg         lock_en;

    pll U_pll(
        .clkin    (CLK_27M   ),
        .reset    (~RST_N    ),
        .clkout   (CLK_9M    ),
        .lock     (lock_en   )
    );

    assign pll_rst = RST_N & ~lock_en;

    matrix_top U_matrix_top(
        .clk_9m   ( CLK_9M   ),
        .pll_rst  ( pll_rst  ),
        .cs       ( CS       ),
        .dout     ( DOUT     )
    );

endmodule