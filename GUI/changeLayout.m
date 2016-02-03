function [ ] = changeLayout(method, handles)
%CHANGELAYOUT Changing the layout of GUI (either training data mode or m.
% file mode)
if method == 1
    set(handles.TrainingSelection, 'String', 'Select training dataset folder');
elseif method == 2
    set(handles.TrainingSelection, 'String', 'Select m.file');  
end

end

