%%                              CheckDotUpDown
% Alistair Boettiger                                   Date Begun: 01/30/11
% Levine Lab                                        Last Modified: 02/06/11


%% Description
% Stitch multi-stack data together to find 3D positions of all dots. 
% avoids multiple dot counting and avoids fusion of dots in Z.


function NewDotC = CheckDotUpDown(DotData,DotMasks,Im,mRNAchn,h,w,plotdata)
%% Updates
% Rewritten 03/07/11 to convert more things to uint16 / uint8 to save
% memory (even fragment of single stack is several gigs of active mem). 
%  
%

%% Approach 3: 
% use 'ovlap'-size pixel masks instead of min distance for speed
% use linear indexing of all dots
tic 
disp('connecting dots in Z...') 
%plotdata = 1; 
% h = hs; w = ws;




% create list of 3d corrdinates of all dots.  Also assigns all dots a
% unique linear index.
Zs = length(DotData);
dotsinlayer = zeros(1,Zs);
dotC = [];
for z = 1:Zs
    dotsinlayer(z) = size(DotData{z},1);
    dotC = [dotC; DotData{z}, z*ones(dotsinlayer(z),1)];
end


maxdots = max(dotsinlayer) +100
totaldots = length(dotC)

        % Rather memory inefficient, I have the same centroid data stored
        % in 2 different data structures.  Could build this guy to start
        % with.  


NDots = length(dotC); % total number of dots;
DotConn = single(zeros(2*NDots,Zs)); % empty connectivity matrix for all dots;  as a uint16 restricts this to 65,536 dots per image.  
ConnInt = single(zeros(2*NDots,Zs)); 
LayerJoin = false(2*NDots,Zs); 
% Only enter data in every other line. This leaves black space to allow
% for image segmentation routines to be used that will treat each dot as
% separate.  

for Z = 1:Zs % The primary layer
         % convert to pixel linear-index
         inds1 = floor(DotData{Z}(:,2))+floor(DotData{Z}(:,1))*h;  % indices in this layer  
         inds1(inds1>w*h) = w*h;  
         R1 = uint16(zeros(h,w));   
         R1(inds1) = maxdots; % convert indices to raster map               
         st1_dot_num = sum(dotsinlayer(1:Z-1)); % starting dot number for the layer under study     
        
         
    for z=1:Zs % compare primary layer to all other layers    
         Loz = R1 + DotMasks{z};  % detect overlap with indices   
        % figure(3); clf; imagesc(Loz); 
        % figure(3); clf; imagesc(DotMasks{z}); 
         Loz(Loz<maxdots+1) = 0; % remove non-overlapping dots;
         Loz = Loz - maxdots; % LoZ is already positive, so we don't need to worry about negative values.  
        % Loz(Loz<0) = 0;
              % figure(3); clf; imagesc(Loz);   
         
      % Need to get linear index to stick correctly in array of all dots.  
         stz_dot_num = sum(dotsinlayer(1:z-1));  % starting dot number for the comparison layer     
         inds_zin1 = Loz(inds1); % indices of layer z overlapping layer 1.
         indsT = inds_zin1 + stz_dot_num; % convert layer indices to total overall dot indices 
         indsT(indsT == stz_dot_num) = 0; % makes sure missing indices are still 'missing' and not last of previous layer.   
         DotConn(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) =  single(indsT); % STORE in DotConn matrix the indices 
         
         % The single pixel version
        % Iw % ( xp1:xp2,yp1:yp2 );  % Alldots(:,:,z); %
         Ivals = Im{1,z}{mRNAchn}(inds1);  % also store the actual intenisites  
         ConnInt(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) = single(Ivals);   
         % figure(3); clf; imagesc(DotConn); shading flat;
    end
    LayerJoin( 2*st1_dot_num+1 :2*(st1_dot_num + dotsinlayer(Z)),Z) = true(2*dotsinlayer(Z),1); 
    
end

clear Im Ivals LoZ R1 DotMasks DotData;

toc
%%
tic
disp('counting total dots...');
% figure(3); clf; imagesc(LayerJoin); 
% figure(3); clf; imagesc(DotConn); colormap hot; shading flat;
% figure(3); clf; imagesc(ConnInt); colormap hot; shading flat;  
 
% 
 ConnInt_T = ConnInt.*(DotConn>0);
%ConnInt_T(ConnInt_T <.02*2^16)=0;
 MD = LayerJoin+ConnInt_T; % figure(4); clf; imagesc(MD);
 MD = MD>0;  MD = bwareaopen(MD,20); % mask of major axis 
 ConnInt_T = ConnInt_T.*MD;
 

 clear MD ConnInt LayerJoin; % need to protect memory space
 
% Watershed to split dots
mask = ConnInt_T>0;
W = ConnInt_T.*mask;
W = watershed(max(W(:)) - W); 
% figure(3); clf; imagesc(W); colormap lines;
mask(W==0) = 0; 
%figure(2); clf; imagesc(mask);

labeled = bwlabel(mask);
R = regionprops(labeled,'Centroid');
cent = reshape([R.Centroid],2,length(R))'; clear R; 

if plotdata == 1;
    figure(4); clf; 
    colordef black; set(gcf,'color','k'); 
    imagesc( ConnInt_T ); colormap hot; shading flat;  colorbar;
    ylabel('mRNA index'); xlabel('z-depth'); 
    hold on; plot(cent(:,1),cent(:,2),'co'); 
    title('Cross-Section of all dots'); 
end
mask = bwareaopen(mask,2);


clear W ConnInt_T 

%%

masked_inds = mask.*DotConn;

clear DotConn;

remove_dot = zeros(NDots,1); 
stacked_dots =0;
% loop through all dots

for i = 1:2:2*NDots % i = 605 i = 5401; i=5693 i = 5547  i = 6549
    j = find(masked_inds(i,:));
    counted = masked_inds(i,j(2:end));   
    if isempty(j) == 0
        stacked_dots = max(j)-min(j) > length(j)-1;
    
        if stacked_dots == 0
             ii = find(cent(:,2)==i);
             dotC((i+1)/2,3) = cent(ii(1),1);
        end
    else
        remove_dot((i+1)/2) = 1;
    end
    if stacked_dots == 1% if stacked dots split up.  
        brk_pts =[0, find(diff(j)>1),length(j),length(j)]; % breakpoints in stack 
        possibles = masked_inds(i,j); % all possible multicounted indices 
        ii = find(possibles == (i+1)/2) ; % find this breakpoint    
        % only need this if low intensity points have been removed
        if isempty(ii); [jnk, ii] = min( ((i+1)/2 - possibles).^2 );  end
       % find nearest breakpoint without going over
          kk = (ii-brk_pts); kk(kk<0) = 100; [jnk,bi] = min(kk);    
          counted = possibles(brk_pts(bi)+2:brk_pts(bi+1));  
    %     try 
          ii = find(cent(:,2)==i);
          dotC((i+1)/2,3) = cent(ii( min(bi,length(ii)) ),1);
%          catch err
%              disp(i)
%          end
    stacked_dots =0;      
    end
    remove_dot(counted) = 1;     
end
toc
sum(remove_dot);
% sum(stacked_dots)
          % NB can't sum stacked dots, all stack dots are also multiply
          % counted.  i.e. the first time a doublet is enountered we say
          % Tstacked = Tstacked + 1, and then we enounter that the other of
          % the pair and again say Tstacked = Tstacked + 1;  

dotC = dotC(~remove_dot,:);
%N_dots = NDots - sum(remove_dot) % sum(stacked_dots)
N_dots = length(dotC); 
disp(['Counted ',num2str(N_dots),' spheres']); 

