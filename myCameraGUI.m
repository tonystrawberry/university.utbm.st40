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
    
    % Choose default command line output for mycameragui
    handles.output = hObject;
    handles.processing = 0;
    handles.currentRectangle = 0;
    handles.trackenable = 0;
    handles.cr = [];
    handles.ref = [];
    handles.g = 1;
    
    handles.numberPictures = getappdata(0, 'nP');
    handles.timerPeriod = getappdata(0, 'tP');
    handles.lS = getappdata(0, 'lS');
    handles.lC = getappdata(0, 'lC');
    handles.sI = getappdata(0, 'sI');
    
    period = handles.timerPeriod; % period in seconds, in which the timer shall execute
    handles.HaarCascade=GetHaarCasade('FaceDetection/HaarCascades/haarcascade_frontalface_alt.mat');

    %% Create video object

    handles.video = videoinput('kinect', 1);
    
    handles.startTrackerface = timer(...
    'TimerFcn', {@startTrackFcn,hObject}, ...
    'ExecutionMode', 'fixedDelay', ...
    'Period', period, ...
    'TasksToExecute', 100);


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
        start(handles.trackerface);        
    elseif handles.g > handles.numberPictures        
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

            if handles.currentRectangle ~= 0
                delete(handles.currentRectangle);
                handles.currentRectangle = 0;
            end

            img = getsnapshot(handles.video);
            img = imresize(img,0.09);
            if handles.processing == 0
                handles.processing = 1;
                tic;
                [croppedImage, img, square] = getCroppedImage(img, handles.HaarCascade, handles.sI, handles.lS, handles.lC);
                if square ~= 0
                    disp(square);               
                    handles.currentRectangle = rectangle('Parent', handles.cameraAxes, 'Position', uint8(square.*1/0.09));
                end           
                toc
                if croppedImage ~= 0
                    handles.cr = [handles.cr croppedImage];
                    handles.ref(:,:,:,handles.g) = img;
                    handles.g = handles.g + 1;
                end          
                handles.processing = 0;
            end
        case 'recog'
            h = getappdata(0, 'handles');
            handles = guidata(hObject);

            if handles.currentRectangle ~= 0
                delete(handles.currentRectangle);
                handles.currentRectangle = 0;
            end

            img = getsnapshot(handles.video);
            img = imresize(img,0.09);
            if handles.processing == 0
                handles.processing = 1;
                tic;
                [croppedImage, img, square] = getCroppedImage(img, handles.HaarCascade, handles.sI, handles.lS, handles.lC);
                if square ~= 0
                    disp(square);               
                    handles.currentRectangle = rectangle('Parent', handles.cameraAxes, 'Position', uint8(square.*1/0.09));
                end           
                toc
                
                
                if croppedImage ~= 0
                    wishedDim = 1; % wishedDim is 1 because 1 vector
                    % cell-type needed
                    temp{1} = orzNormalize(croppedImage); 

                    %% Get projected input subspace
                    [V3 A3] = TransformS(h.projMatrix, temp, wishedDim);

                    S = msm(V3, h.referenceSubspaces); % Calculation of the similarity

                    [~, I] = max(S(:));

                    set(handles.messageAcquisition, 'String', h.faceNames{I});
                end          
                handles.processing = 0;
            end
    end
        
        guidata(hObject, handles);     
        
end

% --- Executes when user attempts to close myCameraGUI.
function myCameraGUI_CloseRequestFcn(hObject, eventdata, handles)

%     if isappdata(0, 'camSubspace'), rmappdata(0, 'camSubspace'); end
%     if isappdata(0, 'camReferenceImage'), rmappdata(0, 'camReferenceImage'); end
%     if isappdata(0, 'inputPhoto'), rmappdata(0, 'inputPhoto'); end
%     if isappdata(0, 'camFaceName'), rmappdata(0, 'camFaceName'); end
    
    delete(hObject);
    delete(imaqfind);
end

% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)

    x = get(handles.FaceName, 'String');
    if isempty(x) || isempty(getappdata(0,'camSubspace'))
       
    else
        % Write code for computation you want to do
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
