function [sys,x0,str,ts] = pid_isatd(t,x,u,flag,Ts,umin,umax,As,hystLevel)
%PID_ISATD Discrete time ISA-PID (implemented as an S-function).
%
%   The PID closely resemble the structure of a real industrial PID and has
%   the following features: 
%     - filter on the derivative action
%     - set-point weight (but not the weight of the derivative action which
%       is fixed to 0)
%     - antiwindup on lower and higher saturation limits of the actuator
%     - bumpless auto-manual switch
%
%   It also implements the logic to perform the identification experiment:
%     - step response identification (with user-defined step amplitude)
%     - relay identification (with user-defined relay amplitude and
%       hysteresis level)
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

persistent stato;           % internal state variable

CVBlock = 'ManValue';
switch flag,
    case 0,
        [sys,x0,str,ts,stato] = mdlInitializeSizes(Ts);
    case 3,
        [sys,stato] = mdlOutputs(t,x,u,stato,Ts,umin,umax,As,hystLevel);
    case { 1, 2, 4, 9 }
        sys=[];
    otherwise
        error(['Unhandled flag = ', num2str(flag)]);
end
% end pid_isatd


%=============================================================================
% mdlInitializeSizes
% Return the sizes, initial conditions, and sample times for the S-function.
%=============================================================================
function [sys,x0,str,ts,stato] = mdlInitializeSizes(Ts)
% set up S-function
sizes = simsizes;

sizes.NumContStates  = 0;
sizes.NumDiscStates  = 0;
sizes.NumOutputs     = 1;
sizes.NumInputs      = 4;
sizes.DirFeedthrough = 1;
sizes.NumSampleTimes = 1;   % at least one sample time is needed

sys = simsizes(sizes);

x0  = [];
str = [];
ts  = [Ts 0];
stato = [0 0 0 0 0];
% end mdlInitializeSizes

%=============================================================================
% mdlOutputs
% Return the block outputs.
%=============================================================================
function [sys,stato] = mdlOutputs(t,x,u,stato,Ts,umin,umax,As,hystLevel)
global CVVALUE                  % control variable (used for M/A commutation)
global IDENTIFICATION_METHOD
global TUNING_METHOD
global PIDPARAMETERS

% measured signals
sp = u(1);                      % setpoint value
pv = u(2);                      % process value

% control signals
auto     = u(3);                % auto/man switch (MANUAL=0; AUTO=1)
autotune = u(4);                % true when autotuning

% PID parameters (c=0)
K  = PIDPARAMETERS(1);
Ti = PIDPARAMETERS(2);
Td = PIDPARAMETERS(3);
N  = PIDPARAMETERS(4);
b  = PIDPARAMETERS(5);

% translation of the vector stato (for simplicity)
% state variable
ui    = stato(1);               % integral action
ud    = stato(2);               % derivative action (filter)

% auxiliary variable
pvold = stato(3);               % old process value
cvold = stato(4);               % old control variable
atold = stato(5);               % old autotune state (to ensure bumpless switch)

% PID algorithm
% compute the constants (made each time since PID parameters may change)
if Ti
    a1 = K*Ts/Ti;
else
    % when Ti = 0 turn off the integral action
    a1 = 0;
end
b1 = Td/(Td + N*Ts);
b2 = K*Td*N/(Td + N*Ts);

% compute control actions
up = K*(b*sp - pv);

ud = b1*ud - b2*(pv-pvold);

if ~autotune & atold
    % ensure bumpless switch after a change in the regulator parameters
    ui = cvold - up - ud;
end

if autotune
    if strcmp(IDENTIFICATION_METHOD,'STEP')
        % increment the value of the control variable
        cv = CVVALUE+As;
    elseif strcmp(IDENTIFICATION_METHOD,'RELAY')
        if ~atold
            cv = CVVALUE+As;
        else
            if pv >= sp+hystLevel
                cv = CVVALUE-As;
            elseif pv <= sp-hystLevel
                cv = CVVALUE+As;
            else
                cv = cvold;
            end
        end
    end
else
    if ~auto
        % manual mode
        cv = CVVALUE;
    else
        % automatic regulation
        cv = up + ui + ud;
    end
    
    if cv > umax
        % saturation on maximum value (note that the state of the integrator is
        % not updated)
        cv = umax;
    elseif cv < umin
        % saturation on minimum value
        cv = umin;
    else
        % update the state of the integrator
        if auto
            ui = ui + a1*(sp-pv);
        else
            ui = cv - up - ud;
        end
    end
    % update control variable value
    CVVALUE = cv;
end

% update internal state vector
stato = [ui ud pv cv autotune];
% generate control variable
sys = cv;
% end mdlOutputs