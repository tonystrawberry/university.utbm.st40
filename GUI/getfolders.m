function [ dirCleaned ] = getfolders( dir )
%GETFOLDER get all the subfolder of a folder 'dir'

    dirCleaned = dir;
    for k = length(dirCleaned):-1:1
    % remove non-folders
        if ~dirCleaned(k).isdir
            dirCleaned(k) = [ ];
            continue
        end

        % remove folders starting with .
        fname = dirCleaned(k).name;
        if fname(1) == '.'
            dirCleaned(k) = [ ];
        end
    end
end

