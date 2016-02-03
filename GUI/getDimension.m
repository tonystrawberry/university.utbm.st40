function [ wishedDim ] = getDimension( croppedImages, dim )
    DIM = zeros(1,size(croppedImages,2)+1);
    DIM(1) = dim;    
    for i = 1:size(croppedImages,2)
        DIM(i+1) = size(croppedImages{i},2);
    end

    wishedDim = min(DIM);
end

