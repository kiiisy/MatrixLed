//////////////////////////////////////////////////////////////
// モジュール :top_sim
// 概要      :シナリオトップ
// 内容      :シナリオトップ
// 変更履歴   :2023/3/21 kiiisy 新規作成
/////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module top_sim;

// Create clock
parameter CLK_27MHz_PERIOD = 37; // ns

// Iputs, Outputs
logic       clk;
logic       rst_n;

// Device under test
top dut(
  .CLK_27M    (clk    ),
  .RST_N      (rst_n  ),
  .CS         (       ), // nouse
  .CLK_9M     (       ), // nouse
  .DOUT       (       )  // nouse
);

initial begin
  clk   = 'b0;
  rst_n = 'b0;
  #10;
  rst_n = 'b1;
end

// clock
always #(CLK_27MHz_PERIOD/2) begin
  clk <= ~clk;
end

///////////////////////////////////////////////////
// Test case
///////////////////////////////////////////////////
initial begin

  $dumpfile("scenario.vcd");
  $dumpvars(0, top_sim);

  $display("start sim");

  #1000000;

  $finish;

end

endmodule
