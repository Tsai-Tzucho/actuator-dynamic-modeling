%% =========================================================================
% extract_dataset.m
% Servo step-response test dataset: calibration, visualization, and export.
%
% Input  — step.csv (raw flight log, 250 Hz)
% Output — dataset/ folder containing:
%            dataset.mat   (MAT format: t, cmd, ref, angle, vel, acc)
%            dataset.csv   (CSV format, same variables)
%            calibration.csv (static calibration table)
% =========================================================================
clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Load raw data
%    Column mapping (step.csv):
%      col 1  → time t (s)
%      col 7  → angular velocity (rad/s)
%      col 8  → angular acceleration (rad/s^2)
%      col 11 → measured angle (rad)
%      col 13 → position command (rad)
% ------------------------------------------------------------------------
fprintf('Loading step.csv ...\n');
data = readmatrix('step.csv');

t_raw     = data(:, 1);
vel_raw   = data(:, 7);
acc_raw   = data(:, 8);
angle_raw = data(:, 11);
cmd_raw   = data(:, 13);

%% ------------------------------------------------------------------------
% 2. Trim to [30, 2330] s (exclude startup and tail transients)
% ------------------------------------------------------------------------
mask  = (t_raw >= 30) & (t_raw <= 2330);
t     = t_raw(mask);
vel   = vel_raw(mask);
acc   = acc_raw(mask);
angle = angle_raw(mask);
cmd   = cmd_raw(mask);

fprintf('Samples: %d raw  →  %d trimmed (%.1f–%.1f s)\n', ...
    length(t_raw), length(t), t(1), t(end));

%% ------------------------------------------------------------------------
% 3. Detect step-command jumps (threshold = 0.05 rad)
% ------------------------------------------------------------------------
dcmd     = diff(cmd);
jump_idx = find(abs(dcmd) > 0.05);

step_times = t(jump_idx + 1);
start_vals = cmd(jump_idx);
end_vals   = cmd(jump_idx + 1);
magnitude  = abs(end_vals - start_vals);
direction  = sign(end_vals - start_vals);

task_id = (1:length(step_times))';
tasks   = table(task_id, step_times, start_vals, end_vals, magnitude, direction, ...
    'VariableNames', {'ID','StepTime','StartCmd','EndCmd','Magnitude','Direction'});

fprintf('Step tasks detected: %d\n', height(tasks));

%% ------------------------------------------------------------------------
% 4. Extract steady-state angle per task (calibration input)
%    Window: [0.65, 0.95] s after each step
% ------------------------------------------------------------------------
steady_angle = NaN(height(tasks), 1);
valid        = false(height(tasks), 1);

for i = 1:height(tasks)
    t0   = tasks.StepTime(i);
    idx  = find(t >= t0 + 0.65 & t <= t0 + 0.95);
    if isempty(idx), continue; end
    steady_angle(i) = mean(angle(idx), 'omitnan');
    valid(i) = true;
end

%% ------------------------------------------------------------------------
% 5. Build static calibration table (command → measured steady-state angle)
% ------------------------------------------------------------------------
tasks_valid = tasks(valid, :);
tasks_valid.SteadyAngle = steady_angle(valid);

[G, cmd_bin] = findgroups(tasks_valid.EndCmd);
cal_mean = splitapply(@mean, tasks_valid.SteadyAngle, G);
cal_std  = splitapply(@std,  tasks_valid.SteadyAngle, G);
cal_n    = splitapply(@numel, tasks_valid.SteadyAngle, G);

calib = table(cmd_bin, cal_mean, cal_std, cal_n, ...
    'VariableNames', {'Command_rad', 'SteadyAngle_rad', 'Std_rad', 'N'});

fprintf('\nCalibration table (command → steady-state angle):\n');
disp(calib);

%% ------------------------------------------------------------------------
% 6. Map full command sequence to reference angle (linear interpolation)
% ------------------------------------------------------------------------
ref = interp1(calib.Command_rad, calib.SteadyAngle_rad, cmd, 'linear', 'extrap');

%% ------------------------------------------------------------------------
% 7. One figure: reference vs measured, angular velocity, acceleration
% ------------------------------------------------------------------------
figure('Name', 'Servo Step-Response Test Dataset', ...
       'Position', [100, 100, 1400, 900], 'Color', 'w');

subplot(3,1,1);
plot(t, ref,   'r-', 'LineWidth', 1.5); hold on;
plot(t, angle, 'b-', 'LineWidth', 1.0);
xlabel('Time (s)'); ylabel('Angle (rad)');
title('Command (reference) vs. Measured Response');
legend('Reference (calibrated command)', 'Measured angle', 'Location', 'best');
grid on;

subplot(3,1,2);
plot(t, vel, 'Color', [0.15 0.55 0.15], 'LineWidth', 1.0);
xlabel('Time (s)'); ylabel('Angular velocity (rad/s)');
title('Angular Velocity');
grid on;

subplot(3,1,3);
plot(t, acc, 'Color', [0.55 0.15 0.55], 'LineWidth', 1.0);
xlabel('Time (s)'); ylabel('Angular acceleration (rad/s^2)');
title('Angular Acceleration');
grid on;

%% ------------------------------------------------------------------------
% 8. Export dataset to ./dataset/
% ------------------------------------------------------------------------
out = 'dataset';
if ~exist(out, 'dir'), mkdir(out); end

% MAT format
save(fullfile(out, 'dataset.mat'), 't', 'cmd', 'ref', 'angle', 'vel', 'acc');

% CSV format (universal)
T = table(t, cmd, ref, angle, vel, acc, ...
    'VariableNames', {'time_s','cmd_rad','ref_rad','angle_rad','velocity_rad_s','acceleration_rad_s2'});
writetable(T, fullfile(out, 'dataset.csv'));

% Calibration table
writetable(calib, fullfile(out, 'calibration.csv'));

%% ------------------------------------------------------------------------
% 9. Summary
% ------------------------------------------------------------------------
fprintf('\n========== Dataset summary ==========\n');
fprintf('Samples:        %d\n', length(t));
fprintf('Time span:      [%.1f, %.1f] s\n', t(1), t(end));
fprintf('Sample period:  %.4f s  (%.0f Hz)\n', mean(diff(t)), 1/mean(diff(t)));
fprintf('Tracking error: mean = %.4f, std = %.4f, rms = %.4f rad\n', ...
    mean(angle - ref, 'omitnan'), std(angle - ref, 'omitnan'), rms(angle - ref, 'omitnan'));
fprintf('Output folder:  %s/\n', fullfile(pwd, out));
fprintf('=====================================\n');
