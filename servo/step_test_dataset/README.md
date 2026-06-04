# Servo Step-Response Test Dataset

Self-contained test dataset for servo dynamics identification. The script performs static calibration, generates a three-panel overview figure, and exports the full time series.

## Quick Start

```matlab
cd('/path/to/step_test_dataset')
run('extract_dataset.m')
```

## Input

| File | Description |
|---|---|
| `step.csv` | Raw flight log (250 Hz) with step position commands and measured response |

## What It Does

1. Loads `step.csv` and trims to the valid interval [30, 2330] s.
2. Detects step-command jumps and builds a **static calibration table** (command → measured steady-state angle).
3. Maps the full command sequence to a **reference angle** via linear interpolation.
4. Displays one figure with three panels:
   - (a) Reference (calibrated command) vs. measured angle
   - (b) Angular velocity
   - (c) Angular acceleration
5. Exports all time series to `dataset/`.

## Output Files

| File | Description |
|---|---|
| `dataset/dataset.mat` | MATLAB `.mat` with variables `t`, `cmd`, `ref`, `angle`, `vel`, `acc` |
| `dataset/dataset.csv` | CSV: `time_s, cmd_rad, ref_rad, angle_rad, velocity_rad_s, acceleration_rad_s2` |
| `dataset/calibration.csv` | Static calibration table (command → steady-state angle) |

## Variables

| Variable | Unit | Description |
|---|---|---|
| `t` | s | Time (250 Hz) |
| `cmd` | rad | Raw position command |
| `ref` | rad | Reference angle (command after calibration mapping) |
| `angle` | rad | Measured servo angle (response) |
| `vel` | rad/s | Angular velocity |
| `acc` | rad/s² | Angular acceleration |

## Requirements

- MATLAB R2019b or later
- No toolboxes required

## Data Source

Raw data extracted from flight-log step-response experiments. The servo receives a sequence of step position commands; the measured angular response, velocity, and acceleration are recorded at 250 Hz.
