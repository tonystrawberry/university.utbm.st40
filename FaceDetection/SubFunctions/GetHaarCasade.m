function HaarCascade=GetHaarCasade(FilenameHaarcasade)
% This function reads a Matlab file with a struct containing 
% the OpenCV classifier data of an openCV XML file.
% It also changes the structure a little bit, and add missing
% fields
%
% HaarCascade=GetHaarCasade(FilenameHaarcasade);
%
%
% Function is written by D.Kroon University of Twente (November 2010)


    load(FilenameHaarcasade);
    f=fields(opencv_storage);
    HaarCascade=opencv_storage.(f{1});
    % Add all missing data-fields
    stages=HaarCascade.stages;
    for i=1:length(stages)
       stages2(i).stage_threshold=stages(i).stage_threshold;
        for j=1:stages(i).maxWeakCount
                a.left_val = stages(i).weakClassifiers(j).leafValues(1);
                a.right_val = stages(i).weakClassifiers(j).leafValues(2);
                a.featureID = stages(i).weakClassifiers(j).internalNodes(3)+1;
                if(~isfield(a,'left_node')) , a.left_node=[]; end
                if(~isfield(a,'right_node')), a.right_node=[];end
                if(~isfield(a,'left_val'))  , a.left_val=[];  end
                if(~isfield(a,'right_val')) , a.right_val=[]; end
                if(isempty(a.left_val)),  a.left_val=-1;  end
                if(isempty(a.right_val)), a.right_val=-1; end
                if(isempty(a.left_node)), a.left_node =-1; end
                if(isempty(a.right_node)),a.right_node=-1; end


                a.rects1=HaarCascade.features(a.featureID).rects(1).value;
                a.rects2=HaarCascade.features(a.featureID).rects(2).value;

                if(length(HaarCascade.features(a.featureID).rects)>2), 
                    a.rects3=HaarCascade.features(a.featureID).rects(3).value;
                else
                    a.rects3=[0 0 0 0 0];
                end

                a.threshold = stages(i).weakClassifiers(j).internalNodes(4);
                 
                % Stage values and features to one big array
                stages2(i).trees(j).value(1,:) = [a.threshold a.left_val a.right_val a.left_node a.right_node a.rects1 a.rects2 a.rects3 0];
        end
    end
    HaarCascade.stages = stages2;
end

