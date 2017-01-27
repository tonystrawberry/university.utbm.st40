function varargout = myCameraGUI(varargin)

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @myCameraGUI_OpeningFcn, ...
                       'gui_OutputFcn',  @myCameraGUI_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    
end


% --- Executes just before mycameragui is made visible.
function myCameraGUI_OpeningFcn(hObject, eventdata, handles, varargin)

    addpath(genpath('FaceDetection'));
        
    % Retrieve all the application-defined data 
    handles.numberPictures = getappdata(0, 'nP');
    handles.timerPeriod = getappdata(0, 'tP');
    handles.lS = getappdata(0, 'lS');
    handles.lC = getappdata(0, 'lC');
    handles.sI = getappdata(0, 'sI');
    handles.tTE = getappdata(0, 'tTE');
    
    handles.output = hObject;
    handles.processing = 0;
    handles.currentRectangle = 0;
    handles.trackenable = 0; % trigger 
    handles.cr = [];
    handles.ref = zeros(ceil(480*0.09),ceil(640*0.09),3,handles.numberPictures);
    
    % used for statistics
    handles.totaltimeFaceDetection = 0; handles.totaltimeFaceDetectionCount = 0;
    handles.totaltimeNonFaceDetection = 0; handles.totaltimeNonFaceDetectionCount = 0;

    handles.g = 1; % counter for faces detected only
    handles.count = 1; % overall counter (frames with detected faces and frames without detected faces) 
    
    period = handles.timerPeriod; % period in seconds, in which the timer shall execute
    handles.HaarCascade=GetHaarCasade('FaceDetection/HaarCascades/haarcascade_frontalface_alt.mat');

    %% Create video object

    handles.video = videoinput('kinect', 1);
    
    handles.startTrackerface = timer(...
    'TimerFcn', {@startTrackFcn,hObject}, ...
    'ExecutionMode', 'fixedDelay', ...
    'Period', period, ...
    'TasksToExecute', handles.tTE);

    handles.trackerface = timer(...
    'TimerFcn', {@trackFcn,hObject}, ...
    'ExecutionMode', 'fixedDelay', ...
    'Period', period, ...
    'TasksToExecute', 1);

    % Update handles structure
    guidata(hObject, handles);
    
    %% Start the tracker (it will process the timer function every 0.25 sec)
    start(handles.startTrackerface);   
    
    % UIWAIT makes mycameragui wait for user response (see UIRESUME)
    uiwait(handles.myCameraGUI);

end


% --- Outputs from this function are returned to the command line.
function varargout = myCameraGUI_OutputFcn(hObject, eventdata, handles)

    % Get default command line output from handles structure
    handles.output = hObject;
    varargout{1} = handles.output;
end

function startTrackFcn(hTimer, timerEvt, hObject)
       
    handles = guidata(hObject);

    handles.trackerface = timer(...
    'TimerFcn', {@trackFcn,hObject}, ...
    'ExecutionMode', 'fixedDelay', ...
    'TasksToExecute', 1);       

    if (handles.trackenable == 1 && handles.g <= handles.numberPictures)
        % delete black rectangle
        if handles.currentRectangle ~= 0
            delete(handles.currentRectangle);
            handles.currentRectangle = 0;
        end
        start(handles.trackerface);        
    elseif handles.g > handles.numberPictures        
        % delete black rectangle
        if handles.currentRectangle ~= 0
            delete(handles.currentRectangle);
            handles.currentRectangle = 0;
        end
        
        % send reference subspaces and images
        setappdata(0,'camSubspace',handles.cr);
        setappdata(0,'camReferenceImage', handles.ref); 
        stop(hTimer);
    end
end

% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
    % Start/Stop Camera
    if strcmp(get(handles.startStopCamera,'String'),'Start Camera')
        % Camera is off. Change button string and start camera.
        set(handles.startStopCamera, 'String', 'Stop Camera')
        axes(handles.cameraAxes);
        vidRes = handles.video.VideoResolution; 
        nBands = handles.video.NumberOfBands; 
        handles.cameraAxes = image(zeros(vidRes(2), vidRes(1), nBands)); 
        preview(handles.video, handles.cameraAxes)
        set(handles.startAcquisition,'Enable','on');
        set(handles.captureImage,'Enable','on');
    else
        % Camera is on. Stop camera and change button string.
        set(handles.startStopCamera,'String','Start Camera')
        closepreview(handles.video)
        set(handles.startAcquisition,'Enable','off');
        set(handles.captureImage,'Enable','off');
    end
end

% --- Executes on button press in captureImage.
function captureImage_Callback(hObject, eventdata, handles)
    frame = get(get(handles.cameraAxes,'children'),'cdata'); % The current displayed frame
    setappdata(0, 'inputPhoto', frame);
end

