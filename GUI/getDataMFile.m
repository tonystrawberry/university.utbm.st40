function [ handles ] = getDataMFile( handles, data )
    handles.referenceSubspaces = data.subspaceOrthogonalizedNormalized;
    handles.referenceImages = data.referenceImages;
    handles.projMatrix = data.projMatrix;
    handles.faceNames = data.faceNames;
    handles.croppedImages = data.croppedImages;
end