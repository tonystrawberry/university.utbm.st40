function varargout = vjsub(varargin)

    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @vjsub_OpeningFcn, ...
                       'gui_OutputFcn',  @vjsub_OutputFcn, ...
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

% --- Executes just before vjsub is made visible.
function vjsub_OpeningFcn(hObject, eventdata, handles, varargin)

    % Add paths of functions
    addpath('orzTools');
    addpath(genpath('FaceDetection')); 
    addpath(genpath('GUI'));

    %% Training handles
    
    % Use to change the action of 'load' button according to the current
    % state (dataset or mfile)
    field1 = 'TRAININGDATASET'; value1 = 1;
    field2 = 'TRAININGMFILE'; value2 = 2;
    handles.TRAININGCODE = struct(field1, value1, field2, value2);
    handles.state = 1; % state = 1 if dataset mode ; state = 2 if mfile mode
    handles.faceNames = {};
    handles.parameters = [];
    
    handles.HaarCascade=GetHaarCasade('FaceDetection/HaarCascades/haarcascade_frontalface_alt.mat');

      
    %% Camera handles
    
    handles.cameraTextBoxes = {}; % Cell array containing the handles of the textboxes generated dynamically
    handles.cameraTextBoxesGap = 0; % Space value used for the position of the textboxes    
    handles.cameraFacesNumber = 1; % Counter for the number of faces by camera
    handles.cameraSubspaces = []; % Array containing subspaces of all faces by camera
    handles.cameraReferenceImages = []; % Array containing the reference images
%     handles.cameraOriginalReferenceImages = []; % Array containing the original reference images
    handles.cameraFaceNames = {}; % Array containing the names of all faces taken by camera
    
    handles.video = videoinput('kinect', 1); % Creating a video input

    %% General handles
    
    handles.selected = ''; % Folder or file currently selected
    
    %% GUI 
    
    % Create tab group
    handles.tgroup = uitabgroup('Parent', handles.figure1,'TabLocation', 'top');
    handles.tab1 = uitab('Parent', handles.tgroup, 'Title', 'Training');
    handles.tab2 = uitab('Parent', handles.tgroup, 'Title', 'Recognition');
    handles.tab3 = uitab('Parent', handles.tgroup, 'Title', 'Parameters');
    
    % Place panels into each tab
    set(handles.Panel1,'Parent',handles.tab1);
    set(handles.Panel2,'Parent',handles.tab2);
    set(handles.Panel3,'Parent',handles.tab3);    
    
    % Reposition each panel to same location as panel 1
    set(handles.Panel2,'position',get(handles.Panel1,'position'));
    set(handles.Panel3,'position',get(handles.Panel1,'position'));
       
    % Hide recognition picture axis
    set(handles.outputImage,'xcolor',get(gcf,'color'));
    set(handles.outputImage, 'xtick', []);
    set(handles.outputImage,'ycolor',get(gcf,'color'));
    set(handles.outputImage, 'ytick', []);   
    
    set(handles.inputImage,'xcolor',get(gcf,'color'));
    set(handles.inputImage, 'xtick', []);
    set(handles.inputImage,'ycolor',get(gcf,'color'));
    set(handles.inputImage, 'ytick', []);
    
    % Store default parameters
    handles = storeParameters(handles);
    
    % Hide camera handles
    set(handles.cameraAxes, 'Visible', 'Off');
    set(get(handles.cameraAxes,'children'),'visible','off');
    
    % Choose default command line output for vjsub
    handles.output = hObject;
    
    % Update handles structure
    guidata(hObject, handles);
    
end

% --- Outputs from this function are returned to the command line.
function varargout = vjsub_OutputFcn(hObject, eventdata, handles) 
    handles.output = hObject;
    varargout{1} = handles.output;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% TRAINING PART
%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in TrainingSelection.
function TrainingSelection_Callback(hObject, eventdata, handles)    
    switch handles.state % state can be 'dataset' or 'm-file'
        case handles.TRAININGCODE.TRAININGDATASET
            folder_name = uigetdir;
            text_handle = handles.trainingTXT;
            set(text_handle, 'String', folder_name);    
            handles.selected = folder_name;            
        case handles.TRAININGCODE.TRAININGMFILE
            [file_name, folder] = uigetfile;
            text_handle = handles.trainingTXT;
            set(text_handle, 'String', file_name);    
            handles.selected = strcat(folder, file_name);
    end
    guidata(hObject, handles);
end

% --- Executes on selection change in TrainingPopupMenu.
function TrainingPopupMenu_Callback(hObject, eventdata, handles)

    contents = get(hObject, 'Value');    
    switch contents        
        case 1 % generate a new reference subspace
            changeLayout(1, handles);
            handles.state = 1;
        case 2 % load a pre-processed subspace from matlab file
            changeLayout(2, handles);      
            handles.state = 2;
    end
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function TrainingPopupMenu_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end

