function [sys,x0,str,ts] = envgui(t,x,u,flag,NoiseBlock,LoadDistBlock)
%ENVGUI S-function for making a simple PID GUI.
%
%   When the model autotunerPID.mdl is run, this S-function create a panel
%   designed as a console from which controlling the simulation
%   environment.  For example a measurement noise or a step on the load
%   disturbance can be included. 
%   The most interesting part of this interface is the one termed
%   ``Comparative Analysis'' which include analysis tools for both time and
%   frequency domain.  
%   The time domain analysis perform a comparison of the responses to a
%   step on the set-point and on the load disturbance for a PID tuned with
%   all the available methods.
%   The frequency domain analysis reports the open loop Bode diagram of the
%   control system together with the Bode diagram of the complementary
%   sensitivity and the sensitivity function. 
%
%   Everything started looking at PENDAN, an S-function for making pendulum
%   animation
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

% Plots every major integration step, but has no states of its own
switch flag,
   
   % Initialization 
   case 0,
      [sys,x0,str,ts] = mdlInitializeSizes(NoiseBlock,LoadDistBlock);
      % Update 
   case 2,
      sys = mdlUpdate(t,x,u);
      % Unused flags
   case { 1, 3, 4, 9 },
      sys = [];
      % DeleteBlock
   case 'DeleteBlock',
      LocalDeleteBlock
      % DeleteFigure
   case 'DeleteFigure',
      LocalDeleteFigure
      % Close
   case 'Close',
      LocalClose
      % Noise
   case 'Noise',
      LocalNoise
      % NoiseParam
   case 'NoiseParam',
      LocalNoiseParam
      % Dist
   case 'Dist',
      LocalDist
      % DistParam
   case 'DistParam',
      LocalDistParam
      % StepPID
   case 'StepPID',
      LocalStepPID
      % BodePID
   case 'BodePID',
      LocalBodePID
      % Help
   case 'Hlp',
      LocalHlp
      % Unexpected flags
   otherwise
      error(['Unhandled flag = ',num2str(flag)]);
end
% end envgui

%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
function [sys,x0,str,ts] = mdlInitializeSizes(NoiseBlock,LoadDistBlock)
% initialize parameters (setpoint)
set_param(get_param([get_param(gcs,'Parent') '/' NoiseBlock],'Handle'),...
   'Variance','0');
set_param(get_param([get_param(gcs,'Parent') '/' LoadDistBlock],'Handle'),...
   'Value','0');

% set up S-function
sizes = simsizes;

sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 0;
sizes.NumInputs      = 0;
sizes.DirFeedthrough = 0;
sizes.NumSampleTimes = 1;

sys = simsizes(sizes);

x0  = [];
str = [];
ts  = [0.1 0];

LocalEnvInit(NoiseBlock,LoadDistBlock);
% end mdlInitializeSizes


%=============================================================================
% mdlUpdate
% Update the Environment Control GUI animation.
%=============================================================================
function sys = mdlUpdate(t,x,u)
fig = get_param(gcbh,'UserData');
if ishandle(fig),
   if strcmp(get(fig,'Visible'),'on'),
      ud = get(fig,'UserData');
      LocalEnvSets(t,ud,u);
   end
end
sys = [];
% end mdlUpdate


%=============================================================================
% LocalDeleteBlock
% The animation block is being deleted, delete the associated figure.
%=============================================================================
function LocalDeleteBlock
fig = get_param(gcbh,'UserData');
if ishandle(fig),
   delete(fig);
   set_param(gcbh,'UserData',-1)
end
% end LocalDeleteBlock


%=============================================================================
% LocalClose
% The callback function for the animation window close button.  Delete
% the animation figure window.
%=============================================================================
function LocalClose
delete(gcbf)
% end LocalClose


%=============================================================================
% LocalDeleteFigure
% The animation figure is being deleted, set the S-function UserData to -1.
%=============================================================================
function LocalDeleteFigure
ud = get(gcbf,'UserData');
set_param(ud.Block,'UserData',-1);
% end LocalDeleteFigure


%=============================================================================
% LocalNoise
% The callback function for the activation/deactivation of the measurement
% noise
%=============================================================================
function LocalNoise
ud = get(gcbf,'UserData');
if get(ud.Noise,'Value')
   set_param(ud.NoiseBlock,'Variance',get(ud.NoiseVar,'String'));
else
   set_param(ud.NoiseBlock,'Variance',num2str(0));
end
% end LocalNoise


