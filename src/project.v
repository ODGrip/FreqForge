/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_odgrip_freq_forge (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered
    input  wire       clk,      // reference clock
    input  wire       rst_n     // reset_n - low to reset
);

    // // ------------------------------------------------------------------------
    // // Pin mapping for this first all-digital test
    // // ------------------------------------------------------------------------
    // //
    // // ui_in[7:0]   = direct_word[7:0]
    // //
    // // uio_in[1:0]  = mode
    // //                00 = PWM
    // //                01 = direct_word
    // //                10 = I/Q
    // //                11 = manual DCO code
    // //
    // // uio_in[2]    = enable
    // // uio_in[3]    = freeze_fll
    // // uio_in[4]    = pwm_in
    // // uio_in[5]    = i_in[0]
    // // uio_in[6]    = i_in[1]
    // // uio_in[7]    = i_in[2]
    // //
    // // For now:
    // // - q_in is tied to 0
    // // - manual_dco_code is tied to 0
    // // - DCO outputs are stubbed to 0
    // //
    // // uo_out mapping:
    // // uo_out[7]    = lock
    // // uo_out[6]    = sat_hi
    // // uo_out[5]    = sat_lo
    // // uo_out[4]    = meas_valid
    // // uo_out[3:0]  = dco_code_dbg[3:0]
    // // ------------------------------------------------------------------------

    // wire [1:0] mode        = uio_in[1:0];
    // wire       core_enable = uio_in[2] & ena;
    // wire       freeze_fll  = uio_in[3];
    // wire       pwm_in      = uio_in[4];

    // wire [3:0] i_in = {uio_in[7], uio_in[6], uio_in[5], 1'b0};
    // wire [3:0] q_in = 4'b0000;

    // wire [7:0] direct_word     = ui_in;
    // wire [7:0] manual_dco_code = 8'h00;

    // // Fixed config for first test
    // wire [7:0] base_count  = 8'd100;
    // wire [7:0] scale_shift = 8'd2;
    // wire [7:0] deadband    = 8'd1;
    // wire [7:0] lock_tol    = 8'd1;

    // wire       clk_hf;
    // wire       clk_div;
    // wire [7:0] cmd_value_dbg;
    // wire [7:0] target_count_dbg;
    // wire [7:0] meas_count_dbg;
    // wire [7:0] dco_code_dbg;
    // wire       lock;
    // wire       sat_hi;
    // wire       sat_lo;
    // wire       meas_valid_dbg;

    // dco_fm_digital_top u_core (
    //     .clk_ref          (clk),
    //     .rst_n            (rst_n),

    //     .enable           (core_enable),
    //     .freeze_fll       (freeze_fll),
    //     .mode             (mode),

    //     .pwm_in           (pwm_in),
    //     .direct_word      (direct_word),
    //     .i_in             (i_in),
    //     .q_in             (q_in),
    //     .manual_dco_code  (manual_dco_code),

    //     .base_count       (base_count),
    //     .scale_shift      (scale_shift),
    //     .deadband         (deadband),
    //     .lock_tol         (lock_tol),

    //     .clk_hf           (clk_hf),
    //     .clk_div          (clk_div),

    //     .cmd_value_dbg    (cmd_value_dbg),
    //     .target_count_dbg (target_count_dbg),
    //     .meas_count_dbg   (meas_count_dbg),
    //     .dco_code_dbg     (dco_code_dbg),
    //     .lock             (lock),
    //     .sat_hi           (sat_hi),
    //     .sat_lo           (sat_lo),
    //     .meas_valid_dbg   (meas_valid_dbg)
    // );

    // // Debug outputs
    // assign uo_out[7]   = lock;
    // assign uo_out[6]   = sat_hi;
    // assign uo_out[5]   = sat_lo;
    // assign uo_out[4]   = meas_valid_dbg;
    // assign uo_out[3:0] = dco_code_dbg[3:0];

    // All bidirectional pins remain inputs in this first test
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

endmodule


// // ----------------------------------------------------------------------------
// // Digital core from previous step
// // ----------------------------------------------------------------------------

