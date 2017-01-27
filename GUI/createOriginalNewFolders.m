function [ handles, croppedImages ] = createOriginalNewFolders( handles, croppedImages, folder, k )
    % For every face captured by camera, add the cropped image of the face and its original image
    % to the croppedImages cell array and the referenceImages cell array generated by folder
    % and save the images into folder 'ReferencesImages'
        
    for i = 1:handles.cameraFacesNumber-1
        folder = strcat(folder, ...
                handles.cameraFaceNames{i});
        mkdir(folder);
        for j = 1:size(handles.cameraOriginalReferenceImages{i}, 4)                   
            imwrite(uint8(handles.cameraOriginalReferenceImages{i}(:,:,:,j)), strcat(folder, '\', num2str(j), '.jpg'), 'jpg'); 
        end
    end

end

