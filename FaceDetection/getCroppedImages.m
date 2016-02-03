function [ croppedImages, referenceImages, faceNames] = getCroppedImages( folder, haarCascade, sizeImage, limitScale, limitClusters )
%GETCROPPEDIMAGES Get the cropped face part of each image

    %% Preparation part
    directory = dir(folder);
    directory = getfolders(directory);
    all_dir = directory([directory(:).isdir]);
    num_dir = numel(all_dir); % Number of class (or folders)
    
    croppedImages = cell(1, num_dir);
    referenceImages = cell(1, num_dir);    
    faceNames = cell(1, num_dir);
    sizeRows = sizeImage;
    sizeCols = sizeImage;
    Options.Resize = true;
    Options.LimitScale = limitScale;
    Options.LimitClusters = limitClusters;
    
    %% Apply the Viola-Jones Algorithm to each image, store the original images and build a matrix ...
    % composed of the cropped images
    for i = 1:num_dir       
        
        pathDirectory = strcat(folder, '\', directory(i).name);
        faceNames{i} = directory(i).name;
        contents = dir(pathDirectory);
        contents = getimages(contents);
        ri = [];
        cp = [];
        x = 1;
        for j = 1:numel(contents)            
            Objects = ObjectDetection((strcat(pathDirectory, '\', contents(j).name)), ...
                haarCascade, Options);
            if isempty(Objects) == 1
               continue; 
            end
            
            A = imread(strcat(pathDirectory, '\', contents(j).name)); % A is original image
            B = imcrop(A, Objects(1,:)); % B is the cropped image
            temp = imresize(B, [sizeRows sizeCols]); % image is the resized image
            ri(:, :, :, x) = temp; % store the image in temporary matrix
            temp = rgb2gray(temp); % RGB to gray          
            cp(:,x) = reshape(temp, numel(temp), 1);  % reshape the image to a vector 
            x = x + 1;
        end
        croppedImages{i} = cp;
        referenceImages{i} = ri;
    end

end

