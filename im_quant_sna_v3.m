%%                             im_quant_sna_v3
% Alistair Boettiger                                   Date Begun: 09/25/08
% Levine Lab                                     Version Complete: 02/01/10  
% In Progress                                       Last Modified: 02/15/11


%% Notes
% This code requires bioinformatics toolbox for the graph shortest path
% algorithm. 
% 
%% Updates
% 02/15/11 Modified to correctly call new version of fxn_nuc_seg.
% 01/28/10 Started Version 3 development: incoperpate Jacques nuclear
% segmentation.  
% 01/12/10 modified to export gradients in terms of pixels.  
% 12/3/09 accelerated step 6 from 10 (with plotting) to 60-fold (without plotting).  
%

% To do:


function varargout = im_quant_sna_v3(varargin)

% Last Modified by GUIDE v2.5 28-Jan-2010 22:17:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @im_quant_sna_v3_OpeningFcn, ...
                   'gui_OutputFcn',  @im_quant_sna_v3_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before im_quant_sna_v3 is made visible.
function im_quant_sna_v3_OpeningFcn(hObject, eventdata, handles, varargin)
handles.step = 1;
handles.output = hObject; 
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = im_quant_sna_v3_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;





function run_Callback(hObject, eventdata, handles)
if handles.step==1
    % get field values
    slide = get(handles.edit1,'String');
    gene = get(handles.edit2,'String');
    embnum = get(handles.edit3,'String');
    sna_chn = str2double(get(handles.edit4,'String')); % snail staining channel
    nuc_chn = str2double(get(handles.edit5,'String')); % nuclei channel
    flpH = str2double(get(handles.edit6,'String')); % Flip Horizontal?
    flpV = str2double(get(handles.edit7,'String'));

    folder = get(handles.folderfield,'String');
    fn = [folder,'/', slide,'_',gene,'_',embnum,'.tif'];   
    
    % upload image and split color data
    try
        I = imread(fn); 
    catch 
        disp(['cannot find file ', fn]);
        disp('update load fields and try again');
        I = uint8(zeros(1024,1024));
    end
     
   
    % flip horizontal if required
    if flpH == 1
        I1 = fliplr(I(:,:,1));
        I2 = fliplr(I(:,:,2));
        I3 = fliplr(I(:,:,3));
        I(:,:,1) = I1;
        I(:,:,2) = I2;
        I(:,:,3) = I3;
    end
    
        % flip horizontal if required
    if flpV == 1
        I1 = flipud(I(:,:,1));
        I2 = flipud(I(:,:,2));
        I3 = flipud(I(:,:,3));
        I(:,:,1) = I1;
        I(:,:,2) = I2;
        I(:,:,3) = I3;
    end
 
    figure(1); clf; imshow(I); 
     saveroot = [slide,'_',gene, '_', embnum];
    title(texlabel(saveroot,'literal'));
    
   % save values 
   
   savepars_Callback(hObject, eventdata, handles); % save chosen values
      handles.I = I;
    handles.saveroot = saveroot; 
    handles.folder = folder;
    handles.slide = slide;
    handles.gene = gene;
    handles.embnum = embnum;
    handles.sna = handles.I(:,:,sna_chn);
    handles.nuc = handles.I(:,:,nuc_chn); 
    handles.flp = [flpH,flpV]; 
    
    handles.output = hObject; guidata(hObject, handles);
end

