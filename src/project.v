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

    // ------------------------------------------------------------------------
    // Final intended pin mapping
    //
    // ui_in[7:0]   = direct input data
    //
    // uio_in[1:0]  = mode
    //                00 = PWM
    //                01 = direct
    //                10 = I/Q
    //                11 = manual DCO code
    //
    // uio_in[2]    = enable
    // uio_in[3]    = freeze_fll
    // uio_in[4]    = pwm_in
    // uio_in[7:5]  = I input bits for now
    //
    // Outputs
    // uo_out[0]    = clk_div
    // uo_out[3:1]  = dco_code debug
    // uo_out[4]    = meas_valid
    // uo_out[5]    = sat_lo
    // uo_out[6]    = sat_hi
    // uo_out[7]    = lock
    // ------------------------------------------------------------------------

    wire [1:0] mode;
    wire       core_enable;
    wire       freeze_fll;
    wire       pwm_in;

    wire [7:0] direct_word;
    wire [3:0] i_in;
    wire [3:0] q_in;
    wire [7:0] manual_dco_code;

    wire [7:0] base_count;
    wire [7:0] scale_shift;
    wire [7:0] deadband;
    wire [7:0] lock_tol;

    wire       clk_hf;
    wire       clk_div;

    wire [7:0] cmd_value_dbg;
    wire [7:0] target_count_dbg;
    wire [7:0] meas_count_dbg;
    wire [7:0] dco_code_dbg;
    wire       lock;
    wire       sat_hi;
    wire       sat_lo;
    wire       meas_valid_dbg;

    assign mode        = uio_in[1:0];
    assign core_enable = uio_in[2] & ena;
    assign freeze_fll  = uio_in[3];
    assign pwm_in      = uio_in[4];

    assign direct_word = ui_in;

    // Temporary compact I mapping on available pins.
    assign i_in = {uio_in[7], uio_in[6], uio_in[5], 1'b0};

    // Q is tied low in this wrapper revision.
    assign q_in = 4'b0000;

    // Manual DCO code not externally exposed in this wrapper revision.
    assign manual_dco_code = 8'h80;

    // Fixed configuration for first integration.
    assign base_count  = 8'd100;
    assign scale_shift = 8'd2;
    assign deadband    = 8'd1;
    assign lock_tol    = 8'd1;

    dco_fm_digital_top u_core (
        .clk_ref          (clk),
        .rst_n            (rst_n),

        .enable           (core_enable),
        .freeze_fll       (freeze_fll),
        .mode             (mode),

        .pwm_in           (pwm_in),
        .direct_word      (direct_word),
        .i_in             (i_in),
        .q_in             (q_in),
        .manual_dco_code  (manual_dco_code),

        .base_count       (base_count),
        .scale_shift      (scale_shift),
        .deadband         (deadband),
        .lock_tol         (lock_tol),

        .clk_hf           (clk_hf),
        .clk_div          (clk_div),

        .cmd_value_dbg    (cmd_value_dbg),
        .target_count_dbg (target_count_dbg),
        .meas_count_dbg   (meas_count_dbg),
        .dco_code_dbg     (dco_code_dbg),
        .lock             (lock),
        .sat_hi           (sat_hi),
        .sat_lo           (sat_lo),
        .meas_valid_dbg   (meas_valid_dbg)
    );

    // Dedicated outputs
    assign uo_out[0] = clk_div;
    assign uo_out[1] = dco_code_dbg[0];
    assign uo_out[2] = dco_code_dbg[1];
    assign uo_out[3] = dco_code_dbg[2];
    assign uo_out[4] = meas_valid_dbg;
    assign uo_out[5] = sat_lo;
    assign uo_out[6] = sat_hi;
    assign uo_out[7] = lock;

    // All bidirectional pins are inputs in this revision
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // Prevent unused-signal warnings for debug-only internal signals
    wire _unused_ok;
    assign _unused_ok = &{1'b0, clk_hf, cmd_value_dbg, target_count_dbg, meas_count_dbg, dco_code_dbg[7:3]};

endmodule

`default_nettype wire