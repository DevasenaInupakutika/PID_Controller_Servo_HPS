function stepPIDcompare(num,den,tau)
%STEPPIDCOMPARE Comparison of step response on setpoint and load
%   disturbance with different autotuning methods.
%   
%   The function is typically called through the GUI in AutotunerPID.mdl
%   and provides a graphical comparison of four different autotuning
%   methods (STEP/ZN(OL), STEP/KT, STEP/IMC, RELAY/ZN(CL)) in time domain.
%   The response to a step on the setpoint at time t = 0 and the response
%   to a step at 2/3 of the final time are simulated.
%   By default the parameter Ms is set to 2 in KT methods, while the
%   parameter lambda is set 1/5 of the settling time of the plant.
%   
%   STEPPIDCOMPARE(NUM,DEN,TAU) performs the comparative analysis directly
%   considering the plant described by the transfer function
%              NUM(s)
%      P(s) = -------- * exp(-TAU*s)
%              DEN(s)
%
%   See also BODEPID

%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

global PIDPARAMETERS

% compute step response
P = tf(num,den,'IODelay',tau);
[y,t] = step(P);
Ts = min(real(abs(pole(P))))/50;
[y,t] = step(P,0:Ts:t(end));
Tf = t(end);

% identify a FOPDT model
modelFOPDT = idareas(y,1,Ts);

% identify the point of the frequency response with omega_n = -pi
[Gm,Pm,Wcg,Wcp] = margin(P);
modelPI.A = 2/Gm;
modelPI.T = 2*pi/Wcg;

% Set up the simulation environment
load_system('steppidsupport')
simhandle = 'steppidsupport';
set_param([simhandle '/Plant'],'Numerator',['[' num2str(num) ']']);
set_param([simhandle '/Plant'],'Denominator',['[' num2str(den) ']']);
set_param([simhandle '/PlantDelay'],'DelayTime',num2str(tau));
set_param([simhandle '/spWorkspace'],'SampleTime',num2str(Ts));
set_param([simhandle '/cvWorkspace'],'SampleTime',num2str(Ts));
set_param([simhandle '/pvWorkspace'],'SampleTime',num2str(Ts));
set_param([simhandle '/toutWorkspace'],'SampleTime',num2str(Ts));
set_param([simhandle '/ISA PID'],'Ts',num2str(Ts));
set_param(simhandle,'StopTime',num2str(2*Tf));

set_param([simhandle '/SetPoint'],'Time',num2str(0));
set_param([simhandle '/SetPoint'],'After',num2str(1));
set_param([simhandle '/Disturbance'],'Time',num2str(4/3*Tf));
set_param([simhandle '/Disturbance'],'After',num2str(0.1));

figure(...
   'Name',               'Step response',...
   'NumberTitle',        'off');

% simulation of the step response with different autotuner
% Ziegler & Nichols with Step identification
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'ZN (OL)',[],'PID');
PIDPARAMETERS = [K,Ti,Td,N,b];
sim('steppidsupport');
subplot(211)
plot(tout,pvVec,'b')
set(gca,'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8)
hold on
subplot(212)
plot(tout,cvVec,'b')
set(gca,'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8)
hold on

% Kappa-Tau with Ms = 2
% in order to obtain better performance
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'KT',2,'PID');
PIDPARAMETERS = [K,Ti,Td,N,b];
sim('steppidsupport');
subplot(211)
plot(tout,pvVec,'r')
subplot(212)
plot(tout,cvVec,'r')

% Internal Model Control with lambda = Tf/5
% this means that the closed loop model is made five time faster than the
% original (open loop model)
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'IMC',Tf/10,'PID');
PIDPARAMETERS = [K,Ti,Td,N,b];
sim('steppidsupport');
subplot(211)
plot(tout,pvVec,'g')
subplot(212)
plot(tout,cvVec,'g')

% Ziegler & Nichols with Relay identification
[K,Ti,Td,N,b] = pid_tuning(modelPI,'ZN (CL)',[],'PID');
PIDPARAMETERS = [K,Ti,Td,N,b];
sim('steppidsupport');
subplot(211)
plot(tout,pvVec,'m',tout,spVec,'k:')
title('Step and Load Disturbance Response',...
   'Color',[0 0 0],'FontSize',8)
ylabel('Process Value',...
   'Color',[0 0 0],'FontSize',8)
legend('STEP + ZN(OL)','STEP + KT','STEP + IMC','RELAY + ZN(CL)',4)
subplot(212)
plot(tout,cvVec,'m')
xlabel('Time [sec]',...
   'Color',[0 0 0],'FontSize',8)
ylabel('Control Variable',...
   'Color',[0 0 0],'FontSize',8)