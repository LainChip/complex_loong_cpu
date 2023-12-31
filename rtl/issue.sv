`include "pipeline.svh"

module issue(
  input logic clk,
  input logic rst_n,
  input inst_t[1:0] inst_i,
  input logic[1:0] d_valid_i, // 2'b00 | 2'b01 | 2'b11

  input ex_ready_i,
  output ex_valid_o,
  output logic[1:0] is_o // 2'b00 | 01 | 11
);

logic structural_conflict;
logic data_conflict      ;

assign data_conflict = ((inst_i[0].reg_info.w_reg[0] == inst_i[1].reg_info.w_reg[0]
    && |inst_i[1].reg_info.w_reg) ||         // 避免 WAW 冲突
  (inst_i[0].reg_info.w_reg == inst_i[1].reg_info.r_reg[0] ||
    inst_i[0].reg_info.w_reg == inst_i[1].reg_info.r_reg[1])) && // 只有第一条指令写寄存器，才有可能发生数据冲突
|inst_i[0].reg_info.w_reg ;

assign structural_conflict = (
  ( inst_i[0].decode_info.need_csr ||
    /* THIS INST CAN ONLY BE EXCUTED IN PIPE0 */
    inst_i[1].decode_info.need_csr) ||
  ( inst_i[0].decode_info.invalid_inst ||
    /* THIS INST CAN ONLY BE EXCUTED IN PIPE0 */
    inst_i[1].decode_info.invalid_inst) ||
  (inst_i[0].decode_info.need_mul && inst_i[1].decode_info.need_mul) ||
  (inst_i[0].decode_info.need_div && inst_i[1].decode_info.need_div) ||
  (inst_i[0].decode_info.need_lsu && inst_i[1].decode_info.need_lsu) ||
  // (inst_i[0].decode_info.need_lsu && (inst_i[1].decode_info.mem_write || inst_i[1].decode_info.mem_cacop)) ||
  // ((inst_i[0].decode_info.mem_write || inst_i[0].decode_info.mem_cacop) && inst_i[1].decode_info.need_lsu)// ||
  (inst_i[0].decode_info.need_bpu && inst_i[1].decode_info.need_bpu) 
  );

assign is_o[0]    = ex_ready_i && d_valid_i[0];
assign is_o[1]    = ex_ready_i && d_valid_i[1] && !data_conflict && !structural_conflict;
assign ex_valid_o = d_valid_i[0];
endmodule
