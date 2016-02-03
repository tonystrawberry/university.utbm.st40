function [ handles ] = storeParameters( handles )
%STOREPARAMETERS Summary of this function goes here
%   Detailed explanation goes here

    numParam = 7;
    
    for i = 1:numParam        
        handles.parameters(i) = str2double(get(handles.(['param' num2str(i)]), 'string'));   
    end

end