% --- Executes on button press in TrainingCameraLoad.
function TrainingCameraLoad_Callback(hObject, eventdata, handles)      
    switch handles.state
        case handles.TRAININGCODE.TRAININGDATASET

            %% Get parameters
            [dim, kP, sI, nP, lS, lC, tP, tTE] = getParameters(handles);
                        
            %% Delete double (replace old folder by new dataset from camera if same name)
            folder = 'C:\Users\Tony\Documents\MATLAB\FaceRecognitionSystem2016\ReferencesImages\';
            deleteDouble(handles, folder);
                        
            %% Apply face detection for each face of the dataset
            [croppedImages, handles.referenceImages, handles.faceNames] = getCroppedImages(handles.selected, handles.HaarCascade, sI, lS, lC);                               

            %% 'Subspace of variable size' version
                        
            %% Create new folders for new faces
            
            [handles, croppedImages] = createNewFolders(handles, croppedImages, folder);
%             [handles, croppedImages] = createOriginalNewFolders(handles, croppedImages, ofolder);
                        
            %% Normalization of all the vectors
            for i = 1:size(croppedImages,2)
                croppedImages{i} = orzNormalize(croppedImages{i});                
            end
               
            %% Get the dimension (here just get the smallest dimension possible)
            wishedDim = getDimension(croppedImages, dim);
                        
            %% Application of KOMSM
            OB = OrzKOMSMV2(croppedImages, wishedDim, kP);
            [V2] = TransformS(OB, croppedImages, wishedDim);
                       
            handles.referenceSubspaces = V2;
            handles.projMatrix = OB;
            
            %% Save...
            [referenceImages, subspaceOrthogonalizedNormalized, projMatrix, faceNames, handles] = presave(handles, croppedImages);
                       
        case handles.TRAININGCODE.TRAININGMFILE
            temp = load(handles.selected, 'projMatrix', 'subspaceOrthogonalizedNormalized', 'referenceImages', ...
                'croppedImages', 'faceNames');
            
            handles = getDataMFile(handles, temp);            
    end
    guidata(hObject, handles);
    
end

% --- Executes on button press in TrainingAddFaceCamera.
function TrainingAddFaceCamera_Callback(hObject, eventdata, handles)
    
    guidata(hObject, handles);
    handles.mode = 1; % mode = 1 when used for training ; mode = 2 when used for recognition/classification
    
    %% Get parameters
    [dim, kP, sI, nP, lS, lC, tP, tTE] = getParameters(handles);   
    
    % Send the parameters
    
    setappdata(0, 'mode', 'train');
    setappdata(0, 'nP', nP); % number of pictures
    setappdata(0, 'tP', tP); % timer period
    setappdata(0, 'lS', lS); % limit scale
    setappdata(0, 'lC', lC); % limit clusters
    setappdata(0, 'sI', sI); % size of image
    setappdata(0, 'tTE', tTE); % tasks to execute (or number of frames to process)
    
    myCameraGUI; % display the camera GUI
     
    if ~isempty(getappdata(0, 'camFaceName'))   % getappdata(0, 'camSubspace') returns the subspace corresponding to the face 
        handles.cameraSubspaces{handles.cameraFacesNumber} = double(getappdata(0, 'camSubspace'));
        handles.cameraReferenceImages{handles.cameraFacesNumber} = getappdata(0, 'camReferenceImage');
%         handles.cameraOriginalReferenceImages{handles.cameraFacesNumber} = getappdata(0, 'camOriginalReferenceImage');
        handles.cameraFaceNames{handles.cameraFacesNumber} = getappdata(0, 'camFaceName');
        
        % Dynamically create a textbox, set the text and position
        [handles, mTextBox] = createFaceNameText(handles);
               
        guidata(hObject, handles);
    end
end

% --- Executes on button press in TrainingReset.
function TrainingReset_Callback(hObject, eventdata, handles)
    
    % Delete all the data related to the faces obtained by camera
    for i = 1:size(handles.cameraTextBoxes, 2) 
        delete(handles.cameraTextBoxes{i});
    end
    
    handles.cameraSubspaces = [];
    handles.cameraReferenceImages = [];
%     handles.cameraOriginalReferenceImages = [];
    handles.cameraSubspaces = [];
    handles.cameraFacesNumber = 1;
    handles.cameraTextBoxesGap = 0;  
    guidata(hObject, handles);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% RECOGNITION PART 
%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on selection change in RecogPopupMenu.
function RecogPopupMenu_Callback(hObject, eventdata, handles)

    contents = get(hObject, 'Value');    
    switch contents        
        case 1 % photo mode
            changeLayoutRecog(1, handles);
        case 2 % camera mode
            handles.mode = 2;
            guidata(hObject, handles);
            changeLayoutRecog(2, handles); 
            
            % Send the mode (recognition mode)
            setappdata(0, 'mode', 'recog');
            setappdata(0, 'handles', handles);
            
            [dim, kP, sI, nP, lS, lC, tP, tTE] = getParameters(handles);
            
            % Send the parameters
    
            setappdata(0, 'nP', nP); % number of pictures
            setappdata(0, 'tP', tP); % timer period
            setappdata(0, 'lS', lS); % limit scale
            setappdata(0, 'lC', lC); % limit clusters
            setappdata(0, 'sI', sI); % size of image
            setappdata(0, 'tTE', tTE); % tasks to execute (or number of frames to process)

            
            % Display the camera GUI and retrieve the photo
            myCameraGUI;
            handles.selected = getappdata(0, 'inputPhoto');
            axes(handles.cameraAxes);
            imshow(handles.selected);
    end
    guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function RecogPopupMenu_CreateFcn(hObject, eventdata, handles)

    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end

