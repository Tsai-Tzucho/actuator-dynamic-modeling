# Motor Step-Response Test Dataset

Self-contained test dataset for motor (propeller) dynamics identification across 16 throttle-sweep experiments. The script performs static calibration over all files, generates a three-panel overview figure, and exports the full concatenated time series.

## Quick Start

```matlab
cd('/path/to/motor_test_dataset')
run('extract_dataset.m')
```

## Input

| File | Description |
|---|---|
| `fb1.xlsx` – `fb16.xlsx` | Raw motor-propeller test-stand data (~23 MB total) |

## What It Does

1. Loads `fb1.xlsx` through `fb16.xlsx` (16 files, ~23 MB total).
2. Detects PWM step changes in each file, extracts steady-state thrust, and builds a **global static calibration table** (PWM → steady-state thrust).
3. Maps the full PWM sequence to a **reference thrust** via linear interpolation.
4. Displays one figure with three panels:
   - (a) Reference thrust (calibrated) vs. measured thrust
   - (b) Simulated torque coefficient (F_kg × g × 0.01) vs. servo reaction torque
   - (c) Command PWM
5. Exports the concatenated time series to `dataset/`.

## Output Files

| File | Description |
|---|---|
| `dataset/dataset.mat` | MATLAB `.mat` with variables `t`, `pwm`, `F_ref`, `F`, `T_sim`, `T_srv` |
| `dataset/dataset.csv` | CSV: `time_s, PWM, F_ref_N, F_measured_N, T_sim_Nm, T_servo_Nm` |
| `dataset/calibration.csv` | Global static calibration table (PWM → steady-state thrust) |

## Variables

| Variable | Unit | Description |
|---|---|---|
| `t` | s | Time (shifted to form one continuous timeline) |
| `pwm` | — | Command PWM (1000–2000) |
| `F_ref` | N | Reference thrust (PWM after global calibration mapping) |
| `F` | N | Measured thrust (F_kg × 9.81) |
| `T_sim` | N·m | Simulated reaction torque coefficient (F_kg × 9.81 × 0.01) |
| `T_srv` | N·m | Servo reaction torque (column 8) |

## Data Source

16 raw motor-propeller test stand experiments. Each file contains a sequence of PWM step commands with recorded thrust and torque.

| Files | Steady-state window | Description |
|---|---|---|
| fb1–fb4 | [1.0, 1.8] s | Slow-dynamics experiments |
| fb5–fb16 | [0.6, 0.95] s | Fast-dynamics experiments |

**Columns**: TIME (ms), PWM (μs), throttle (%), U (V), I (A), N (RPM), F (kg), T (N·m), …

## Requirements

- MATLAB R2019b or later
- No toolboxes required
