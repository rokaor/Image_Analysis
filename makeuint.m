

% Convert to uint

% I is the input image
% n is either 8 for uint8 or 16 for uint16; 
% Io is the output image in the requested format

function Io = makeuint(I,n)

 I = I - min(I(:));
 I = I/max(I(:)); 
 Io = eval(['uint',num2str(n),'(2^n*I)']); 
 

