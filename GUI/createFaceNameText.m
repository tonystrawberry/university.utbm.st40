function [handles, mTextBox] = createFaceNameText(handles)
    mTextBox = uicontrol(handles.Panel1,'style','text');
    set(mTextBox,'String', strcat(num2str(handles.cameraFacesNumber), '. ', handles.cameraFaceNames{handles.cameraFacesNumber}));
    set(mTextBox, 'Position', [30 60-handles.cameraTextBoxesGap 130 30]);
    handles.cameraTextBoxes{handles.cameraFacesNumber} = mTextBox;
    handles.cameraTextBoxesGap = handles.cameraTextBoxesGap + 20;
    handles.cameraFacesNumber = handles.cameraFacesNumber + 1;
end