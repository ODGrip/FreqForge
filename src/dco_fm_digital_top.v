`default_nettype none

// -----------------------------------------------------------------------------
// dco_fm_digital_top.v
//
// Digital-only FM/FLL core around a DCO black box.
//
// Notes:
// - This file contains ONLY the digital logic.
// - The DCO itself is modeled as a synthesizable stub at the bottom of the file.
// - Replace dco_blackbox_stub with the real DCO instance in the final project.
// - All main logic runs in clk_ref domain except the asynchronous DCO edge counter.
// - The async counter is sampled into clk_ref through a Gray-code CDC.
// -----------------------------------------------------------------------------

module dco_fm_digital_top #(
    parameter integer CMD_W           = 8,
    parameter integer TARGET_W        = 8,
    parameter integer DCO_CODE_W      = 8,
    parameter integer DCO_COUNTER_W   = 16,
    parameter integer WINDOW_REF_CYC  = 25,   // 25 cycles @ 25 MHz = 1 us window
    parameter integer DIVIDER_BITS    = 4
) (
    input  wire                    clk_ref,
    input  wire                    rst_n,

    input  wire                    enable,
    input  wire                    freeze_fll,
    input  wire [1:0]              mode,          // 00: PWM, 01: direct, 10: IQ, 11: manual

    input  wire                    pwm_in,
    input  wire [7:0]              direct_word,
    input  wire [3:0]              i_in,
    input  wire [3:0]              q_in,
    input  wire [DCO_CODE_W-1:0]   manual_dco_code,

    input  wire [TARGET_W-1:0]     base_count,
    input  wire [7:0]              scale_shift,
    input  wire [TARGET_W-1:0]     deadband,
    input  wire [TARGET_W-1:0]     lock_tol,

    output wire                    clk_hf,
    output wire                    clk_div,

    output wire [CMD_W-1:0]        cmd_value_dbg,
    output wire [TARGET_W-1:0]     target_count_dbg,
    output wire [TARGET_W-1:0]     meas_count_dbg,
    output wire [DCO_CODE_W-1:0]   dco_code_dbg,
    output wire                    lock,
    output wire                    sat_hi,
    output wire                    sat_lo,
    output wire                    meas_valid_dbg
);

    wire [CMD_W-1:0] pwm_cmd;
    wire [CMD_W-1:0] direct_cmd;
    wire [CMD_W-1:0] iq_cmd;
    wire [CMD_W-1:0] cmd_value;

    wire [TARGET_W-1:0] target_count;
    wire [TARGET_W-1:0] meas_count;
    wire                meas_valid;
    wire [DCO_CODE_W-1:0] dco_code;

    assign cmd_value_dbg     = cmd_value;
    assign target_count_dbg  = target_count;
    assign meas_count_dbg    = meas_count;
    assign dco_code_dbg      = dco_code;
    assign meas_valid_dbg    = meas_valid;

    pwm_decoder #(
        .OUT_W(CMD_W),
        .WINDOW_REF_CYC(WINDOW_REF_CYC)
    ) u_pwm_decoder (
        .clk_ref   (clk_ref),
        .rst_n     (rst_n),
        .enable    (enable),
        .pwm_in    (pwm_in),
        .pwm_value (pwm_cmd)
    );

    direct_decoder #(
        .W(CMD_W)
    ) u_direct_decoder (
        .direct_word (direct_word),
        .cmd_value   (direct_cmd)
    );

    iq_decoder #(
        .OUT_W(CMD_W)
    ) u_iq_decoder (
        .i_in      (i_in),
        .q_in      (q_in),
        .cmd_value (iq_cmd)
    );

    mode_mux #(
        .W(CMD_W)
    ) u_mode_mux (
        .mode       (mode),
        .pwm_cmd    (pwm_cmd),
        .direct_cmd (direct_cmd),
        .iq_cmd     (iq_cmd),
        .manual_cmd ({CMD_W{1'b0}}),
        .cmd_value  (cmd_value)
    );

    command_generator #(
        .CMD_W    (CMD_W),
        .TARGET_W (TARGET_W)
    ) u_command_generator (
        .cmd_value    (cmd_value),
        .base_count   (base_count),
        .scale_shift  (scale_shift[2:0]),
        .target_count (target_count)
    );

    freq_counter_gray #(
        .COUNTER_W      (DCO_COUNTER_W),
        .WINDOW_REF_CYC (WINDOW_REF_CYC),
        .MEAS_W         (TARGET_W)
    ) u_freq_counter_gray (
        .clk_ref    (clk_ref),
        .rst_n      (rst_n),
        .enable     (enable),
        .clk_async  (clk_hf),
        .meas_count (meas_count),
        .meas_valid (meas_valid)
    );

    fll_controller #(
        .MEAS_W     (TARGET_W),
        .DCO_CODE_W (DCO_CODE_W)
    ) u_fll_controller (
        .clk_ref         (clk_ref),
        .rst_n           (rst_n),
        .enable          (enable),
        .freeze_fll      (freeze_fll),
        .manual_mode     (mode == 2'b11),
        .manual_dco_code (manual_dco_code),
        .target_count    (target_count),
        .meas_count      (meas_count),
        .meas_valid      (meas_valid),
        .deadband        (deadband),
        .lock_tol        (lock_tol),
        .dco_code        (dco_code),
        .lock            (lock),
        .sat_hi          (sat_hi),
        .sat_lo          (sat_lo)
    );

    dco_blackbox_stub #(
        .CODE_W       (DCO_CODE_W),
        .DIVIDER_BITS (DIVIDER_BITS)
    ) u_dco_blackbox (
        .enable   (enable),
        .dco_code (dco_code),
        .clk_hf   (clk_hf),
        .clk_div  (clk_div)
    );

endmodule

// -----------------------------------------------------------------------------
// mode_mux
// -----------------------------------------------------------------------------
module mode_mux #(
    parameter integer W = 8
) (
    input  wire [1:0]   mode,
    input  wire [W-1:0] pwm_cmd,
    input  wire [W-1:0] direct_cmd,
    input  wire [W-1:0] iq_cmd,
    input  wire [W-1:0] manual_cmd,
    output reg  [W-1:0] cmd_value
);
    always @* begin
        case (mode)
            2'b00: cmd_value = pwm_cmd;
            2'b01: cmd_value = direct_cmd;
            2'b10: cmd_value = iq_cmd;
            2'b11: cmd_value = manual_cmd;
            default: cmd_value = {W{1'b0}};
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// direct_decoder
// -----------------------------------------------------------------------------
module direct_decoder #(
    parameter integer W = 8
) (
    input  wire [W-1:0] direct_word,
    output wire [W-1:0] cmd_value
);
    assign cmd_value = direct_word;
endmodule

// -----------------------------------------------------------------------------
// pwm_decoder
//
// Measures how many clk_ref cycles pwm_in is high inside a fixed reference
// window. Exposes that high-count scaled to 0..255.
// -----------------------------------------------------------------------------
module pwm_decoder #(
    parameter integer OUT_W          = 8,
    parameter integer WINDOW_REF_CYC = 25
) (
    input  wire             clk_ref,
    input  wire             rst_n,
    input  wire             enable,
    input  wire             pwm_in,
    output reg [OUT_W-1:0]  pwm_value
);
    localparam integer CNT_W = clog2(WINDOW_REF_CYC + 1);

    reg [CNT_W-1:0] ref_cnt;
    reg [CNT_W-1:0] high_cnt;

    wire window_last;
    assign window_last = (ref_cnt == WINDOW_REF_CYC-1);

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            ref_cnt   <= {CNT_W{1'b0}};
            high_cnt  <= {CNT_W{1'b0}};
            pwm_value <= {OUT_W{1'b0}};
        end else if (!enable) begin
            ref_cnt   <= {CNT_W{1'b0}};
            high_cnt  <= {CNT_W{1'b0}};
            pwm_value <= {OUT_W{1'b0}};
        end else begin
            if (window_last) begin
                pwm_value <= (high_cnt * ((1 << OUT_W) - 1)) / WINDOW_REF_CYC;
                ref_cnt   <= {CNT_W{1'b0}};
                if (pwm_in)
                    high_cnt <= {{(CNT_W-1){1'b0}}, 1'b1};
                else
                    high_cnt <= {CNT_W{1'b0}};
            end else begin
                ref_cnt <= ref_cnt + {{(CNT_W-1){1'b0}}, 1'b1};
                if (pwm_in)
                    high_cnt <= high_cnt + {{(CNT_W-1){1'b0}}, 1'b1};
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// iq_decoder
//
// Treats I and Q as signed 4-bit two's-complement values.
// Uses an approximate vector magnitude:
//   mag = max(|I|,|Q|) + min(|I|,|Q|)/2
// Then maps to unsigned command 0..255 by multiplying by 23.
// -----------------------------------------------------------------------------
module iq_decoder #(
    parameter integer OUT_W = 8
) (
    input  wire [3:0] i_in,
    input  wire [3:0] q_in,
    output wire [OUT_W-1:0] cmd_value
);
    wire signed [3:0] i_s;
    wire signed [3:0] q_s;
    wire [3:0] abs_i;
    wire [3:0] abs_q;
    wire [3:0] max_v;
    wire [3:0] min_v;
    wire [4:0] mag;
    wire [8:0] scaled;

    assign i_s = i_in;
    assign q_s = q_in;

    assign abs_i = i_s[3] ? (~i_s + 4'd1) : i_s;
    assign abs_q = q_s[3] ? (~q_s + 4'd1) : q_s;

    assign max_v = (abs_i >= abs_q) ? abs_i : abs_q;
    assign min_v = (abs_i >= abs_q) ? abs_q : abs_i;
    assign mag   = {1'b0, max_v} + ({1'b0, min_v} >> 1);
    assign scaled = mag * 9'd23;

    assign cmd_value = scaled[OUT_W-1:0];
endmodule

// -----------------------------------------------------------------------------
// command_generator
//
// target_count = base_count + signed_delta
// cmd_value is interpreted as unsigned centered around 128.
// scale_shift selects power-of-two scaling of the centered command.
// -----------------------------------------------------------------------------
module command_generator #(
    parameter integer CMD_W    = 8,
    parameter integer TARGET_W = 8
) (
    input  wire [CMD_W-1:0]    cmd_value,
    input  wire [TARGET_W-1:0] base_count,
    input  wire [2:0]          scale_shift,
    output reg  [TARGET_W-1:0] target_count
);
    reg signed [CMD_W:0] centered;
    reg signed [CMD_W:0] delta;
    reg signed [TARGET_W:0] sum_ext;
    reg signed [CMD_W:0] mid_code;

    always @* begin
        mid_code = $signed(1 << (CMD_W-1));
        centered = $signed({1'b0, cmd_value}) - mid_code;

        case (scale_shift)
            3'd0: delta = centered;
            3'd1: delta = centered >>> 1;
            3'd2: delta = centered >>> 2;
            3'd3: delta = centered >>> 3;
            3'd4: delta = centered >>> 4;
            3'd5: delta = centered >>> 5;
            default: delta = centered >>> 2;
        endcase

        sum_ext = $signed({1'b0, base_count}) + $signed(delta[TARGET_W:0]);

        if (sum_ext < 0)
            target_count = {TARGET_W{1'b0}};
        else if (sum_ext > $signed({1'b0, {TARGET_W{1'b1}}}))
            target_count = {TARGET_W{1'b1}};
        else
            target_count = sum_ext[TARGET_W-1:0];
    end
endmodule

// -----------------------------------------------------------------------------
// freq_counter_gray
//
// Asynchronous domain: free-running counter on clk_async
// Reference domain: samples Gray-coded count, converts to binary, subtracts two
// snapshots taken WINDOW_REF_CYC cycles apart.
// -----------------------------------------------------------------------------
module freq_counter_gray #(
    parameter integer COUNTER_W      = 16,
    parameter integer WINDOW_REF_CYC = 25,
    parameter integer MEAS_W         = 8
) (
    input  wire              clk_ref,
    input  wire              rst_n,
    input  wire              enable,
    input  wire              clk_async,
    output reg  [MEAS_W-1:0] meas_count,
    output reg               meas_valid
);
    localparam integer REF_W = clog2(WINDOW_REF_CYC + 1);

    wire [COUNTER_W-1:0] async_bin;
    wire [COUNTER_W-1:0] async_gray;

    reg  [COUNTER_W-1:0] gray_sync_1;
    reg  [COUNTER_W-1:0] gray_sync_2;
    reg  [COUNTER_W-1:0] bin_sample;
    reg  [COUNTER_W-1:0] bin_prev;
    reg  [REF_W-1:0]     win_cnt;

    wire                  win_last;
    wire [COUNTER_W-1:0]  count_diff;
    wire [COUNTER_W-1:0]  meas_max_ext;

    assign win_last     = (win_cnt == WINDOW_REF_CYC-1);
    assign count_diff   = bin_sample - bin_prev;
    assign meas_max_ext = {{(COUNTER_W-MEAS_W){1'b0}}, {MEAS_W{1'b1}}};

    gray_counter_async #(
        .W(COUNTER_W)
    ) u_gray_counter_async (
        .clk_async  (clk_async),
        .rst_n      (rst_n),
        .enable     (enable),
        .bin_count  (async_bin),
        .gray_count (async_gray)
    );

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            gray_sync_1 <= {COUNTER_W{1'b0}};
            gray_sync_2 <= {COUNTER_W{1'b0}};
        end else begin
            gray_sync_1 <= async_gray;
            gray_sync_2 <= gray_sync_1;
        end
    end

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            bin_sample <= {COUNTER_W{1'b0}};
            bin_prev   <= {COUNTER_W{1'b0}};
            win_cnt    <= {REF_W{1'b0}};
            meas_count <= {MEAS_W{1'b0}};
            meas_valid <= 1'b0;
        end else if (!enable) begin
            bin_sample <= {COUNTER_W{1'b0}};
            bin_prev   <= {COUNTER_W{1'b0}};
            win_cnt    <= {REF_W{1'b0}};
            meas_count <= {MEAS_W{1'b0}};
            meas_valid <= 1'b0;
        end else begin
            bin_sample <= gray2bin(gray_sync_2);
            meas_valid <= 1'b0;

            if (win_last) begin
                win_cnt <= {REF_W{1'b0}};

                if (count_diff > meas_max_ext)
                    meas_count <= {MEAS_W{1'b1}};
                else
                    meas_count <= count_diff[MEAS_W-1:0];

                bin_prev   <= bin_sample;
                meas_valid <= 1'b1;
            end else begin
                win_cnt <= win_cnt + {{(REF_W-1){1'b0}}, 1'b1};
            end
        end
    end

    function [COUNTER_W-1:0] gray2bin;
        input [COUNTER_W-1:0] g;
        integer k;
        begin
            gray2bin[COUNTER_W-1] = g[COUNTER_W-1];
            for (k = COUNTER_W-2; k >= 0; k = k - 1)
                gray2bin[k] = gray2bin[k+1] ^ g[k];
        end
    endfunction
endmodule

// -----------------------------------------------------------------------------
// gray_counter_async
// -----------------------------------------------------------------------------
module gray_counter_async #(
    parameter integer W = 16
) (
    input  wire         clk_async,
    input  wire         rst_n,
    input  wire         enable,
    output reg  [W-1:0] bin_count,
    output wire [W-1:0] gray_count
);
    assign gray_count = (bin_count >> 1) ^ bin_count;

    always @(posedge clk_async or negedge rst_n) begin
        if (!rst_n)
            bin_count <= {W{1'b0}};
        else if (!enable)
            bin_count <= {W{1'b0}};
        else
            bin_count <= bin_count + {{(W-1){1'b0}}, 1'b1};
    end
endmodule

// -----------------------------------------------------------------------------
// fll_controller
//
// Manual mode bypasses the loop and drives dco_code directly.
// Otherwise, on each meas_valid pulse, it compares target_count to meas_count and
// steps the code up/down.
// -----------------------------------------------------------------------------
module fll_controller #(
    parameter integer MEAS_W     = 8,
    parameter integer DCO_CODE_W = 8
) (
    input  wire                  clk_ref,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire                  freeze_fll,
    input  wire                  manual_mode,
    input  wire [DCO_CODE_W-1:0] manual_dco_code,
    input  wire [MEAS_W-1:0]     target_count,
    input  wire [MEAS_W-1:0]     meas_count,
    input  wire                  meas_valid,
    input  wire [MEAS_W-1:0]     deadband,
    input  wire [MEAS_W-1:0]     lock_tol,
    output reg  [DCO_CODE_W-1:0] dco_code,
    output reg                   lock,
    output reg                   sat_hi,
    output reg                   sat_lo
);
    reg signed [MEAS_W:0] error_s;
    reg [DCO_CODE_W-1:0]  step;
    reg [MEAS_W:0]        abs_error;

    always @(posedge clk_ref or negedge rst_n) begin
        if (!rst_n) begin
            dco_code <= {1'b1, {(DCO_CODE_W-1){1'b0}}}; // mid-scale
            lock     <= 1'b0;
            sat_hi   <= 1'b0;
            sat_lo   <= 1'b0;
        end else if (!enable) begin
            dco_code <= {1'b1, {(DCO_CODE_W-1){1'b0}}};
            lock     <= 1'b0;
            sat_hi   <= 1'b0;
            sat_lo   <= 1'b0;
        end else if (manual_mode) begin
            dco_code <= manual_dco_code;
            lock     <= 1'b0;
            sat_hi   <= 1'b0;
            sat_lo   <= 1'b0;
        end else if (meas_valid) begin
            error_s   = $signed({1'b0, target_count}) - $signed({1'b0, meas_count});
            if (error_s[MEAS_W])
                abs_error = $unsigned(-error_s);
            else
                abs_error = $unsigned(error_s);

            lock   <= (abs_error <= {1'b0, lock_tol});
            sat_hi <= 1'b0;
            sat_lo <= 1'b0;

            if (!freeze_fll) begin
                if (abs_error > ({1'b0, deadband} + {{MEAS_W-4{1'b0}}, 4'd8}))
                    step = {{(DCO_CODE_W-3){1'b0}}, 3'd4};
                else if (abs_error > ({1'b0, deadband} + {{MEAS_W-2{1'b0}}, 2'd2}))
                    step = {{(DCO_CODE_W-2){1'b0}}, 2'd2};
                else
                    step = {{(DCO_CODE_W-1){1'b0}}, 1'b1};

                if (error_s > $signed({1'b0, deadband})) begin
                    if (dco_code >= ({DCO_CODE_W{1'b1}} - step)) begin
                        dco_code <= {DCO_CODE_W{1'b1}};
                        sat_hi   <= 1'b1;
                    end else begin
                        dco_code <= dco_code + step;
                    end
                end else if (error_s < -$signed({1'b0, deadband})) begin
                    if (dco_code <= step) begin
                        dco_code <= {DCO_CODE_W{1'b0}};
                        sat_lo   <= 1'b1;
                    end else begin
                        dco_code <= dco_code - step;
                    end
                end
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Utility function: ceil(log2(n))
// -----------------------------------------------------------------------------
function integer clog2;
    input integer value;
    integer tmp;
    begin
        tmp = value - 1;
        clog2 = 0;
        while (tmp > 0) begin
            tmp = tmp >> 1;
            clog2 = clog2 + 1;
        end
    end
endfunction

// -----------------------------------------------------------------------------
// DCO synthesizable stub
//
// Replace this with the real custom oscillator in the final project.
// This stub keeps lint/synthesis happy.
// -----------------------------------------------------------------------------
module dco_blackbox_stub #(
    parameter integer CODE_W = 8,
    parameter integer DIVIDER_BITS = 4
) (
    input  wire              enable,
    input  wire [CODE_W-1:0] dco_code,
    output wire              clk_hf,
    output wire              clk_div
);
    assign clk_hf  = 1'b0;
    assign clk_div = 1'b0;

    wire _unused_ok;
    assign _unused_ok = &{1'b0, enable, dco_code};
endmodule

`default_nettype wire
