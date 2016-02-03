function [ ] = changeLayoutRecog(method, handles)
%CHANGELAYOUT Change layout for recognition part (either picture or camera)
if method == 1
    set(handles.recogTXT, 'Visible', 'On');
    set(handles.RecogPhotoSelection, 'Visible', 'On');
    set(handles.inputImage, 'Visible', 'On'); set(get(handles.outputImage,'children'),'visible','On');
    set(handles.outputImage, 'Visible', 'On'); set(get(handles.inputImage,'children'),'visible','On');
    set(handles.inputName, 'Visible', 'On');
    set(handles.outputName, 'Visible', 'On');
          
    set(handles.cameraAxes, 'Visible', 'Off');
    set(get(handles.cameraAxes,'children'),'visible','off');
elseif method == 2
    set(handles.recogTXT, 'Visible', 'Off'); 
    set(handles.RecogPhotoSelection, 'Visible', 'Off');
    set(handles.inputImage, 'Visible', 'Off'); set(get(handles.outputImage,'children'),'visible','Off');
    set(handles.outputImage, 'Visible', 'Off'); set(get(handles.inputImage,'children'),'visible','Off');
    set(handles.inputName, 'Visible', 'On');
    set(handles.inputName, 'Visible', 'Off');
    set(handles.outputName, 'Visible', 'Off');

    set(handles.cameraAxes, 'Visible', 'On');
    set(get(handles.cameraAxes,'children'),'visible','on')
end

