function [referenceImages, subspaceOrthogonalizedNormalized, projMatrix, faceNames, handles] = presave(handles, croppedImages)
    referenceImages = handles.referenceImages; 
    subspaceOrthogonalizedNormalized = handles.referenceSubspaces;
    projMatrix = handles.projMatrix;
    faceNames = handles.faceNames;
    handles.croppedImages = croppedImages;

    % Save into data.mat file
    save('data.mat', 'projMatrix', 'subspaceOrthogonalizedNormalized', 'referenceImages', 'croppedImages', 'faceNames');
end