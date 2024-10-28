function [gazeX, gazeY, isFixating] = getGazeCoordinates(eyetracker, scr, visual, fixation, fixationThreshold)
    % Function to get the latest gaze coordinates without clearing the buffer.
    % Inputs:
    %   eyetracker - Tobii controller object (setup before calling this function)
    %   fixationThreshold - Threshold (in degrees of visual angle or pixels) for determining fixation
    %
    % Outputs:
    %   gazeX, gazeY - Latest gaze coordinates in screen pixels
    %   isFixating - Boolean indicating if the participant is fixating within a threshold
    
    % Fetch the latest sample from the Tobii controller
    latestGazeData = eyetracker.get_gaze_data();  % Assuming get_gaze_data retrieves the latest gaze sample
    
    % Check if data is valid and contains gaze coordinates
    if isempty(latestGazeData) || ~isfield(latestGazeData, 'left_gaze_point_on_display_area') || ~isfield(latestGazeData, 'right_gaze_point_on_display_area')
        gazeX = NaN;
        gazeY = NaN;
        isFixating = false;
        return;
    end

    % Extract gaze coordinates for both eyes (averaging them)
    leftEyeGaze = latestGazeData.left_gaze_point_on_display_area;
    rightEyeGaze = latestGazeData.right_gaze_point_on_display_area;

    % Average the X and Y coordinates from both eyes (assuming both eyes give valid data)
    % convert to pixels
    gazeX = mean([leftEyeGaze(1), rightEyeGaze(1)], 'omitnan')*scr.xres;
    gazeY = mean([leftEyeGaze(2), rightEyeGaze(2)], 'omitnan')*scr.yres;

    
    % Calculate distance from the center, and convert in centimeters
    distFromCenter = visual.ppc * sqrt((gazeX - fixation(1))^2 + (gazeY - fixation(2))^2);
    
    % Check if the distance is within the fixation threshold
    isFixating = distFromCenter <= fixationThreshold;
    
    % should we refraint to penalise blinks??
    if isnan(isFixating)
        isFixating = true;
    end
    
    % Return the gaze coordinates and fixation status
end
