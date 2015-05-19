function bodePIDcompare(num,den,tau)
%BODEPIDCOMPARE Comparison of Bode Diagrams with different autotuning
%   methods.
%   
%   The function is typically called through the GUI in AutotunerPID.mdl
%   and provides a graphical comparison of four different autotuning
%   methods (STEP/ZN(OL), STEP/KT, STEP/IMC, RELAY/ZN(CL)) in frequency
%   domain. 
%   By default the parameter Ms is set to 2 in KT methods, while the
%   parameter lambda is set 1/5 of the settling time of the plant.
%   
%   
%   BODEPIDCOMPARE(NUM,DEN,TAU) performs the comparative analysis directly
%   considering the plant described by the transfer function
%              NUM(s)
%      P(s) = -------- * exp(-TAU*s)
%              DEN(s)
%
%   See also STEPPID
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

global PIDPARAMETERS

% Bode diagram of the real plant model
P = tf(num,den,'IODelay',tau);
[m,f,w] = bode(P);
w = logspace(log10(w(1)),log10(w(end)),512);
s = j*w;

% compute step response
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

% evaluate the frequency response of the plant
P = squeeze(freqresp(P,w)).';

% Create new figure
Lfig = figure(...
   'Name',               'Bode diagram - Open loop function',...
   'NumberTitle',        'off',...
   'MenuBar',            'figure');
Ffig = figure(...
   'Name',               'Bode diagram - Complementary sensitivity',...
   'NumberTitle',        'off',...
   'MenuBar',            'figure');
Sfig = figure(...
   'Name',               'Bode diagram - Sensitivity',...
   'NumberTitle',        'off',...
   'MenuBar',            'figure');

% Bode diagrams with different autotuner
% Ziegler & Nichols with Step identification
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'ZN (OL)',[],'PID');
Rff = K*(b+1./(Ti*s));
Rfb = K*(1+1./(Ti*s)+(Td*s)./(1+Td*s/N));
L = Rfb.*P;
F = (Rff.*P)./(ones(1,length(P))+(Rfb.*P));
S = 1./(ones(1,length(P))+(Rfb.*P));
figure(Lfig)
subplot(211), semilogx(w,20*log10(abs(L)),'b')
subplot(212), semilogx(w,unwrap(angle(L))/pi*180,'b')
figure(Ffig)
subplot(211), semilogx(w,20*log10(abs(F)),'b')
subplot(212), semilogx(w,unwrap(angle(F))/pi*180,'b')
figure(Sfig)
subplot(211), semilogx(w,20*log10(abs(S)),'b')
subplot(212), semilogx(w,unwrap(angle(S))/pi*180,'b')

% Kappa-Tau with Ms = 2
% in order to obtain better performance
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'KT',2,'PID');
Rff = K*(b+1./(Ti*s));
Rfb = K*(1+1./(Ti*s)+(Td*s)./(1+Td*s/N));
L = Rfb.*P;
F = (Rff.*P)./(ones(1,length(P))+(Rfb.*P));
S = 1./(ones(1,length(P))+(Rfb.*P));
figure(Lfig)
subplot(211), hold on, semilogx(w,20*log10(abs(L)),'r')
subplot(212), hold on, semilogx(w,unwrap(angle(L))/pi*180,'r')
figure(Ffig)
subplot(211), hold on, semilogx(w,20*log10(abs(F)),'r')
subplot(212), hold on, semilogx(w,unwrap(angle(F))/pi*180,'r')
figure(Sfig)
subplot(211), hold on, semilogx(w,20*log10(abs(S)),'r')
subplot(212), hold on, semilogx(w,unwrap(angle(S))/pi*180,'r')

