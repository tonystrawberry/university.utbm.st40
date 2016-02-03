function [] = deleteDouble(handles, folder)
    for i = 1:handles.cameraFacesNumber-1
        folder = strcat(folder, ...
                handles.cameraFaceNames{i});
        if exist(folder, 'dir')
            rmdir(folder, 's');
        end
    end
end