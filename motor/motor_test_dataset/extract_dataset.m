%% =========================================================================
% extract_dataset.m
% Motor step-response test dataset (fb1–fb16): calibration, visualization,
% and export.
%
% Input  — fb1.xlsx … fb16.xlsx  (raw motor test data, 16 files)
%          col 1: TIME (ms)
%          col 2: PWM (us)
%          col 7: F (kg)   — thrust
%          col 8: T (N·m)  — servo reaction torque
% Output — dataset/ folder:
%            dataset.mat   (MAT format)
%            dataset.csv   (CSV format)
%            calibration.csv
% =========================================================================
clear; clc; close all;

%% ------------------------------------------------------------------------
% 1. Settings
% ------------------------------------------------------------------------
g = 9.81;

% Steady-state window per file group (seconds after each step)
%   fb1–fb4  → slow dynamics  [1.0, 1.8]
%   fb5–fb16 → fast dynamics  [0.6, 0.95]
win_slow = [1.0, 1.8];
win_fast = [0.6, 0.95];

%% ------------------------------------------------------------------------
% 2. Batch process all files
% ------------------------------------------------------------------------
% Storage for concatenated time series
T_all  = {};   % time (s)
P_all  = {};   % PWM
F_all  = {};   % measured thrust (N)
TS_all = {};   % simulated torque coefficient (N·m)
TR_all = {};   % servo reaction torque (N·m)

% Storage for calibration (across all files)
cal_pwm   = [];
cal_force = [];

for k = 1:16
    fname = sprintf('fb%d.xlsx', k);
    if ~exist(fname, 'file')
        warning('File %s not found, skipping.', fname);
        continue;
    end

    % Choose steady-state window
    if k <= 4
        win = win_slow;
    else
        win = win_fast;
    end

    fprintf('[%2d/16] %-12s  window = [%.1f, %.1f] s  ...', k, fname, win);

    % Read file
    data = readmatrix(fname);
    first_row = find(data(:,1) > 0, 1, 'first');
    data = data(first_row:end, :);

    t_ms  = data(:, 1);
    pwm   = round(data(:, 2));
    F_kg  = data(:, 7);
    T_srv = data(:, 8);

    tk    = t_ms / 1000;           % time (s)
    Fk    = F_kg * g;              % thrust (N)
    T_sim = F_kg * g * 0.01;       % simulated torque coefficient (N·m)

    % Shift time to concatenate after previous file
    if ~isempty(T_all)
        t_offset = T_all{end}(end) + mean(diff(tk));
        tk = tk + t_offset;
    end

    dt = mean(diff(tk));

    % Detect PWM step changes
    change_idx = find(diff(pwm) ~= 0);
    n_steps = length(change_idx);
    step_start_idx = change_idx + 1;
    step_end_idx   = [step_start_idx(2:end) - 1; length(pwm)];
    step_PWM_after = pwm(step_start_idx);

    % Extract steady-state thrust per step
    n_cal = 0;
    for i = 1:n_steps
        idx0 = step_start_idx(i);
        idx1 = step_end_idx(i);
        ss0 = idx0 + round(win(1) / dt);
        ss1 = idx0 + round(win(2) / dt);
        ss1 = min(ss1, idx1);
        if ss0 >= ss1, continue; end
        F_ss = mean(Fk(ss0:ss1), 'omitnan');
        cal_pwm   = [cal_pwm;   step_PWM_after(i)];
        cal_force = [cal_force; F_ss];
        n_cal = n_cal + 1;
    end

    % Store
    T_all{end+1}  = tk;
    P_all{end+1}  = pwm;
    F_all{end+1}  = Fk;
    TS_all{end+1} = T_sim;
    TR_all{end+1} = T_srv;

    fprintf(' %d steps, %d calibrated, %d samples\n', n_steps, n_cal, length(tk));
end