%=============================================================================
% LocalNoiseParam
% The callback function for setting of noise variance
%=============================================================================
function LocalNoiseParam
ud = get(gcbf,'UserData');
if get(ud.Noise,'Value')
   set_param(ud.NoiseBlock,'Variance',get(ud.NoiseVar,'String'));
end
% end LocalNoiseParam


%=============================================================================
% LocalDist
% The callback function for the activation/deactivation of load disturbance
%=============================================================================
function LocalDist
ud = get(gcbf,'UserData');
if get(ud.LoadDist,'Value')
   set_param(ud.LoadDistBlock,'Value',get(ud.LoadAmp,'String'));
else
   set_param(ud.LoadDistBlock,'Value',num2str(0));
end
% end LocalDist


%=============================================================================
% LocalDistParam
% The callback function for setting the load diturbance amplitude
%=============================================================================
function LocalDistParam
ud = get(gcbf,'UserData');
if get(ud.LoadDist,'Value')
   set_param(ud.LoadDistBlock,'Value',get(ud.LoadAmp,'String'));
end
% end LocalDistParam


%=============================================================================
% LocalStepPID
% The callback function for comparing step response with different
% autotuning method
%=============================================================================
function LocalStepPID
global MODELRUNNING
if ~MODELRUNNING
   try
      num = str2num(get_param('autotunerPID/Plant/Transfer Fcn','Numerator'));
      den = str2num(get_param('autotunerPID/Plant/Transfer Fcn','Denominator'));
      tau = str2num(get_param('autotunerPID/Plant/Transport Delay','DelayTime'));
   catch
      msgbox('The step response can be computed only for linear models',...
         'AutotunerPID','error');
      return
   end
   stepPIDcompare(num,den,tau);
else
   msgbox('The simulation must be STOPPED to perform the Comparative Analysis',...
         'AutotunerPID','warn');
end
% end LocalStepPID


%=============================================================================
% LocalBodePID
% The callback function for comparing Bode diagram with different
% autotuning method
%=============================================================================
function LocalBodePID
global MODELRUNNING
if ~MODELRUNNING
   try
      num = str2num(get_param('autotunerPID/Plant/Transfer Fcn','Numerator'));
      den = str2num(get_param('autotunerPID/Plant/Transfer Fcn','Denominator'));
      tau = str2num(get_param('autotunerPID/Plant/Transport Delay','DelayTime'));
   catch
      msgbox('The Bode diagrams can be computed only for linear models',...
         'AutotunerPID','error');
      return
   end
   bodePIDcompare(num,den,tau);
else
   msgbox('The simulation must be STOPPED to perform the Comparative Analysis',...
         'AutotunerPID','warn');
end

% end LocalBodePID


%=============================================================================
% LocalHlp
% The callback function for Help
%=============================================================================
function LocalHlp
web([strrep(which('envgui'),'envgui.m','') 'help/index_doc.html'],'-browser')
% end LocalHlp


%=============================================================================
% LocalEnvSets
% Local function to set the position of the graphics objects in the Env GUI
% animation window.
%=============================================================================
function LocalEnvSets(time,ud,u)
global AUTOTUNE
global ENVINACTIVE

if AUTOTUNE
   set(ud.Noise,'Enable','off');
   set(ud.NoiseVar,'Enable','off');
   set(ud.LoadDist,'Enable','off');
   set(ud.LoadAmp,'Enable','off');
   ENVINACTIVE = 1;
elseif ~AUTOTUNE & ENVINACTIVE
   % Autotuning process completed (update parameters and set the GUI
   % active)
   set(ud.Noise,'Enable','on');
   set(ud.NoiseVar,'Enable','on');
   set(ud.LoadDist,'Enable','on');
   set(ud.LoadAmp,'Enable','on');
   ENVINACTIVE = 0;
end

% Force plot to be drawn
pause(0), drawnow
% end LocalEnvSets


%=============================================================================
% LocalEnvInit
% Local function to initialize the Env GUI animation.  If the animation
% window already exists, it is brought to the front.  Otherwise, a new
% figure window is created.
%=============================================================================
function LocalEnvInit(NoiseBlock,LoadDistBlock)
% The name of the reference is derived from the name of the
% subsystem block that owns the GUI S-function block.
% This subsystem is the current system and is assumed to be the same
% layer at which the reference block resides.
sys = get_param(gcs,'Parent');

global AUTOTUNE
global AUTOMAN
global INACTIVE