// module dco_fm_digital_top #(
//     parameter integer CMD_W           = 8,
//     parameter integer TARGET_W        = 8,
//     parameter integer DCO_CODE_W      = 8,
//     parameter integer DCO_COUNTER_W   = 16,
//     parameter integer WINDOW_REF_CYC  = 25,
//     parameter integer DIVIDER_BITS    = 4
// ) (
//     input  wire        clk_ref,
//     input  wire        rst_n,

//     input  wire        enable,
//     input  wire        freeze_fll,
//     input  wire [1:0]  mode,

//     input  wire        pwm_in,
//     input  wire [7:0]  direct_word,
//     input  wire [3:0]  i_in,
//     input  wire [3:0]  q_in,
//     input  wire [7:0]  manual_dco_code,

//     input  wire [7:0]  base_count,
//     input  wire [7:0]  scale_shift,
//     input  wire [7:0]  deadband,
//     input  wire [7:0]  lock_tol,

//     output wire        clk_hf,
//     output wire        clk_div,

//     output wire [7:0]  cmd_value_dbg,
//     output wire [7:0]  target_count_dbg,
//     output wire [7:0]  meas_count_dbg,
//     output wire [7:0]  dco_code_dbg,
//     output wire        lock,
//     output wire        sat_hi,
//     output wire        sat_lo,
//     output wire        meas_valid_dbg
// );

//     wire [CMD_W-1:0] pwm_cmd;
//     wire [CMD_W-1:0] direct_cmd;
//     wire [CMD_W-1:0] iq_cmd;
//     wire [CMD_W-1:0] cmd_value;

//     wire [TARGET_W-1:0] target_count;
//     wire [TARGET_W-1:0] meas_count;
//     wire                meas_valid;
//     wire [DCO_CODE_W-1:0] dco_code;

//     assign cmd_value_dbg     = cmd_value;
//     assign target_count_dbg  = target_count;
//     assign meas_count_dbg    = meas_count;
//     assign dco_code_dbg      = dco_code;
//     assign meas_valid_dbg    = meas_valid;

//     pwm_decoder #(
//         .OUT_W(CMD_W),
//         .WINDOW_REF_CYC(WINDOW_REF_CYC)
//     ) u_pwm_decoder (
//         .clk_ref   (clk_ref),
//         .rst_n     (rst_n),
//         .enable    (enable),
//         .pwm_in    (pwm_in),
//         .pwm_value (pwm_cmd)
//     );

//     direct_decoder #(
//         .W(CMD_W)
//     ) u_direct_decoder (
//         .direct_word (direct_word),
//         .cmd_value   (direct_cmd)
//     );

//     iq_decoder #(
//         .OUT_W(CMD_W)
//     ) u_iq_decoder (
//         .i_in      (i_in),
//         .q_in      (q_in),
//         .cmd_value (iq_cmd)
//     );

//     mode_mux #(
//         .W(CMD_W)
//     ) u_mode_mux (
//         .mode       (mode),
//         .pwm_cmd    (pwm_cmd),
//         .direct_cmd (direct_cmd),
//         .iq_cmd     (iq_cmd),
//         .manual_cmd (8'd0),
//         .cmd_value  (cmd_value)
//     );

//     command_generator #(
//         .CMD_W   (CMD_W),
//         .TARGET_W(TARGET_W)
//     ) u_command_generator (
//         .cmd_value    (cmd_value),
//         .base_count   (base_count),
//         .scale_shift  (scale_shift[2:0]),
//         .target_count (target_count)
//     );

//     freq_counter_gray #(
//         .COUNTER_W      (DCO_COUNTER_W),
//         .WINDOW_REF_CYC (WINDOW_REF_CYC),
//         .MEAS_W         (TARGET_W)
//     ) u_freq_counter_gray (
//         .clk_ref    (clk_ref),
//         .rst_n      (rst_n),
//         .enable     (enable),
//         .clk_async  (clk_hf),
//         .meas_count (meas_count),
//         .meas_valid (meas_valid)
//     );

