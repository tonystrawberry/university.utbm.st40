function [ clusterOK, clusterID ] = findCluster( mapCluster, i )
%FINDCLUSTER Summary of this function goes here
%   Detailed explanation goes here
            % Loop through map to check if i exists in a cluster
            
        clusterOK = false;
        Found = false;
        for k = 0:length(mapCluster)-1
           Found = find(mapCluster(k)==i);
           if ~isempty(Found)
               clusterID = k;
               clusterOK = true;
               break
           end
        end
        if ~clusterOK
            clusterID = -1;
        end

end

