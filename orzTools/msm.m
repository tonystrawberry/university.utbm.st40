function [ S ] = msm( input_subspace, reference_subspace )
    
    similarity = [];
    
    transpose_input_subspace = transpose(input_subspace);
    S = zeros(size(reference_subspace,3), 1);
    
    for i =1:size(reference_subspace,3)
        singularvalue = svd(transpose_input_subspace*reference_subspace(:,:,i));
        S(i) = sum(singularvalue.^2); 
    end

end