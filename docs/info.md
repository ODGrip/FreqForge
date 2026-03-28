# FreqForge – Digital FM Core

## How it works

This project implements a **multi-format digital frequency modulation core** based on a **digitally controlled oscillator (DCO)** and a fully digital **frequency-locked loop (FLL)**.

The system generates a frequency-modulated clock centered around ~100 MHz, with the frequency controlled by various input formats.

## Architecture

The design is composed of four main blocks:

### 1. Input interface (multi-format)

The system supports multiple input types:

- **PWM input** → duty cycle is converted to a numeric value  
- **Direct digital input** → frequency command provided directly  
- **I/Q input** → vector magnitude approximation used as control signal  

All input formats are normalized into a common internal representation (`cmd_value`).

---

### 2. Command generator

The normalized input is converted into a **target frequency**, expressed as:

> number of oscillator cycles within a fixed reference time window

This avoids working directly in Hz and simplifies control.

---

### 3. FLL (Frequency-Locked Loop)

A fully digital control loop:

- measures the oscillator frequency using a reference clock  
- compares it with the target  
- adjusts the DCO control word (`dco_code`)  

The loop ensures:

- convergence to the desired center frequency  
- robustness against PVT variations  

---

### 4. Digitally Controlled Oscillator (DCO)

The DCO is a **ring oscillator with digital tuning**:

- controlled by `dco_code`  
- monotonic frequency response  
- nominal center around ~100 MHz  

The DCO produces:

- `clk_hf` → high-frequency output (carrier)  
- `clk_div` → divided version for observation/debug  

---

## Modulation principle

The system performs frequency modulation by:

1. Using the FLL to lock the DCO to a **center frequency**  
2. Applying input-driven variations to the target  
3. Adjusting the DCO control word accordingly  

This results in:

- **FSK** (with discrete inputs)  
- **FM-like behavior** (with continuous inputs like PWM or I/Q)  

---

## How to test

### Basic setup

- Provide a clock on `clk` (reference clock, e.g. 10–50 MHz)  
- Assert `ena = 1`  
- Release reset (`rst_n = 1`)  

---

### Input control

#### Mode selection (`uio_in[1:0]`)

- `00` → PWM mode  
- `01` → Direct digital mode  
- `10` → I/Q mode  
- `11` → Manual DCO control  

#### Other control signals

- `uio_in[2]` → enable  
- `uio_in[3]` → freeze FLL (optional)  
- `uio_in[4]` → PWM input (PWM mode only)  

---

### Input formats

#### Direct mode

- `ui_in[7:0]` sets the frequency command directly  

#### PWM mode

- Apply a PWM signal on `uio_in[4]`  
- Duty cycle controls frequency  

#### I/Q mode

- `uio_in` carries I/Q values (low resolution)  
- Frequency is derived from vector magnitude  

---

### Observing the output

#### High-frequency output

- `clk_hf` → main modulated clock (~100 MHz)  

#### Debug output

- `clk_div` → divided version of the clock (easier to measure)  

#### Status signals (`uo_out`)

- `lock` → FLL has converged  
- `sat_hi / sat_lo` → control saturation  
- `meas_valid` → measurement updates  
- `dco_code` (partial) → current tuning value  

---

### Expected behavior

- On startup, the FLL searches for the correct `dco_code`  
- Once locked:  
  - frequency stabilizes around the target  
  - `lock` signal asserts  
- Changing the input:  
  - shifts the target frequency  
  - the DCO follows accordingly  

---

## External hardware

### Required

- A **reference clock source** (connected to `clk`)  

### Recommended for testing

- **Oscilloscope or frequency counter**  
  - to observe `clk_hf` or `clk_div`  

- Optional signal generator  
  - to provide PWM input for testing modulation  

### Not required

- No analog biasing  
- No external DACs  
- No RF front-end  

---

## 🧾 Summary

**A flexible digital frequency modulation engine that converts PWM, digital, or I/Q inputs into a ~100 MHz modulated clock using a DCO and a digital FLL.**