//     fll_controller #(
//         .MEAS_W     (TARGET_W),
//         .DCO_CODE_W (DCO_CODE_W)
//     ) u_fll_controller (
//         .clk_ref         (clk_ref),
//         .rst_n           (rst_n),
//         .enable          (enable),
//         .freeze_fll      (freeze_fll),
//         .manual_mode     (mode == 2'b11),
//         .manual_dco_code (manual_dco_code),
//         .target_count    (target_count),
//         .meas_count      (meas_count),
//         .meas_valid      (meas_valid),
//         .deadband        (deadband),
//         .lock_tol        (lock_tol),
//         .dco_code        (dco_code),
//         .lock            (lock),
//         .sat_hi          (sat_hi),
//         .sat_lo          (sat_lo)
//     );

//     dco_blackbox_stub #(
//         .CODE_W       (DCO_CODE_W),
//         .DIVIDER_BITS (DIVIDER_BITS)
//     ) u_dco_blackbox (
//         .enable   (enable),
//         .dco_code (dco_code),
//         .clk_hf   (clk_hf),
//         .clk_div  (clk_div)
//     );

// endmodule

// module mode_mux #(
//     parameter integer W = 8
// ) (
//     input  wire [1:0]   mode,
//     input  wire [W-1:0] pwm_cmd,
//     input  wire [W-1:0] direct_cmd,
//     input  wire [W-1:0] iq_cmd,
//     input  wire [W-1:0] manual_cmd,
//     output reg  [W-1:0] cmd_value
// );
//     always @* begin
//         case (mode)
//             2'b00: cmd_value = pwm_cmd;
//             2'b01: cmd_value = direct_cmd;
//             2'b10: cmd_value = iq_cmd;
//             2'b11: cmd_value = manual_cmd;
//             default: cmd_value = {W{1'b0}};
//         endcase
//     end
// endmodule

// module direct_decoder #(
//     parameter integer W = 8
// ) (
//     input  wire [W-1:0] direct_word,
//     output wire [W-1:0] cmd_value
// );
//     assign cmd_value = direct_word;
// endmodule

// module pwm_decoder #(
//     parameter integer OUT_W          = 8,
//     parameter integer WINDOW_REF_CYC = 25
// ) (
//     input  wire            clk_ref,
//     input  wire            rst_n,
//     input  wire            enable,
//     input  wire            pwm_in,
//     output reg [OUT_W-1:0] pwm_value
// );
//     localparam integer CNT_W = 8;

//     reg [CNT_W-1:0] ref_cnt;
//     reg [CNT_W-1:0] high_cnt;

//     wire window_last = (ref_cnt == WINDOW_REF_CYC-1);

//     always @(posedge clk_ref or negedge rst_n) begin
//         if (!rst_n) begin
//             ref_cnt   <= 0;
//             high_cnt  <= 0;
//             pwm_value <= 0;
//         end else if (!enable) begin
//             ref_cnt   <= 0;
//             high_cnt  <= 0;
//             pwm_value <= 0;
//         end else begin
//             if (window_last) begin
//                 pwm_value <= (high_cnt * 8'd255) / WINDOW_REF_CYC;
//                 ref_cnt   <= 0;
//                 high_cnt  <= pwm_in ? 8'd1 : 8'd0;
//             end else begin
//                 ref_cnt <= ref_cnt + 8'd1;
//                 if (pwm_in)
//                     high_cnt <= high_cnt + 8'd1;
//             end
//         end
//     end
// endmodule

// module iq_decoder #(
//     parameter integer OUT_W = 8
// ) (
//     input  wire [3:0] i_in,
//     input  wire [3:0] q_in,
//     output wire [OUT_W-1:0] cmd_value
// );
//     wire signed [3:0] i_s = i_in;
//     wire signed [3:0] q_s = q_in;

//     wire [3:0] abs_i = i_s[3] ? (~i_s + 4'd1) : i_s;
//     wire [3:0] abs_q = q_s[3] ? (~q_s + 4'd1) : q_s;