%% ------------------------------------------------------------------------
% 3. Concatenate all segments
% ------------------------------------------------------------------------
t     = cell2mat(T_all');
pwm   = cell2mat(P_all');
F     = cell2mat(F_all');
T_sim = cell2mat(TS_all');
T_srv = cell2mat(TR_all');

fprintf('\nConcatenated: %d total samples\n', length(t));

%% ------------------------------------------------------------------------
% 4. Build global calibration table (PWM → steady-state thrust)
% ------------------------------------------------------------------------
[G, pwm_bin] = findgroups(cal_pwm);
F_mean = splitapply(@mean, cal_force, G);
F_std  = splitapply(@std,  cal_force, G);
F_n    = splitapply(@numel, cal_force, G);

calib = table(pwm_bin, F_mean, F_std, F_n, ...
    'VariableNames', {'PWM', 'Thrust_N', 'Std_N', 'N'});

fprintf('\nCalibration table (PWM → thrust, all files):\n');
disp(calib);

%% ------------------------------------------------------------------------
% 5. Map full PWM sequence to reference (expected) thrust
% ------------------------------------------------------------------------
F_ref = interp1(calib.PWM, calib.Thrust_N, pwm, 'linear', 'extrap');

%% ------------------------------------------------------------------------
% 6. One figure — 3 panels
%    (a) Reference thrust vs. measured thrust
%    (b) Simulated torque coefficient vs. servo reaction torque
%    (c) Command PWM
% ------------------------------------------------------------------------
figure('Name', 'Motor Step-Response Test Dataset (fb1–fb16)', ...
       'Position', [100, 100, 1400, 900], 'Color', 'w');

subplot(3,1,1);
plot(t, F_ref, 'r-', 'LineWidth', 1.2); hold on;
plot(t, F,     'b-', 'LineWidth', 0.8);
xlabel('Time (s)'); ylabel('Thrust (N)');
title('(a) Reference Thrust (calibrated) vs. Measured Thrust');
legend('Reference (F_{ref})', 'Measured (F)', 'Location', 'best');
grid on;

subplot(3,1,2);
plot(t, T_sim, 'r-', 'LineWidth', 1.0); hold on;
plot(t, T_srv, 'b-', 'LineWidth', 0.8);
xlabel('Time (s)'); ylabel('Torque (N·m)');
title('(b) Simulated Torque Coeff. (F_{kg}·g·0.01) vs. Servo Reaction Torque');
legend('T_{sim}', 'T_{srv}', 'Location', 'best');
grid on;

subplot(3,1,3);
plot(t, pwm, 'k-', 'LineWidth', 0.8);
xlabel('Time (s)'); ylabel('PWM');
title('(c) Command PWM');
grid on;

%% ------------------------------------------------------------------------
% 7. Export dataset to ./dataset/
% ------------------------------------------------------------------------
out = 'dataset';
if ~exist(out, 'dir'), mkdir(out); end

save(fullfile(out, 'dataset.mat'), ...
     't', 'pwm', 'F_ref', 'F', 'T_sim', 'T_srv');

T = table(t, pwm, F_ref, F, T_sim, T_srv, ...
    'VariableNames', {'time_s', 'PWM', 'F_ref_N', 'F_measured_N', ...
                       'T_sim_Nm', 'T_servo_Nm'});
writetable(T, fullfile(out, 'dataset.csv'));

writetable(calib, fullfile(out, 'calibration.csv'));

%% ------------------------------------------------------------------------
% 8. Summary
% ------------------------------------------------------------------------
fprintf('\n========== Dataset summary ==========\n');
fprintf('Files:          fb1–fb16\n');
fprintf('Samples:        %d\n', length(t));
fprintf('Time span:      [%.0f, %.0f] s\n', t(1), t(end));
fprintf('Sample period:  %.4f s\n', mean(diff(T_all{1})));
fprintf('PWM values:     %s\n', mat2str(unique(pwm)'));
fprintf('Calibration pts: %d\n', length(cal_pwm));
fprintf('Output folder:  %s/\n', fullfile(pwd, out));
fprintf('=====================================\n');
