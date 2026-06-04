# Servo Sweep-Frequency Test Dataset

Self-contained test dataset for servo dynamics identification using chirp (swept-sine) excitation. The script zero-centers the measured angle at sweep onset, scales the normalized command to real radians using the measured amplitude, and exports time series for model identification.

## Quick Start

```matlab
cd('/path/to/sweep_test_dataset')
run('extract_dataset.m')
```

## Input

| File | Description |
|---|---|
| `sweep_data.csv` | Raw flight log (250 Hz) with chirp sweep command and measured angle |

## Calibration Method

1. Record the measured angle at sweep start: **θ₀**.
2. Subtract θ₀ from all angles → **zero-centered** (symmetric about zero).
3. Find max / min of the centered angle during the sweep segment.
4. Compute amplitude = max(\|min\|, \|max\|).
5. **Expected angle** = cmd_norm × amplitude  (converts normalized [−1, 1] to real radians).

## Figure Panels

- (a) Expected angle (cmd_norm × amplitude) vs. measured angle — sweep segment
- (b) Angular velocity — sweep segment
- (c) Angular acceleration — sweep segment

## Output Files

| File | Description |
|---|---|
| `dataset/dataset.mat` | MATLAB `.mat` — full + sweep-only variables |
| `dataset/dataset.csv` | Sweep segment: `t_sweep_s, expected_angle_rad, measured_angle_rad, velocity_rad_s, acceleration_rad_s2, freq_Hz` |

## Variables

| Variable | Unit | Description |
|---|---|---|
| `t_raw` | s | Time — full timeline (250 Hz) |
| `cmd_norm` | — | Normalized chirp command (col 13, range [−1, 1]) |
| `expected_angle` | rad | Expected angle = cmd_norm × amplitude |
| `angle` | rad | Measured angle (col 11), zero-centered (θ₀ subtracted) |
| `vel` | rad/s | Angular velocity (numerical derivative) |
| `acc` | rad/s² | Angular acceleration (numerical derivative) |
| `t_sweep_only` | s | Sweep time — sweep segment only |
| `amplitude` | rad | Scaling factor derived from measured angle range |
| `theta0` | rad | Initial angle at sweep start |

## Chirp Properties

- **Waveform**: sin(0.1 · t²)
- **Instantaneous frequency**: f(t) = t / (10π) Hz
- **Sweep duration**: ~265 s (0 → ~8.4 Hz)

## Requirements

- MATLAB R2019b or later
- No toolboxes required
