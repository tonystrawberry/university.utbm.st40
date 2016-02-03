function [ Picture, Ratio ] = getPreProcessingImage( Input, Options)
% GETPREPROCESSINGIMAGE PreProcessing (Resizing, Grayscale, Historigram
% enhancement to increase the recognition rate)

    % Convert the Picture to double 
    % (grey-level scaling doesn't influence the result, thus 
    % double instead of im2double can also be used)
    Picture=im2double(Input);
    
    % Resize the image to decrease the processing-time
    if(Options.Resize)
        if (size(Picture,2) > size(Picture,1)),
            Ratio = size(Picture,2) / 384;
        else
            Ratio = size(Picture,1) / 384;
        end
        if (Ratio > 1)
            Picture = imresize(Picture, [size(Picture,1) size(Picture,2) ]/ Ratio);            
        else
           Ratio = 1; 
        end
    else
        Ratio=1;
    end
    
    % Convert the picture to greyscale (this line is the same as rgb2gray, see help)
    if(size(Input, 3)>1),
        Picture=0.2989*Picture(:,:,1) + 0.5870*Picture(:,:,2)+ 0.1140*Picture(:,:,3);
    end
    % Histogram enhancement
    Picture = histeq(Picture);
    
    Picture = imadjust(Picture);
        
end