% --- Executes on button press in RecogPhotoSelection.
function RecogPhotoSelection_Callback(hObject, eventdata, handles)
    [file_name, folder] = uigetfile;
    text_handle = handles.recogTXT;
    set(text_handle, 'String', file_name);    
    handles.selected = imread(strcat(folder, file_name));   
                     
    guidata(hObject, handles);
end

% --- Executes on button press in RecogPerform.
function RecogPerform_Callback(hObject, eventdata, handles)

    %% Get parameters
    [dim, kP, sI, nP, lS, lC, tP, tTE] = getParameters(handles);   

    wishedDim = 1; % wishedDim is 1 because 1 vector

    %% Detect Faces
    Options.Resize = true;
    Options.LimitScale = lS;
    Options.LimitCluster = lC;
        
    [croppedImage, image] = getCroppedImage(handles.selected, handles.HaarCascade, sI, lS, lC);
    
    
    %% Get projected input subspace
    
    imcell{1} = orzNormalize(croppedImage);
    im = imcell{1};
    
    [V3 A2] = TransformS(handles.projMatrix, imcell, wishedDim);

    S = msm(V3,handles.referenceSubspaces); % Calculation of the similarity

    [~, I] = max(S(:));

    output = uint8(handles.referenceImages{I}(:,:,:,1)); % output is reference image 
    input = uint8(reshape(croppedImage, sI, sI)); % input is test image

    % Hide camera handles
    set(handles.cameraAxes, 'Visible', 'Off');
    set(get(handles.cameraAxes,'children'),'visible','off');
    
    axes(handles.inputImage);
    imshow(input);
    axes(handles.outputImage);
    imshow(output);
    set(handles.outputName, 'String', handles.faceNames{I});
    
    %% Ask the user to add the input image or not
    button = questdlg('Add input image to dataset ?', 'Add input image to dataset', 'Yes', 'No', 'No');
    
    switch button
        case 'Yes'
            %% Add the input image and reference image to dataset
            handles.croppedImages{I}(:, size(handles.croppedImages,2)+1) = im;
            handles.croppedImages{I} = transpose(unique(transpose(handles.croppedImages{I}), 'rows'));
            
            wishedDim = getDimension( handles.croppedImages, dim );
                      
            %% Recalculate subspace, reperform KOMSM
            OB = OrzKOMSMV2(handles.croppedImages, wishedDim, 0.1);
            [V2] = TransformS(OB, handles.croppedImages, wishedDim);
                       
            handles.referenceSubspaces = V2;
            handles.projMatrix = OB;
            
            
            %% Save...
            [referenceImages, subspaceOrthogonalizedNormalized, projMatrix, faceNames, handles] = presave(handles, handles.croppedImages);
            folder = strcat('C:\Users\Tony\Documents\MATLAB\FaceRecognitionSystem2016\ReferencesImages', '\',handles.faceNames{I});
%             ofolder = strcat('C:\Users\Tony\Documents\MATLAB\FaceRecognitionSystem2016\OriginalReferencesImages', '\',handles.faceNames{I});

            for i = 1:1000
                if exist(strcat(folder, '\', num2str(i), '.jpg'), 'file') == 0
                    imwrite(uint8(image), strcat(folder, '\', num2str(i), '.jpg'), 'jpg'); break;
                end
            end
        case 'No'
    end
            
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% PARAMETERS PART 
%%%%%%%%%%%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in apply.
function apply_Callback(hObject, eventdata, handles)

    handles = storeParameters(handles);
    guidata(hObject, handles);

end

% --- Executes when user attempts to close vjsub.
function vjsub_CloseRequestFcn(hObject, eventdata, handles)

    % Hint: delete(hObject) closes the figure
    
    % delete all application-defined data
    rmappdata(0, 'mode');
    rmappdata(0, 'handles');
    rmappdata(0, 'mode');
    rmappdata(0, 'nP');
    rmappdata(0, 'tP');
    rmappdata(0, 'lS');
    rmappdata(0, 'lC');
    rmappdata(0, 'sI');
    rmappdata(0, 'tTE');
    
    delete(hObject);
    delete(imaqfind);
end

% --- Executes during object creation, after setting all properties.
function param1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function param2_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- Executes during object creation, after setting all properties.
function param3_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

end

% --- Executes during object creation, after setting all properties.
function param4_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function param5_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function param6_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes during object creation, after setting all properties.
function param7_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end



function param1_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param2_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param3_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param4_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param5_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param6_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end

function param7_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double
end



function param8_Callback(hObject, eventdata, handles)
% hObject    handle to param8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of param8 as text
%        str2double(get(hObject,'String')) returns contents of param8 as a double
end

% --- Executes during object creation, after setting all properties.
function param8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to param8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
