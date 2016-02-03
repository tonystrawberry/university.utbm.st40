function [ averageWindow ] = getAverageWindow( windows )
% GETAVERAGEWINDOW Find the average window of a group of windows 
% and return averageWindow = [averageX averageY averageSize averageSize];

    % First compute the average size
    averageSize = round(mean(windows(:,3)));
    
    % Secondly compute average x
    averageX = round(mean(windows(:,1)));
    
    % Thirdly compute average y
    averageY = round(mean(windows(:,2)));
    
    averageWindow = [averageX averageY averageSize averageSize];
end