//     wire [3:0] max_v = (abs_i >= abs_q) ? abs_i : abs_q;
//     wire [3:0] min_v = (abs_i >= abs_q) ? abs_q : abs_i;
//     wire [4:0] mag   = {1'b0, max_v} + ({1'b0, min_v} >> 1);
//     wire [8:0] scaled = mag * 9'd23;

//     assign cmd_value = scaled[OUT_W-1:0];
// endmodule

// module command_generator #(
//     parameter integer CMD_W    = 8,
//     parameter integer TARGET_W = 8
// ) (
//     input  wire [CMD_W-1:0]    cmd_value,
//     input  wire [TARGET_W-1:0] base_count,
//     input  wire [2:0]          scale_shift,
//     output reg  [TARGET_W-1:0] target_count
// );
//     reg signed [8:0] centered;
//     reg signed [8:0] delta;
//     reg signed [8:0] sum_ext;

//     always @* begin
//         centered = $signed({1'b0, cmd_value}) - 9'sd128;

//         case (scale_shift)
//             3'd0: delta = centered;
//             3'd1: delta = centered >>> 1;
//             3'd2: delta = centered >>> 2;
//             3'd3: delta = centered >>> 3;
//             3'd4: delta = centered >>> 4;
//             default: delta = centered >>> 2;
//         endcase

//         sum_ext = $signed({1'b0, base_count}) + delta;

//         if (sum_ext < 0)
//             target_count = 0;
//         else if (sum_ext > 9'sd255)
//             target_count = 8'hFF;
//         else
//             target_count = sum_ext[7:0];
//     end
// endmodule

// module freq_counter_gray #(
//     parameter integer COUNTER_W      = 16,
//     parameter integer WINDOW_REF_CYC = 25,
//     parameter integer MEAS_W         = 8
// ) (
//     input  wire              clk_ref,
//     input  wire              rst_n,
//     input  wire              enable,
//     input  wire              clk_async,
//     output reg  [MEAS_W-1:0] meas_count,
//     output reg               meas_valid
// );
//     reg  [COUNTER_W-1:0] async_bin;
//     wire [COUNTER_W-1:0] async_gray = (async_bin >> 1) ^ async_bin;

//     reg [COUNTER_W-1:0] gray_sync_1;
//     reg [COUNTER_W-1:0] gray_sync_2;
//     reg [COUNTER_W-1:0] bin_sample;
//     reg [COUNTER_W-1:0] bin_prev;
//     reg [7:0]           win_cnt;

//     wire window_last = (win_cnt == WINDOW_REF_CYC-1);

//     always @(posedge clk_async or negedge rst_n) begin
//         if (!rst_n)
//             async_bin <= 0;
//         else if (!enable)
//             async_bin <= 0;
//         else
//             async_bin <= async_bin + 1'b1;
//     end

//     always @(posedge clk_ref or negedge rst_n) begin
//         if (!rst_n) begin
//             gray_sync_1 <= 0;
//             gray_sync_2 <= 0;
//         end else begin
//             gray_sync_1 <= async_gray;
//             gray_sync_2 <= gray_sync_1;
//         end
//     end

//     always @(posedge clk_ref or negedge rst_n) begin
//         if (!rst_n) begin
//             bin_sample  <= 0;
//             bin_prev    <= 0;
//             win_cnt     <= 0;
//             meas_count  <= 0;
//             meas_valid  <= 1'b0;
//         end else if (!enable) begin
//             bin_sample  <= 0;
//             bin_prev    <= 0;
//             win_cnt     <= 0;
//             meas_count  <= 0;
//             meas_valid  <= 1'b0;
//         end else begin
//             bin_sample <= gray2bin(gray_sync_2);
//             meas_valid <= 1'b0;

//             if (window_last) begin
//                 win_cnt <= 0;
//                 if ((bin_sample - bin_prev) > 16'd255)
//                     meas_count <= 8'hFF;
//                 else
//                     meas_count <= (bin_sample - bin_prev)[7:0];
//                 bin_prev   <= bin_sample;
//                 meas_valid <= 1'b1;
//             end else begin
//                 win_cnt <= win_cnt + 1'b1;
//             end
//         end
//     end

