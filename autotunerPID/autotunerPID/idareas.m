function model = idareas(y,As,Ts)
%IDAREAS Identification of a FOPDT model using the method of the
%   areas.
%
%   MODEL = IDAREAS(Y,As,Ts) returns a structure describing the identified
%   FOPDT (First Order Plus Dead Time) model in the form
%            M(s) = m*exp(-s*L) / (1+s*T)
%   The structure has the following fields MODEL.m, MODEL.L and MODEL.T
%   with obvious meaning.
%   The function requires the recorded step response Y, the amplitude of
%   the step used for identification As and the sample time Ts.
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

% compute auxiliary parameters
m = (y(end)-y(1))/As;                     % process gain

% if m<0 reverse the step response
if m<0
   y = -y;
end

% change this setting one can try to robustify the identification process
% with noisy step response
y1 = y(1);
yN = y(end);

% reverse undershoot and overshoot
y(y<y1) = y1;
y(y>yN) = y(y>yN) - 2*(y(y>yN)-yN);

A0  = sum(yN-y)*Ts;              % upper area
it0 = fix(A0/abs(m)/Ts);         % compute the index of the vector 
                                 % (not the value of t0)
A1  = sum(y(1:it0)-y1)*Ts;       % lower area

% compute model parameters
T = exp(1)*A1/abs(m);
L = max((A0-exp(1)*A1)/abs(m),0);

model.L = L;
model.T = T;
model.m = m;