% The animation figure handle is stored in the GUI block's UserData.
% If it exists, initialize all the fields
Fig = get_param(gcbh,'UserData');
if ishandle(Fig),
   FigUD = get(Fig,'UserData');
   
   set(FigUD.Noise,...
      'Value',0,...
      'Enable','on');
   set(FigUD.NoiseVar,...
      'String','0.0001',...
      'Enable','on');
   set(FigUD.LoadDist,...
      'Value',0,...
      'Enable','on');
   set(FigUD.LoadAmp,...
      'String','1',...
      'Enable','on');
   
   % bring it to the front
   figure(Fig);
   return
end

% the animation figure doesn't exist, create a new one and store its
% handle in the animation block's UserData
FigureName = 'Environment Panel';

% Figure
FigH = 150;                % figure height
FigW = 272;                % figure width
Fig = figure(...
   'Units',              'pixel',...
   'Position',           [100 300-FigH FigW FigH],...
   'Name',               FigureName,...
   'NumberTitle',        'off',...
   'IntegerHandle',      'off',...
   'HandleVisibility',   'callback',...
   'MenuBar',            'none',...
   'Resize',				 'off',...
   'DoubleBuffer',       'on',...
   'DeleteFcn',          'envgui([],[],[],''DeleteFigure'')',...
   'CloseRequestFcn',    'envgui([],[],[],''Close'');');

% operating condition
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [12 FigH-19 140 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             'Operating Conditions');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'frame',...
   'Units',              'pixel',...
   'Position',           [12 FigH-64 248 44]);
Noise = uicontrol(...
   'Parent',             Fig,...
   'Style',              'checkbox',...
   'Position',           [16 FigH-42 140 18],...
   'String',             'Measurement noise',...
   'Fontweight',         'bold',...
   'Value',              0,...
   'Callback',           'envgui([],[],[],''Noise'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [156 FigH-40 40 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'var. ');
NoiseVar = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [196 FigH-42 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '0.0001',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'envgui([],[],[],''NoiseParam'');');
LoadDist = uicontrol(...
   'Parent',             Fig,...
   'Style',              'checkbox',...
   'Position',           [16 FigH-62 150 18],...
   'String',             'Load disturbance',...
   'Fontweight',         'bold',...
   'Value',              0,...
   'Callback',           'envgui([],[],[],''Dist'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [166 FigH-60 30 14], ...
   'HorizontalAlignment','right',...
   'Fontweight',         'bold',...
   'String',             'amp. ');
LoadAmp = uicontrol(...
   'Parent',             Fig,...
   'Style',              'edit',...
   'Units',              'pixel',...
   'Position',           [196 FigH-60 60 18], ...
   'HorizontalAlignment','center',...
   'String',             '1',...
   'Backgroundcolor',    [1 1 1],...
   'Callback',           'envgui([],[],[],''DistParam'');');

% compact analysis
uicontrol(...
   'Parent',             Fig,...
   'Style',              'text',...
   'Units',              'pixel',...
   'Position',           [12 FigH-88 240 14], ...
   'HorizontalAlignment','left',...
   'Fontweight',         'bold',...
   'FontSize',           8,...
   'Backgroundcolor',    [0.8 0.8 0.8],...
   'String',             'Comparative Analysis');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'frame',...
   'Units',              'pixel',...
   'Position',           [12 FigH-118 248 28]);
uicontrol(...
   'Parent',             Fig,...
   'Style',              'pushbutton',...
   'Position',           [22 FigH-114 72 20],...
   'String',             'Time', ...
   'Fontweight',         'bold',...
   'Callback',           'envgui([],[],[],''StepPID'');');
uicontrol(...
   'Parent',             Fig,...
   'Style',              'pushbutton',...
   'Position',           [176 FigH-114 72 20],...
   'String',             'Frequency', ...
   'Fontweight',         'bold',...
   'Callback',           'envgui([],[],[],''BodePID'');');
% help button
uicontrol(...
   'Parent',             Fig,...
   'Style',              'pushbutton',...
   'Position',           [100 FigH-145 72 20],...
   'String',             'Help', ...
   'Fontweight',         'bold',...
   'Callback',           'envgui([],[],[],''Hlp'');');


% all the HG objects are created, store them into the Figure's UserData

% operating conditions
FigUD.Noise        = Noise;
FigUD.NoiseVar     = NoiseVar;
FigUD.LoadDist     = LoadDist;
FigUD.LoadAmp      = LoadAmp;
% Simulink Block Interaction
FigUD.Block        = get_param(gcbh,'Handle');
FigUD.NoiseBlock   = get_param([sys '/' NoiseBlock],'Handle');
FigUD.LoadDistBlock= get_param([sys '/' LoadDistBlock],'Handle');

set(Fig,'UserData',FigUD);

drawnow

% store the figure handle in the animation block's UserData
set_param(gcbh,'UserData',Fig);
% end LocalEnvInit