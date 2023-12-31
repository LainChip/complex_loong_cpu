`include "pipeline.svh"

/*--JSON--{"module_name":"core_divider_manager","module_ver":"1","module_type":"module"}--JSON--*/
// 注意：接口发生变化，老版本不可用

module core_divider_manager(
    input logic clk,
    input logic rst_n,

    input logic[31:0] r0_i,
    input logic[31:0] r1_i,
    input logic[1:0] op_i,
    input logic push_valid_i,
    output logic push_ready_o,
    input logic[2:0] push_id_i,

    input logic wb_stall_i,
    input logic[2:0] pop_id_i,  // CONNECT TO M2
    output logic result_valid_o,
    output logic[31:0] result_o
  );

  logic div_finish;
  logic[31:0] mod_result, div_result;
  logic[2:0] calculating_id_q;
  logic calculating_mod_q,calculating_mod;
  // VALID TABLE
  logic[7:0] valid_table_q;
  logic[7:0][31:0] result_q;
  always_ff@(posedge clk) begin
    if(push_valid_i & push_ready_o) begin
      valid_table_q[push_id_i] <= '0;
      calculating_id_q <= push_id_i;
    end
    else begin
      if(div_finish) begin
        valid_table_q[calculating_id_q] <= '1;
        result_q[calculating_id_q] <= calculating_mod_q ? mod_result : div_result;
      end
    end
  end

  logic div_busy_q,div_busy;
  logic[2:0] pop_id_skid_q;
  always_ff @(posedge clk) begin
    if(!wb_stall_i) begin
      pop_id_skid_q <= pop_id_i;
      result_valid_o <= valid_table_q[pop_id_i];
      result_o <= result_q[pop_id_i];
    end
    else begin
      result_valid_o <= valid_table_q[pop_id_skid_q];
      result_o <= result_q[pop_id_skid_q];
    end
  end
  always_ff @(posedge clk) begin
    if(~rst_n) begin
      div_busy_q <= '0;
    end
    else begin
      div_busy_q <= div_busy;
      calculating_mod_q <= calculating_mod;
    end
  end
  always_comb begin
    div_busy = div_busy_q;
    calculating_mod = calculating_mod_q;
    if(div_busy_q) begin
      if(div_finish) begin
        div_busy = '0;
      end
    end
    else begin
      if(push_valid_i) begin
        div_busy = '1;
        calculating_mod = op_i[1];
      end
    end
  end
  assign push_ready_o = ~div_busy_q;

  // divider  divider_i (
  //            .clk(clk),
  //            .rst_n(rst_n),
  //            .div_valid(push_valid_i & push_ready_o),
  //            .div_ready(),
  //            .res_valid(div_finish),
  //            .res_ready(1'b1),
  //            .div_signed_i(~op_i[0]),
  //            .Z_i(r1_i),
  //            .D_i(r0_i),
  //            .q_o(div_result),
  //            .s_o(mod_result)
  //          );
  logic div_core_busy;
  assign div_finish = ~div_core_busy;
  fast_div  fast_div_inst (
            .clk(clk),
            .rst_n(rst_n),
            .A(r1_i),
            .B(r0_i),
            .HI(mod_result),
            .LO(div_result),
            .start(push_valid_i & push_ready_o),
            .sign(~op_i[0]),
            .busy(div_core_busy)
          );
endmodule
