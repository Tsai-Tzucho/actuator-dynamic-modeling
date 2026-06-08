# Actuator Modeling Dataset

Comprehensive test dataset for actuator dynamics identification, covering both servo and motor (propeller) systems. Each sub-dataset is self-contained with raw data, a MATLAB extraction script, and pre-computed output files.

## Directory Structure

```
.
├── servo/
│   ├── sweep_test_dataset/     Chirp (swept-sine) excitation for servo frequency-domain identification
│   └── step_test_dataset/      Step-response experiments for servo time-domain identification
└── motor/
    └── motor_test_dataset/     16-file PWM step-response experiments for motor/propeller identification
```

## Sub-Datasets

| Dataset | Input | Samples |
|---|---|---|---|
| [Servo Sweep-Frequency](servo/sweep_test_dataset/) | `sweep_data.csv` | 
| [Servo Step-Response](servo/step_test_dataset/) | `step.csv` | ~575,000 |
| [Motor Step-Response](motor/motor_test_dataset/) | `fb1.xlsx` – `fb16.xlsx` |

## Quick Start

Each sub-dataset follows the same workflow:

```matlab
cd('servo/sweep_test_dataset')   % or step_test_dataset, motor_test_dataset
run('extract_dataset.m')
```

The script will:
1. Load the raw data
2. Perform static calibration
3. Display a three-panel diagnostic figure
4. Export `.mat` and `.csv` files to a `dataset/` folder

## Output Format

All datasets export to both:
- **`.mat`** — MATLAB binary format (all variables)
- **`.csv`** — Universal text format, readable by Python (`pandas`), R, MATLAB, etc.

## Requirements

- MATLAB R2019b or later
- No toolboxes required

## License

This dataset is provided for research and educational purposes. Please cite appropriately if used in publications.