if handles.step==2 % find snail borders and chose transects
   % upload relevant analysis parameters    
        sT = str2double(get(handles.edit1,'String'));  % threshold for snail region detection
        sdil = str2double(get(handles.edit2,'String')); % dialate expression region
        sfill = str2double(get(handles.edit3,'String')); % imclose strel parameter for chosing expression region
        smin = str2double(get(handles.edit4,'String')); % min size for expression regions
        pts = str2double(get(handles.edit5,'String')); % number of points for transects          

    % select snail region process code (Step #) 
        sna_region = im2bw(handles.sna,sT); 
        sna_region = imdilate(sna_region,strel('disk',sdil)); % dilate chosen region
        sna_region = imclose(sna_region, strel('disk', sfill));
        
     
      sna_region = imerode(sna_region,strel('disk',2));  % erode rough edges
        
        sna_region = imfill(sna_region,'holes');
        sna_region = bwareaopen(sna_region,smin); 
           % trouble shooting problems
             figure(2); clf; subplot(2,1,1); imshow(handles.I);  hold on;
             title('thresholded snail region');
             subplot(2,1,2); imshow(sna_region); 
             title('chosen snail region');

    % get sna expression region boundaries
          L = bwlabel(sna_region);  % compute boundaries      
          a = bwboundaries(L);
          bndrys = fliplr(cell2mat(a));
          figure(2); subplot(2,1,1); hold on;
          %plot(bndrys(:,1),bndrys(:,2),'y');
          l = length(bndrys);
          bnd = bndrys(1:round(l/pts):end,:);
           scatter(bnd(1,1),bnd(1,2),'y*','sizedata',50); hold on;
           plot(bnd(:,1),bnd(:,2),'y.');

      
              handles.bnd = bnd;
              handles.output = hObject; guidata(hObject, handles); 
              
              load quantsna_v3_pars3;
              pars{4} = num2str(sT*255); save quantsna_v3_pars3 pars; 
              
end

if handles.step==3  % Transect snail boundaries
        tpts = str2double(get(handles.edit1,'String'));
        nts = str2double(get(handles.edit2,'String'));
        cl = str2double(get(handles.edit3,'String')); % max transect length transect
        lsna = str2double(get(handles.edit4,'String')); % min value called snail expression
        offset = str2double(get(handles.edit5,'String')); % pixels on either side of gradient to include in sna profile transect measurement  
        max_noise_size = str2double(get(handles.edit6,'String')); 
        bnd = handles.bnd;        
        
% chose boundary points from which to measure transects
        L2 = length(bnd);
        ind = [(1:L2)', bnd];   
        ind = sortrows(ind,3); % sort points by y-position
        t1 = min(ind(1:floor(tpts*L2) )); % chose top 30% of points 
       tops = bnd(t1:t1+floor(nts*L2),:); 
        % tops = bnd(t1:t1+floor(.4*pts),:); % left most of these and the next 40% of points declare as top points


%~~chose and draw transects based on expression region and chosen points~~%
    figure(2); clf;  imshow(handles.I); hold on;
    % initialize some new variables
         T = length(tops);
          bots = zeros(size(tops));
          lows = zeros(T,1);
          [ws,ls] = size(handles.sna);
          sna_grad = cell(1,T);
          sna_pro = zeros(T,500);
          coords = cell(1,T);
        % nuc_grad = {1:T};
        
   % Compute and Plot Transects in loop   
    for t=1:T
        
        % compute upper and lower bounds for transects
        lowb = min(tops(t,2)+cl,ws); % lower bound can't exceed size of sna data fill
        sna_grad{t} = handles.sna(tops(t,2)-offset:lowb,tops(t,1))';
        coords{t}= [tops(t,2)-offset:lowb,tops(t,1)]  ;
        
        
        lows(t) = min(find(sna_grad{t}>lsna,max_noise_size,'last'))-offset;  % find last 5 time snail gradient is stronger than 20
        bots(t,:) = [tops(t,1),tops(t,2)+lows(t)];
        
        % interpolate concentration in units of fractional transect length
            y = double(sna_grad{t});
            xx = linspace(1,length(y),500);
            x = 1:length(y);
            sna_pro(t,:) = spline(x, y, xx);
        
        
%         figure(2); hold on; % trouble shooting / progress plot
%         plot([tops(t,1),bots(t,1)],[tops(t,2),bots(t,2)],'c');
%         figure(5); clf; plot(sna_pro(t,:)); %pause(.1);
    end
    figure(2); % plot start points and endpoints
        line([tops(:,1),bots(:,1)]',[tops(:,2),bots(:,2)]','color','c');
    figure(2); hold on;
    plot(tops(:,1),tops(:,2),'co');
    plot(bots(:,1),bots(:,2),'yo');
% ~~~~~              end transect loop code                 ~~~~~~~~~~~~%    

    
figure(3); clf; 
plot(sna_pro(15:30,:)'); hold on;
plot(median(sna_pro(15:30,:)),'c','LineWidth',8 );
 set(gca,'FontSize',18); set(gcf,'color','w');    
    
    % export data
    handles.tops = tops;
    handles.bots = bots; 
    handles.sna_pro = sna_pro; 
    handles.sna_grad = sna_grad; 
    handles.sna_coords = coords; 
    handles.output = hObject; guidata(hObject, handles);  
end % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  




%===============================
            %%step 4
%===============================

if handles.step==4 % Get Nuclei centroids
  
    I = handles.nuc;    
    FiltSize = str2double(get(handles.edit1,'String'));  % 
    imblur = str2double(get(handles.edit2,'String'));
    sigmaE = str2double(get(handles.edit3,'String'));
    sigmaI = str2double(get(handles.edit4,'String'));
    minN = str2double(get(handles.edit5,'String'));   
    
    
  % get threshold image 'bw' and nuclei centroids 'cent'  
   % [handles.bw,handles.cent] = fxn_nuc_seg(I,FiltSize,FiltStr,sigmaE,sigmaI,PercP,minN); 
  %  [handles.bw,handles.cent] =fxn_nuc_seg(I,minN,FiltStr,sigmaE,sigmaI,AspectRatio,dilp);
   [handles.bw,handles.cent] = fxn_nuc_seg(I,minN,sigmaE,sigmaI,FiltSize,imblur);
end
    


%===============================
            %%step 5
%===============================

if handles.step==5
   
    Mthink = str2double(get(handles.edit1,'String'));  % 
    Mthin = str2double(get(handles.edit2,'String'));
    Imnn = str2double(get(handles.edit3,'String'));
    [handles.Nuc_map,handles.Nuc_overlay,handles.conn_map] = fxn_nuc_reg(handles.nuc,handles.bw,Mthink,Mthin,Imnn);  
     figure(3); clf; imagesc(handles.Nuc_map); 
end




%===============================
            %%step 6
%===============================
if handles.step==6
    % get user inputs
      min_neighbor_pix = str2double(get(handles.edit1,'String')); 
    
    
% load key parameters
        tops = handles.tops;   % coordinates of boundary points on top
        bots = handles.bots;   % " " " on bottom
        H = handles.Nuc_map;
        C = handles.conn_map; 
        [h,w] = size(H);
        T =length(tops);
        
         % must have at least min_neighbor_pix pixels along border to be considered a neighbor.
        C = sparse(C > min_neighbor_pix);
        
          I3 = uint8(zeros(h,w,3));
          I3(:,:,2) = handles.sna;
          I3(:,:,3) = handles.nuc; 
          figure(4); clf; imshow(I3);
          
             
                   
         cnt_nuc = zeros(T,1); 
    for t=1:T
        top = round(tops(t,2))+round(tops(t,1))*h;
        bot = round(bots(t,2))+round(bots(t,1))*h;
        top_nuc = H(top); bot_nuc = H(bot); 
        
        try
             [cnt_nuc(t),path,jnk] = graphshortestpath(C,top_nuc,bot_nuc,'Method','Dijkstra');   % 'BFS'    
             % [cnt_nuc(t),path,jnk] = my_graphshortestpath(C,top_nuc,bot_nuc,'Method','Dijkstra');   % 'BFS'    
               L = ismember(H,path);
        
        if rem(t,10)==0
        I3(:,:,1) = I3(:,:,1) + uint8(100*L); 
        figure(1); clf; imshow(I3); pause(.01); 
        end
        
        catch error
            disp(error.message);
        end
        
    end
     figure(5); clf; colordef white;  plot(cnt_nuc,'k.'); 
     set(gca,'FontSize',18); set(gcf,'color','w'); ylim([0,30]);
     
     
   %
handles.cnt_nuc = cnt_nuc; % nuclei transect counts for each position
handles.nTop = T; % number of top nuclei

end



if handles.step==7 % save and export data
  disp('saving data...'); 
    folder = get(handles.edit1,'string');
  savename = get(handles.edit2,'string');  
  h = figure(1);  nuc_tot = length(handles.cent); % total nuclei

  csvwrite([folder,'/',savename,'_data.txt'],[nuc_tot,handles.nTop,handles.cnt_nuc']);  % nuclei counts 
    saveas(h,[folder,'/',savename,'_anot.tif']); %save figure
  sna_grad = handles.sna_grad;  % the raw gradients 
  nuc_map = handles.Nuc_map; % Indexed map of nuclei
  tops = handles.tops; % position of upper boundary points
  bots = handles.bots; % position of lower boundary points
  norm_grads = handles.sna_pro; % length normalized intensities 
  nTop = handles.nTop;
  cnt_nuc = handles.cnt_nuc; 
  flp = handles.flp; 
  
  save([folder,'/',savename,'_data.mat'],'sna_grad','nuc_map','tops',...
      'bots','norm_grads','nuc_tot','cnt_nuc','flp'); 
        
   set(handles.steplabel,'String','Exporting Data, reset to step 1');
    handles.step = 1;   pause(1); % pause to read change
     load quantsna_v3_pars1; % pars
      emb = str2double(pars{3})+1;
      if emb < 10
          emb = ['0',num2str(emb)];
      else
          emb = num2str(emb); 
      end
          
      pars{3} = emb; 
      save quantsna_v3_pars1; % pars
    
    
    Setup_Steps(hObject, eventdata, handles); 
    disp('data saved'); 
end

guidata(hObject, handles);  % update GUI data after any step


% ============= SET UP STEP INPUT LABELS ================ %

function next_Callback(hObject, eventdata, handles)
    handles.step = handles.step + 1; 
    handles.output = hObject; guidata(hObject, handles);  
    Setup_Steps(hObject, eventdata, handles); 
    guidata(hObject, handles); 

function Back_Callback(hObject, eventdata, handles)
    handles.step = handles.step - 1; 
    Setup_Steps(hObject, eventdata, handles); 
    handles.output = hObject; guidata(hObject, handles);  

function Setup_Steps(hObject, eventdata, handles)
% disp('setup steps called'); 
if handles.step == 1; 
    
     load quantsna_v3_pars1; % pars = {'brkN','sim_sna','01','1','3','0','0'}; save quantsna_v3_pars1 pars 
    set(handles.steplabel,'String','Step 1: load image'); 
    set(handles.in1label,'String','slide');
    set(handles.in2label,'String','gene');
    set(handles.in3label,'String','emb num');
    set(handles.in4label,'String','Snail chn');
    set(handles.in5label,'String','Nuclei chn');
    set(handles.in6label,'String','Flip Horiz?');
    set(handles.in7label,'String','Flip Vert?');
 % reset default field entries  
    set(handles.edit1,'String',pars{1});
    set(handles.edit2,'String',pars{2});
    set(handles.edit3,'String',pars{3});
    set(handles.edit4,'String',pars{4});
    set(handles.edit5,'String',pars{5});
    set(handles.edit6,'String',pars{6});
    set(handles.edit7,'String',pars{7});
end

if handles.step == 2;
      load quantsna_v3_pars2; % pars = {'0.05','0','2','1000','200',' ',' '}; save quantsna_v3_pars2 pars 
    set(handles.steplabel,'String','Step 2: select snail expression region'); 
% reset field labels;
    set(handles.in1label,'String','Snail thresh.');
    set(handles.in2label,'String','Dilate region');
    set(handles.in3label,'String','region fill');
    set(handles.in4label,'String','min size');
    set(handles.in5label,'String','pts for boundary');
    set(handles.in6label,'String',' ');
    set(handles.in7label,'String',' ');
 % reset default field entries  
    set(handles.edit1,'String',pars{1});
    set(handles.edit2,'String',pars{2});
    set(handles.edit3,'String',pars{3});
    set(handles.edit4,'String',pars{4});
    set(handles.edit5,'String',pars{5});
    set(handles.edit6,'String',pars{6});
    set(handles.edit7,'String',pars{7});
end

if handles.step == 3;
    % disp('Step 3: Compute Snail Transects')
         load quantsna_v3_pars3; %    pars = {'.4','.35','350','20','50','5',' '}; save quantsna_v3_pars3 pars 
       set(handles.steplabel,'String','Step 3: Compute Snail Transects'); 
% reset field labels;
    set(handles.in1label,'String','top nuclei');
    set(handles.in2label,'String','frac top nucs');
    set(handles.in3label,'String','max transect');
    set(handles.in4label,'String','min snail');
    set(handles.in5label,'String','trans. buffer'); 
    set(handles.in6label,'String','max noise size');
    set(handles.in7label,'String','');
 % reset default field entries  
    set(handles.edit1,'String',pars{1});
    set(handles.edit2,'String',pars{2});
    set(handles.edit3,'String',pars{3});
    set(handles.edit4,'String',pars{4});
    set(handles.edit5,'String',pars{5});
    set(handles.edit6,'String',pars{6});
    set(handles.edit7,'String',pars{7});
end

if handles.step == 4;
      load quantsna_v3_pars4; % pars = {'15','.9','3','8','75','10',''};   save quantsna_v3_pars4 pars;
        set(handles.steplabel,'String','Step 4: Locate Nuclei');
        set(handles.in1label,'String','Filter Size'); % number of pixels in filter (linear dimension of a square)
        set(handles.edit1,'String', pars{1});
        set(handles.in2label,'String','imblur'); % width of Gaussian in pixels
        set(handles.edit2,'String',pars{2});
        set(handles.in3label,'String','Excitation Width');
        set(handles.edit3,'String',pars{3}); 
        set(handles.in4label,'String','Inhibition Width');
        set(handles.edit4,'String', pars{4});
        set(handles.in5label,'String','min Nuc size');
        set(handles.edit5,'String', pars{5});
        set(handles.in6label,'String','');
        set(handles.edit6,'String', pars{6});  
        set(handles.in7label,'String','');
        set(handles.edit7,'String',pars{7});
end



if handles.step == 5;
      load quantsna_v3_pars5;% pars = {'10','3','2','','','',''};  save quantsna_v3_pars5 pars;
       set(handles.steplabel,'String','Step 5: Map Nuclei regions');   
        set(handles.in1label,'String','thicken nuclei'); 
        set(handles.edit1,'String', pars{1});
        set(handles.in2label,'String','thin boundaries');
        set(handles.edit2,'String', pars{2});
        set(handles.in3label,'String','erode'); 
        set(handles.edit3,'String', pars{3});
        set(handles.in4label,'String',' ');
        set(handles.edit4,'String', pars{4}); 
        set(handles.in5label,'String',' ');
        set(handles.edit5,'String', pars{5}); 
        set(handles.in6label,'String',' ');
        set(handles.edit6,'String', pars{6});  
        set(handles.in7label,'String','');
        set(handles.edit7,'String',pars{7}); 
end
if handles.step == 6; 
      load quantsna_v3_pars6; % pars = {'3',' ',' ','',' ',' ',' '}; save quantsna_v3_pars6 pars 
      set(handles.steplabel,'String','Step 6: Measure width of sna expression');
% reset field labels;
    set(handles.in1label,'String','Min neighbor pix');
    set(handles.in2label,'String',' ');
    set(handles.in3label,'String','');
    set(handles.in4label,'String','');
    set(handles.in5label,'String','');
    set(handles.in6label,'String','');
    set(handles.in7label,'String','');
 % reset default field entries  
    set(handles.edit1,'String',pars{1});
    set(handles.edit2,'String',pars{2});
    set(handles.edit3,'String',pars{3});
    set(handles.edit4,'String',pars{4});
    set(handles.edit5,'String',pars{5});
    set(handles.edit6,'String',pars{6});
    set(handles.edit7,'String',pars{7});
end

if handles.step == 7;
      load quantsna_v3_pars7; % pars = {'/Volumes/Data/Lab Data/SnaSwitch_data/snail_quant','brkN_sim_sna_01',' ','',' ',' ',' '}; save quantsna_v3_pars7 pars 
    set(handles.steplabel,'String', 'Step 7: Export Data');
    % reset field labels;
    set(handles.in1label,'String','save folder');
    set(handles.in2label,'String','save name');
    set(handles.in3label,'String','');
    set(handles.in4label,'String','');
    set(handles.in5label,'String','');
    set(handles.in6label,'String','');
    set(handles.in7label,'String','');
 % reset default field entries  
    set(handles.edit1,'String',pars{1});
    set(handles.edit2,'String',['v2_',handles.saveroot]);
    set(handles.edit3,'String',pars{3});
    set(handles.edit4,'String',pars{4});
    set(handles.edit5,'String',pars{5});
    set(handles.edit6,'String',pars{6});
    set(handles.edit7,'String',pars{7});
end
    guidata(hObject, handles); 


function edit1_Callback(hObject, eventdata, handles)

function edit2_Callback(hObject, eventdata, handles)

function edit3_Callback(hObject, eventdata, handles)

function edit4_Callback(hObject, eventdata, handles)

function edit5_Callback(hObject, eventdata, handles)

function edit6_Callback(hObject, eventdata, handles)

function edit7_Callback(hObject, eventdata, handles)

function folderfield_Callback(hObject, eventdata, handles)




% --- Executes on button press in savepars.
function savepars_Callback(hObject, eventdata, handles)
   % record the values of the 6 input boxes for the step now showing
     p1 = (get(handles.edit1,'String'));  
     p2 = (get(handles.edit2,'String'));  
     p3 = (get(handles.edit3,'String'));  
     p4 = (get(handles.edit4,'String'));  
     p5 = (get(handles.edit5,'String'));  
     p6 = (get(handles.edit6,'String'));  
     p7 = (get(handles.edit7,'String'));
     pars = {p1, p2, p3, p4, p5, p6, p7}; % cell array of strings
  % Export parameters 
     stp_label = num2str(handles.step) ; 
     savelabel = ['quantsna_v3_pars',stp_label]  ;
     % labeled as nucdot_parsi.mat where "i" is the step number 
     save(savelabel, 'pars');     



% draw fields
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function edit7_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end
function folderfield_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white'); end


