%% 1. Setup and Connection
clear; close all; clc;
arduinoPortName = "/dev/tty.usbmodem1201"; %make sure this is the right port, you can find available ports by: serialportlist("available") 

try
    % UPDATED: Baud rate changed to 9600 to match Arduino
    arduino_port = serialport(arduinoPortName, 9600, 'Timeout', 5);
    configureTerminator(arduino_port, "CR/LF"); 
    disp('Successfully connected to Arduino.');
catch ME
    error('Could not connect: %s', ME.message);
end

%% 2. Parameters
weights = [200, 400, 700, 900, 1200]; 
num_weights = length(weights);
num_sensors = 1; % Set to 1 as per your Arduino code

all_voltages = zeros(num_sensors, num_weights);

%% 3. Data Collection Loop
% for s = 1:num_sensors
%     fprintf('\n--- CALIBRATING SENSOR %d ---\n', s);
% 
%     for w = 1:num_weights
%         fprintf('Place %dg and press ENTER...', weights(w));
%         pause; 
% 
%         % disp('Stabilizing...');
%         % pause(2)
% 
%         disp('Recording 50 samples...');
%         flush(arduino_port); 
% 
%         samples = [];
%         while length(samples) < 50
%             try
%                 % Read data
%                 raw_str = readline(arduino_port);
%                 val = str2double(raw_str); % Arduino is sending a single float
% 
%                 if ~isnan(val)
%                     samples(end+1) = val;
%                 end
%             catch
%                 % Ignore glitches
%             end
%         end
% 
%         all_voltages(s, w) = mean(samples);
%         fprintf('Saved Average: %.3f V\n', all_voltages(s, w));
%     end
% end

for s = 1:num_sensors
    fprintf('\n--- CALIBRATING SENSOR %d ---\n', s);

    for w = 1:num_weights
        fprintf('Place %dg and press ENTER...', weights(w));
        pause; 

        num_samples = 500; % 100 Hz * 5 seconds = 500 samples
        samples = zeros(num_samples, 1);

        fprintf('Recording %d samples over 5 seconds...', num_samples);
        flush(arduino_port); 

        count = 0;
        while count < num_samples
            try
                raw_str = readline(arduino_port);
                val = str2double(raw_str);

                if ~isnan(val)
                    count = count + 1;
                    samples(count) = val;
                end
            catch
                % Ignore communication glitches
            end
        end

        all_voltages(s, w) = mean(samples);
        fprintf('\nSaved Average: %.3f V\n', all_voltages(s, w));
    end
end
%% 4. Final Plotting and Nonlinear Math
figure('Name', 'Calibration Comparison', 'Color', 'w');
shg; hold on; grid on;
colors = lines(num_sensors);
for s = 1:num_sensors
    v_data = all_voltages(s, :);
    
    % --- LINEAR FIT ---
    p_lin = polyfit(v_data, weights, 1);
    
    % --- QUADRATIC FIT ---
    p_quad = polyfit(v_data, weights, 2); 
    
    % --- POWER LAW FIT ---
    p_power = polyfit(log(v_data), log(weights), 1);
    c2 = p_power(1);        
    c1 = exp(p_power(2));    
    
    % Plot raw data
    plot(v_data, weights, 'o', 'MarkerFaceColor', colors(s,:), 'MarkerSize', 10, ...
        'DisplayName', 'Sensor Data');
    
    % Fit range
    v_fit = linspace(min(v_data), max(v_data), 100);
    
    % Plot fits
    plot(v_fit, polyval(p_lin, v_fit), '--', 'LineWidth', 1.5, 'DisplayName', 'Linear');
    plot(v_fit, polyval(p_quad, v_fit), '-', 'LineWidth', 2, 'DisplayName', 'Quadratic');
    plot(v_fit, c1 .* (v_fit .^ c2), ':', 'LineWidth', 2, 'DisplayName', 'Power Law'); 
    
    % Display coefficients
    fprintf('\n--- Sensor %d Calibration Results ---\n', s);
    fprintf('Quadratic: Weight = %.4f*V^2 + %.4f*V + %.4f\n', p_quad(1), p_quad(2), p_quad(3));
    fprintf('Power Law: Weight = %.4f * V^%.4f\n', c1, c2);
end
xlabel('Voltage (V)'); ylabel('Weight (g)');
legend('Location', 'best');

%% 5. Validation Step (Fixed 500g)
fprintf('\n--- VALIDATION STEP (Target: 500g) ---\n');
test_weight_actual = 500; 

fprintf('Place the 500g weight and press ENTER...');
pause;

% Collect 500 samples (5s @ 100Hz)
num_val_samples = 500; 
val_samples = zeros(num_val_samples, 1);
fprintf('\nRecording 500 samples...');
flush(arduino_port);

count = 0;
while count < num_val_samples
    raw_str = readline(arduino_port);
    val = str2double(raw_str);
    if ~isnan(val)
        count = count + 1;
        val_samples(count) = val;
    end
end

v_avg = mean(val_samples);

% Predict weights
w_pred_lin  = polyval(p_lin, v_avg);
w_pred_quad = polyval(p_quad, v_avg);
w_pred_pwr  = c1 * (v_avg ^ c2);

% Calculate Errors
error_lin  = abs(test_weight_actual - w_pred_lin);
error_quad = abs(test_weight_actual - w_pred_quad);
error_pwr  = abs(test_weight_actual - w_pred_pwr);

% Display Results
fprintf('\n--- Validation Results (Target: %dg) ---', test_weight_actual);
fprintf('\nMeasured Voltage: %.3f V', v_avg);
fprintf('\nPredicted (Lin):  %.2f g (Error: %.2f g)', w_pred_lin, error_lin);
fprintf('\nPredicted (Quad): %.2f g (Error: %.2f g)', w_pred_quad, error_quad);
fprintf('\nPredicted (Pwr):  %.2f g (Error: %.2f g)\n', w_pred_pwr, error_pwr);