% Internal Model Control with lambda = Tf/5
% this means that the closed loop model is made five time faster than the
% original (open loop model)
[K,Ti,Td,N,b] = pid_tuning(modelFOPDT,'IMC',Tf/5,'PID');
Rff = K*(b+1./(Ti*s));
Rfb = K*(1+1./(Ti*s)+(Td*s)./(1+Td*s/N));
L = Rfb.*P;
F = (Rff.*P)./(ones(1,length(P))+(Rfb.*P));
S = 1./(ones(1,length(P))+(Rfb.*P));
figure(Lfig)
subplot(211), hold on, semilogx(w,20*log10(abs(L)),'g')
subplot(212), hold on, semilogx(w,unwrap(angle(L))/pi*180,'g')
figure(Ffig)
subplot(211), hold on, semilogx(w,20*log10(abs(F)),'g')
subplot(212), hold on, semilogx(w,unwrap(angle(F))/pi*180,'g')
figure(Sfig)
subplot(211), hold on, semilogx(w,20*log10(abs(S)),'g')
subplot(212), hold on, semilogx(w,unwrap(angle(S))/pi*180,'g')

% Ziegler & Nichols with Relay identification
[K,Ti,Td,N,b] = pid_tuning(modelPI,'ZN (CL)',[],'PID');
Rff = K*(b+1./(Ti*s));
Rfb = K*(1+1./(Ti*s)+(Td*s)./(1+Td*s/N));
L = Rfb.*P;
F = (Rff.*P)./(ones(1,length(P))+(Rfb.*P));
S = 1./(ones(1,length(P))+(Rfb.*P));

figure(Lfig)
subplot(211), semilogx(w,20*log10(abs(L)),'m')
set(gca,'Position', [0.1514 0.4858 0.7536 0.3916],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8,...
   'XTickLabel',[])
title('Bode Diagram - Open loop function',...
   'Color',[0 0 0],'FontSize',8)
ylabel('Magnitude (dB)',...
   'Color',[0 0 0],'FontSize',8)
legend('STEP + ZN(OL)','STEP + KT','STEP + IMC','RELAY + ZN(CL)',4)
subplot(212), semilogx(w,unwrap(angle(L))/pi*180,'m')
set(gca,'Position',[0.1514 0.1100 0.7536 0.3472],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8)
ylabel('Phase (deg)',...
   'Color',[0 0 0],'FontSize',8)
xlabel('Frequency (rad/sec)',...
    'Color',[0 0 0],'FontSize',8)

figure(Ffig)
subplot(211), semilogx(w,20*log10(abs(F)),'m')
set(gca,'Position', [0.1514 0.4858 0.7536 0.3916],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8,...
   'XTickLabel',[])
title('Bode Diagram - Complementary sensitivity function',...
   'Color',[0 0 0],'FontSize',8)
ylabel('Magnitude (dB)',...
   'Color',[0 0 0],'FontSize',8)
legend('STEP + ZN(OL)','STEP + KT','STEP + IMC','RELAY + ZN(CL)',4)
subplot(212), semilogx(w,unwrap(angle(F))/pi*180,'m')
set(gca,'Position',[0.1514 0.1100 0.7536 0.3472],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8)
ylabel('Phase (deg)',...
   'Color',[0 0 0],'FontSize',8)
xlabel('Frequency (rad/sec)',...
    'Color',[0 0 0],'FontSize',8)

figure(Sfig)
subplot(211), semilogx(w,20*log10(abs(S)),'m')
set(gca,'Position', [0.1514 0.4858 0.7536 0.3916],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8,...
   'XTickLabel',[])
title('Bode Diagram - Sensitivity function',...
   'Color',[0 0 0],'FontSize',8)
ylabel('Magnitude (dB)',...
   'Color',[0 0 0],'FontSize',8)
legend('STEP + ZN(OL)','STEP + KT','STEP + IMC','RELAY + ZN(CL)',4)
subplot(212), semilogx(w,unwrap(angle(S))/pi*180,'m')
set(gca,'Position',[0.1514 0.1100 0.7536 0.3472],...
   'XColor',[0.4 0.4 0.4],'YColor',[0.4 0.4 0.4],...
   'FontSize',8)
ylabel('Phase (deg)',...
   'Color',[0 0 0],'FontSize',8)
xlabel('Frequency (rad/sec)',...
   'Color',[0 0 0],'FontSize',8)