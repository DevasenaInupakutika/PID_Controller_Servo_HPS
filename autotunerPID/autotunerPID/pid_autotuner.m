function [sys,x0,str,ts] = pid_autotuner(t,x,u,flag,Ts,As)
%PID_AUTOTUNER Supervisor of a PID autotuner (implemented as an S-function).
%
%   The supervisor, rules out the autotuning process mainly performing the
%   identification of a process model and the synthesis of the new
%   parameters with various methods. 
%   Moreover it is possible to constrain the structure of the regulator to
%   be a PI or a PID, or the structure can be automatically selected by the
%   supervisor.
%   In particular, the autotuner has the following feature:
%      - identification of process description:
%         * a FOPDT model through the areas method
%         * one point of the frequency response through the method of the
%           relay 
%      - sythesis of the PID parameters using
%         * KT method
%         * IMC method
%         * First and second ZN method
%      - it's still a work in progress!! ;-)
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

switch flag,
   % Initialization
   case 0,
      [sys,x0,str,ts] = mdlInitializeSizes(Ts);
      % Outputs
   case 3,
      [sys] = mdlOutputs(t,x,u,Ts,As);
      % Unused flags
   case { 1, 2, 4, 9 }
      sys = [];
   otherwise
      error(['Unhandled flag = ',num2str(flag)]);        
end
% end pid_superv


%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
function [sys,x0,str,ts] = mdlInitializeSizes(Ts)
global Y_AUTOTUNING     % store the step (or relay) response used for tuning

Y_AUTOTUNING = [];      % initialized to an empty vector

% set up S-function
sizes = simsizes;

sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 2;
sizes.NumInputs      = 1;
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;   % at least one sample time is needed

sys = simsizes(sizes);

x0  = [];
str = [];
ts  = [Ts 0];
% end mdlInitializeSizes


%=============================================================================
% mdlOutputs
% Return the block outputs.
%=============================================================================
function [sys] = mdlOutputs(t,x,u,Ts,As)
% sys(1)    :    auto/manual switch
% sys(2)    :    autotuning (0 : autotuning in progress; 1 : normal operation)

% u(1)      :    new sample of the step response

global PIDPARAMETERS
global IDENTIFICATION_METHOD
global TUNING_STRUCTURE
global TUNING_METHOD
global TUNING_PARAM
global AUTOTUNE
global AUTOMAN

global Y_AUTOTUNING

step_steadyThr  = 0.05;    % threshold on derivative to consider the
                           % step response to a stedy state
relay_steadyThr = 0.05;    % threshold on peaks percentual difference to
                           % consider the relay response to steady state

if AUTOTUNE
   % store the new sample of the step response
   Y_AUTOTUNING = [Y_AUTOTUNING; u(1)];
   y = Y_AUTOTUNING;
   
   if strcmp(IDENTIFICATION_METHOD,'STEP')
      % check if the step response has reached a steady state (i. e. check if
      % the last 10% of the step response is ``flat'' enough)
      N  = fix(length(y)/10);   % last 10% of the step response
      if N > 15
         % the step response must be made at least by 150 samples
         deltay = abs(y(end)-y(1));
         yw = y(end-N:end);
         % mean value of the derivative in the window lower than a fraction
         % of the maximum value of the derivative
         idok = (max(yw)-min(yw)) < step_steadyThr*(max(y)-min(y));
      else
         idok = 0;
      end
      if idok
         model = idareas(y,1,Ts);
      end
   elseif strcmp(IDENTIFICATION_METHOD,'RELAY')
      % IDENTIFICATION WITH THE RELAY METHOD
      dy = diff(y);
      ind = find(dy(1:end-1)>0 & dy(2:end)<0);
      
      % at least 4 oscillations but no more than 10 oscillations
      if length(ind)>=4 & length(ind)<10
         ym = mean(y);
         % mean value of the difference between the last three peaks is
         % less than a fraction of the overall range of the response
         idok = mean(abs(diff(y(ind(end-2:end))))) < relay_steadyThr*(max(y)-min(y));
         % the last ``period'' must cross the zero
         idok = idok & any(abs(y(ind(end-1):ind(end))-ym) < relay_steadyThr/2*abs(max(y)-ym));
      elseif length(ind)>=10
         % force the stop of the relay identification
         idok = 1;
      else
         idok = 0;
      end
      
      if idok
         model.A = max(y)-min(y);
         model.T = Ts*(ind(end)-ind(end-1));
      end    
   end
   
   % autotuning required
   if idok        
      % selection of the regulator structure
      regStruct = pid_structure(model,TUNING_STRUCTURE);
      
      % synthesis of the PID parameters
      try
         [K,Ti,Td,N,b] = pid_tuning(model,TUNING_METHOD,TUNING_PARAM,regStruct,As);
         % update PID parameters
         PIDPARAMETERS = [K Ti Td N b];
      catch
         % no change in the parameters
      end
      
      AUTOTUNE = 0;
   end
   % put the PID in manual mode during autotuning and propagate the
   % ``autotuning running'' signal
   sys = [AUTOMAN 1];   
else
   % empty the step response vector
   Y_AUTOTUNING = [];
   % put the PID in auto mode during autotuning and propagate the
   % ``autotuning not running'' signal
   sys = [AUTOMAN 0];
end
% end mdlOutputs