//     function [COUNTER_W-1:0] gray2bin;
//         input [COUNTER_W-1:0] g;
//         integer k;
//         begin
//             gray2bin[COUNTER_W-1] = g[COUNTER_W-1];
//             for (k = COUNTER_W-2; k >= 0; k = k - 1)
//                 gray2bin[k] = gray2bin[k+1] ^ g[k];
//         end
//     endfunction
// endmodule

// module fll_controller #(
//     parameter integer MEAS_W     = 8,
//     parameter integer DCO_CODE_W = 8
// ) (
//     input  wire                  clk_ref,
//     input  wire                  rst_n,
//     input  wire                  enable,
//     input  wire                  freeze_fll,
//     input  wire                  manual_mode,
//     input  wire [DCO_CODE_W-1:0] manual_dco_code,
//     input  wire [MEAS_W-1:0]     target_count,
//     input  wire [MEAS_W-1:0]     meas_count,
//     input  wire                  meas_valid,
//     input  wire [MEAS_W-1:0]     deadband,
//     input  wire [MEAS_W-1:0]     lock_tol,
//     output reg  [DCO_CODE_W-1:0] dco_code,
//     output reg                   lock,
//     output reg                   sat_hi,
//     output reg                   sat_lo
// );
//     reg signed [8:0] error_s;
//     reg [DCO_CODE_W-1:0] step;
//     reg [8:0] abs_error;

//     always @(posedge clk_ref or negedge rst_n) begin
//         if (!rst_n) begin
//             dco_code <= 8'h80;
//             lock     <= 1'b0;
//             sat_hi   <= 1'b0;
//             sat_lo   <= 1'b0;
//         end else if (!enable) begin
//             dco_code <= 8'h80;
//             lock     <= 1'b0;
//             sat_hi   <= 1'b0;
//             sat_lo   <= 1'b0;
//         end else if (manual_mode) begin
//             dco_code <= manual_dco_code;
//             lock     <= 1'b0;
//             sat_hi   <= 1'b0;
//             sat_lo   <= 1'b0;
//         end else if (meas_valid) begin
//             error_s = $signed({1'b0, target_count}) - $signed({1'b0, meas_count});
//             abs_error = error_s[8] ? -error_s : error_s;

//             lock   <= (abs_error <= {1'b0, lock_tol});
//             sat_hi <= 1'b0;
//             sat_lo <= 1'b0;

//             if (!freeze_fll) begin
//                 if (abs_error > ({1'b0, deadband} + 9'd8))
//                     step = 8'd4;
//                 else if (abs_error > ({1'b0, deadband} + 9'd2))
//                     step = 8'd2;
//                 else
//                     step = 8'd1;

//                 if (error_s > $signed({1'b0, deadband})) begin
//                     if (dco_code >= (8'hFF - step)) begin
//                         dco_code <= 8'hFF;
//                         sat_hi   <= 1'b1;
//                     end else begin
//                         dco_code <= dco_code + step;
//                     end
//                 end else if (error_s < -$signed({1'b0, deadband})) begin
//                     if (dco_code <= step) begin
//                         dco_code <= 8'h00;
//                         sat_lo   <= 1'b1;
//                     end else begin
//                         dco_code <= dco_code - step;
//                     end
//                 end
//             end
//         end
//     end
// endmodule

// // Stub sintetizzabile per il primo test.
// // DCO "spento": tutte le uscite a zero.
// module dco_blackbox_stub #(
//     parameter integer CODE_W = 8,
//     parameter integer DIVIDER_BITS = 4
// ) (
//     input  wire              enable,
//     input  wire [CODE_W-1:0] dco_code,
//     output wire              clk_hf,
//     output wire              clk_div
// );
//     assign clk_hf  = 1'b0;
//     assign clk_div = 1'b0;

//     wire _unused = &{enable, dco_code, DIVIDER_BITS[0], 1'b0};
// endmodule

`default_nettype wire