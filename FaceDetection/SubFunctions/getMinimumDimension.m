function croppedImages = getMinimumDimension(cr)

    dimc = [];
    for i=1:size(cr,2)
       dimc = [dimc ; size(cr{i},2)];
    end
    
    mindimc = min(dimc);
    
    for i=1:size(cr,2)
       croppedImages(:,:,i) = cr{i}(:,1:mindimc);
    end
end