function [ croppedImage image, square] = getCroppedImage(image, HaarCascade, sizeImage, limitScale, limitClusters)
     %% Preparation part
        sizeRows = sizeImage;
        sizeCols = sizeImage;
        Options.Resize = true;
        Options.Verbose = true;
        Options.LimitScale = limitScale;
        Options.LimitClusters = limitClusters;
        
        Objects = ObjectDetection(image,HaarCascade, Options);
        square = 0;
        if isempty(Objects) == 0   
            square = Objects(1,:); % used for drawing rectangle around the face
            B = imcrop(image, Objects(1,:)); % B is the cropped image
            temp = imresize(B, [sizeRows sizeCols]); % image is the resized image
            im = rgb2gray(temp); % RGB to gray          
            croppedImage = reshape(im, numel(im), 1);  % reshape the image to a vector 
        else
            croppedImage = 0;
        end

end

