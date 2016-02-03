function [ Detections ] = postProcessing( InputDetections )
    %POSTPROCESSING PostProcessing (average windows, cropping...)

    % Connected components
    clusterID = 1;
    mapCluster = containers.Map(0,[0 0]);
    % for each detection window from the set
    for i = 1:size(InputDetections,1)
        % get the coordinates x and y and the size
        xi = InputDetections(i,1);
        yi = InputDetections(i,2);
        sizei = InputDetections(i,3)*InputDetections(i,4);
        
        % check if the window is already associated to a cluster or not
        % CiOK = true or false
        % CiID = ID of cluster or -1 if no cluster associated
        [ciOK, ciID] = findCluster(mapCluster, i);
                       
        % for all the other windows
        for j = i+1:size(InputDetections,1)       
            % check cluster
            [cjOK, cjID] = findCluster(mapCluster, j);
            % get the coordinates x and y and the size
            xj = InputDetections(j,1);
            yj = InputDetections(j,2);
            sizej = InputDetections(j,3)*InputDetections(j,4);
            
            % if same size then check if windows are associated or not
            % (same face or not)
            if (sizei == sizej)
                
                if (abs(yj-yi) < InputDetections(i,4)/5 && abs(xj-xi) < InputDetections(i,3)/5)
                    % both are not associated to any cluster
                    if ~ciOK && ~cjOK
                        mapCluster(clusterID) = [i j];
                        ciOK = true; ciID = clusterID;
                        clusterID = clusterID + 1;                           
                    elseif ~cjOK % only window i is associated to a cluster, include j to i's cluster 
                        mapCluster(ciID) = [mapCluster(ciID) j];
                    elseif ~ciOK % only window j is associated to a cluster, include i to i's cluster 
                        mapCluster(cjID) = [mapCluster(cjID) i];
                        ciOK = true; ciID = cjID;
                    end                    
                end           
            end    
            
        end
        
        % if after looping, no association found then create a cluster only
        % for window i
        if ~ciOK 
            mapCluster(clusterID) = [i];
            clusterID = clusterID + 1;
        end
    end
    
    disp(['Number of clusters found : ' num2str(length(mapCluster))-1 ])
%     %TEST
%     for k = 1:length(mapCluster)-1
%         K = mapCluster(k);
%         representative(k, :) = [InputDetections(K(1),:), size(mapCluster(k),2)];
%     end
%     
%     Detections = representative(:,1:4);
    
    
%   if at least one cluster found
    if length(mapCluster)-1 ~= 0 
        % remove duplicates for each cluster
        for k = 1:length(mapCluster)-1
              mapCluster(k) = unique(mapCluster(k));
        end

        representative = zeros(length(mapCluster)-1, 5);
        % for each cluster choose one representative (method to be defined)
        for k = 1:length(mapCluster)-1
            averageWindow = getAverageWindow(InputDetections(mapCluster(k)', :));
            representative(k, :) = [averageWindow, size(mapCluster(k),2)];
        end

        % sort by size in descending order
        [S, I] = sortrows(representative,3);
        I = flip(I);
        representative = representative(I,:);

        % check if there are more overlapping
        i = size(representative, 1);
        while i>1   
            % compute the center coordinate of window i
            centerx = ceil(representative(i,1)*2 + representative(i,4))/2;
            centery = ceil(representative(i,2)*2 + representative(i,4))/2; 
            for j = i-1:-1:1      
                % if center of windows i is inside the windows j
                if centerx > representative(j,1) ...
                        && centerx < representative(j,1)+ representative(j,3) ...
                        && centery > representative(j,2) ...
                        && centery < representative(j,2)+ representative(j,4)                    
                    
%                     % Find the average window
%                     w = [representative(i,:); representative(j,:)];
%                     aw = getAverageWindow(w);

                    % Just keep the smallest window
                    aw = representative(i, 1:4);
                    
                    representative(i, :) = [aw 0];
                    representative(j, :) = [];
                    
                    i = i-1;                       
                    j = j-1;
                   
                end           
            end
            i=i-1;
        end
        % Representative 
        Detections = representative(:,1:4);
    else 
        Detections = []; 
    end
end
          


