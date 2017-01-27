function [dim, kP, sI, nP, lS, lC, timerPeriod, tTE] = getParameters(handles)
    dim = handles.parameters(1); % dimension wished
    kP = handles.parameters(2); % Kernel parameter
    sI = handles.parameters(3); % Size Image
    nP = handles.parameters(4);
    lS = handles.parameters(5); % limit scale
    lC = handles.parameters(6); % limit clusters
    timerPeriod = handles.parameters(7);
    tTE = handles.parameters(8);
    
end