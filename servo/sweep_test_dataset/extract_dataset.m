%% =========================================================================
% extract_dataset.m
% Servo sweep-frequency test dataset: calibration, visualization, and export.
%
% Input  — sweep_data.csv  (chirp sweep, 250 Hz)
%          col 1:  time (s)
%          col 9:  sweep on/off switch
%          col 11: measured angle (rad)
%          col 13: normalized command (chirp: sin(0.1·t^2), range [-1, 1])
% Output — dataset/ folder:
%            dataset.mat
%            dataset.csv
% =========================================================================
clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Load raw data
% ------------------------------------------------------------------------
fname = 'sweep_data.csv';
fprintf('Loading %s ...\n', fname);
data = readmatrix(fname);

t_raw     = data(:, 1);       % time (s)
sw        = data(:, 9);       % sweep switch (0->1 at start, 1->0 at end)
angle_raw = -data(:, 11);      % measured angle (rad)
cmd_norm  = data(:, 13);      % normalized chirp command (range [-1, 1])

fprintf('  Samples: %d\n', length(t_raw));
fprintf('  Time span: [%.2f, %.2f] s\n', t_raw(1), t_raw(end));

%% ------------------------------------------------------------------------
% 2. Detect sweep segment
%    Build sweep time from t_raw (col 10 may glitch at transition).
% ------------------------------------------------------------------------
rise_idx = find(diff(sw) > 0.5, 1, 'first') + 1;
if isempty(rise_idx)
    rise_idx = find(sw >= 0.5, 1, 'first');
end

% Sweep time: strictly monotonic, elapsed since sweep onset
t_swp = t_raw - t_raw(rise_idx);

% Restrict to rows where switch is still on (excludes glitch rows)
sweep_mask = (sw == 1);
sweep_mask(1:rise_idx-1) = false;
sweep_idx = find(sweep_mask);

fprintf('  Sweep segment: rows %d-%d  (%.2f-%.2f s,  duration %.2f s)\n', ...
    sweep_idx(1), sweep_idx(end), t_raw(sweep_idx(1)), t_raw(sweep_idx(end)), ...
    t_swp(sweep_idx(end)));

%% ------------------------------------------------------------------------
% 3. Zero-center the measured angle at sweep start
%    Record theta0 at sweep onset, subtract to get symmetric angle about zero.
% ------------------------------------------------------------------------
theta0 = angle_raw(rise_idx);
angle = angle_raw - theta0;

fprintf('  Initial angle theta0 = %.6f rad  (at t = %.4f s)\n', theta0, t_raw(rise_idx));

%% ------------------------------------------------------------------------
% 4. Compute expected angle from normalized command
%    Find max|angle| during sweep, scale normalized cmd [-1,1] to radians.
% ------------------------------------------------------------------------
angle_sweep    = angle(sweep_idx);
cmd_sweep_norm = cmd_norm(sweep_idx);

amp_lo  = min(angle_sweep);
amp_hi  = max(angle_sweep);
amplitude = max(abs(amp_lo), abs(amp_hi));

expected_angle = cmd_norm * amplitude;   % normalized -> rad

fprintf('  Measured angle range during sweep: [%.4f, %.4f] rad\n', amp_lo, amp_hi);
fprintf('  Amplitude scaling factor:          %.4f rad\n', amplitude);

%% ------------------------------------------------------------------------
% 5. Angular velocity and acceleration (numerical derivative)
% ------------------------------------------------------------------------
dt = mean(diff(t_raw));
vel = gradient(angle) ./ gradient(t_raw);
acc = gradient(vel)   ./ gradient(t_raw);

%% ------------------------------------------------------------------------
% 6. One figure - 3 panels
%    (a) Expected angle vs. measured angle (sweep segment)
%    (b) Angular velocity (sweep segment)
%    (c) Instantaneous frequency  f(t) = t_sweep / (10*pi)  [Hz]
% ------------------------------------------------------------------------
f_inst = t_swp / (10 * pi);

figure('Name', 'Servo Sweep-Frequency Test Dataset', ...
       'Position', [100, 100, 1400, 900], 'Color', 'w');

subplot(3,1,1);
plot(t_swp(sweep_idx), expected_angle(sweep_idx), 'r-', 'LineWidth', 1.2); hold on;
plot(t_swp(sweep_idx), angle_sweep,               'b-', 'LineWidth', 1.0);
xlabel('Sweep time (s)'); ylabel('Angle (rad)');
title('(a) Expected Angle (cmd_{norm} x amplitude) vs. Measured Angle');
legend('Expected angle', 'Measured angle', 'Location', 'best');
grid on;

subplot(3,1,2);
plot(t_swp(sweep_idx), vel(sweep_idx), 'Color', [0.15 0.55 0.15], 'LineWidth', 1.0);
xlabel('Sweep time (s)'); ylabel('Angular velocity (rad/s)');
title('(b) Angular Velocity');
grid on;

subplot(3,1,3);
plot(t_swp(sweep_idx), acc(sweep_idx), 'Color', [0.55 0.15 0.55], 'LineWidth', 1.0);
xlabel('Sweep time (s)'); ylabel('Angular acceleration (rad/s^2)');
title('(c) Angular Acceleration');
grid on;

%% ------------------------------------------------------------------------
% 7. Export dataset to ./dataset/
% ------------------------------------------------------------------------
out = 'dataset';
if ~exist(out, 'dir'), mkdir(out); end

% Sweep-segment variables
t_sweep_only   = t_swp(sweep_idx);
expected_sweep = expected_angle(sweep_idx);
angle_sweep_out = angle_sweep;
vel_sweep      = vel(sweep_idx);
acc_sweep      = acc(sweep_idx);
f_inst_sweep   = f_inst(sweep_idx);

% MAT format
save(fullfile(out, 'dataset.mat'), ...
     't_raw', 'cmd_norm', 'expected_angle', 'angle', 'vel', 'acc', 'sw', 't_swp');
save(fullfile(out, 'dataset.mat'), ...
     't_sweep_only', 'expected_sweep', 'angle_sweep_out', ...
     'vel_sweep', 'acc_sweep', 'f_inst_sweep', 'amplitude', 'theta0', '-append');

% CSV - sweep segment only
T = table(t_sweep_only, expected_sweep, angle_sweep_out, ...
          vel_sweep, acc_sweep, f_inst_sweep, ...
    'VariableNames', {'t_sweep_s', 'expected_angle_rad', 'measured_angle_rad', ...
                       'velocity_rad_s', 'acceleration_rad_s2', 'freq_Hz'});
writetable(T, fullfile(out, 'dataset.csv'));

%% ------------------------------------------------------------------------
% 8. Summary
% ------------------------------------------------------------------------
fprintf('\n========== Dataset summary ==========\n');
fprintf('Samples (full):       %d\n', length(t_raw));
fprintf('Samples (sweep only): %d\n', length(sweep_idx));
fprintf('Initial angle theta0: %.6f rad\n', theta0);
fprintf('Amplitude scaling:    %.4f rad\n', amplitude);
fprintf('Sweep time range:     [%.2f, %.2f] s\n', ...
    t_swp(sweep_idx(1)), t_swp(sweep_idx(end)));
fprintf('Frequency range:      [%.2f, %.2f] Hz\n', ...
    f_inst(sweep_idx(1)), f_inst(sweep_idx(end)));
fprintf('Sample period:        %.4f s (%.0f Hz)\n', dt, 1/dt);
fprintf('Output folder:        %s/\n', fullfile(pwd, out));
fprintf('=====================================\n');