% --- Executes on button press in startAcquisition.
function startAcquisition_Callback(hObject, eventdata, handles)   
    if  handles.trackenable == 0
        % Generation of figures
        mode = getappdata(0, 'mode');   
        switch (mode)
            case 'train'                
                % Create figure
                handles.dataComputationTime = figure;
                axis([0 handles.tTE 0 0.5]);
                set( gca, 'XLimMode', 'manual', 'YLimMode', 'manual');
                title('Computation time of face detection')
                xlabel('frames') % x-axis label
                ylabel('time (s)') % y-axis label
                guidata(hObject, handles);                
            case 'recog'                
                % Create figure
                handles.dataSimilarity = figure;
                axis([0 handles.tTE 0 1]);
                set( gca, 'XLimMode', 'manual', 'YLimMode', 'manual');
                h = getappdata(0, 'handles');
                handles.list = hsv(h.projMatrix.nClass);
                for i=1:h.projMatrix.nClass
                   plot(0, 0, 'o', 'color', handles.list(i,:));
                   legendInfo{i} = [h.faceNames{i}];
                   hold on;
                end
                legend(legendInfo);
                title('Graph of similarity')
                xlabel('frames') % x-axis label
                ylabel('similairity value') % y-axis label
                guidata(hObject, handles);                
        end
        set(handles.startAcquisition, 'string', 'Stop Acquisition');
        handles.trackenable = 1;
    else
        set(handles.startAcquisition, 'string', 'Start Acquisition');
        handles.trackenable = 0;
    end
    guidata(hObject, handles);
end

function trackFcn(hTimer, timerEvt, hObject)
    % your send-loop-code
    mode = getappdata(0, 'mode');    
    switch (mode)
        case 'train'
            handles = guidata(hObject);                                
            img = getsnapshot(handles.video); % get the frame      
            imgResized = imresize(img,0.09); % resize the frame
            if handles.processing == 0
                handles.processing = 1;
                tic;
                [croppedImage, imgResized, square] = getCroppedImage(imgResized, handles.HaarCascade, handles.sI, handles.lS, handles.lC);
                timeFaceDetection = toc
                
                % plot COMPUTATION TIME for stats
                tic;
                plot(handles.count, timeFaceDetection, '-o');
                hold on;
                axis([0 handles.tTE 0 0.5]);
                plotTime = toc
                                               
                handles.count = handles.count +1;                             
                if square ~= 0 % face found then draw rectangle
                    tic;
                    handles.currentRectangle = rectangle('Parent', handles.cameraAxes, 'Position', uint8(square.*1/0.09));
                    handles.totaltimeFaceDetection = handles.totaltimeFaceDetection+timeFaceDetection;
                    handles.totaltimeFaceDetectionCount = handles.totaltimeFaceDetectionCount + 1;
                    timeDrawing = toc
                else 
                    handles.totaltimeNonFaceDetection = handles.totaltimeNonFaceDetection+timeFaceDetection;
                    handles.totaltimeNonFaceDetectionCount = handles.totaltimeNonFaceDetectionCount + 1;
                end
                tic;
                if croppedImage ~= 0 % face found then save the cropped images and the original resized image
                    handles.cr = [handles.cr croppedImage];
                    handles.ref(:,:,:,handles.g) = imgResized;
                    handles.g = handles.g + 1;
                end
                timeStorage = toc
                handles.processing = 0;
            end                       
        case 'recog'
            h = getappdata(0, 'handles');
            handles = guidata(hObject);
            if handles.currentRectangle ~= 0
                delete(handles.currentRectangle);
                handles.currentRectangle = 0;
            end
            imgResized = getsnapshot(handles.video);
            imgResized = imresize(imgResized,0.09);
            if handles.processing == 0
                handles.processing = 1;              
                [croppedImage, imgResized, square] = getCroppedImage(imgResized, handles.HaarCascade, handles.sI, handles.lS, handles.lC);
                if square ~= 0
                    disp(square);               
                    handles.currentRectangle = rectangle('Parent', handles.cameraAxes, 'Position', uint8(square.*1/0.09));
                end                           
                if croppedImage ~= 0 % face found then perform the recognition 
                    wishedDim = 1; % wishedDim is 1 because 1 vector
                    temp{1} = orzNormalize(croppedImage);                    
                    %% Get projected input subspace
                    [V3 A3] = TransformS(h.projMatrix, temp, wishedDim);

                    S = msm(V3, h.referenceSubspaces); % Calculation of the similarity

                    [~, I] = max(S(:));
                    
                    % plot SIMILARITY for stats
                    tic;
                    for i = 1:numel(S)                   
%                         set(handles.hLine{i}, 'Xdata', handles.count, 'Ydata', S(i));      
                        plot(handles.count, S(i), 'o', 'color', handles.list(i,:));
                        hold on;
                        axis([0 handles.tTE 0 1]);
                        hold on; 
                    end
                    handles.count = handles.count+1;
                    guidata(hObject, handles);                     
                    plotTime = toc
                    
                    % write the face names below the screen
                    set(handles.messageAcquisition, 'String', h.faceNames{I});
                end          
                handles.processing = 0;
            end
    end
    guidata(hObject, handles);     
        
end

% --- Executes when user attempts to close myCameraGUI.
function myCameraGUI_CloseRequestFcn(hObject, eventdata, handles)    
    delete(hObject);
    delete(imaqfind);
end

% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)

    x = get(handles.FaceName, 'String');
    if isempty(x) || isempty(getappdata(0,'camSubspace'))
       
    else
        % send information to main window
        setappdata(0,'camFaceName', x);
        delete(handles.myCameraGUI);
        delete(imaqfind); 
    end
    
end

% --- Executes during object creation, after setting all properties.
function FaceName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FaceName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function FaceName_Callback(hObject, eventdata, handles)

end
