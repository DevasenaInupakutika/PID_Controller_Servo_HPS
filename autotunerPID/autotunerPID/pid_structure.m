function regStruct = pid_structure(model,reqStruct)
%PID_STRUCTURE Structure selection for a ISA-PID regulator.
%
%   REGSTRUCT = PID_STRUCTURE(MODEL,REQSTRUCT) returns the ``best''
%   structure for the regulator, assuming that the controlled plant can be
%   described with a FOPDT model.
%   MODEL is a structure with the description of the process model with the
%   fields {m L T} (parameters of a FOPDT model M(s) = m*exp(-sL)/(1+s*T)).
%   The structure may be computed through the function setting the flag
%   REQSTRUCT to 'AUTO', or may be constrained to a particular one by
%   setting the flag REQSTRUCT to 'PI' or 'PID' respectively.
%
%   The structure selection is performed only if a FOPDT model of the
%   process is given, otherwise the PID structure is selected.  If the
%   control problem is intrinsically difficult the PID structure is
%   selected, and a warning message is prompted.
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

if nargin < 2
   reqStruct = 'AUTO';
end

switch reqStruct
   case 'PI'
      % override selection
      regStruct  = 'PI';
      
   case 'PID'
      % override selection
      regStruct  = 'PID';
      
   case 'AUTO'
      if isfield(model,'m')
         % selection performed only if a FOPDT model is provided
         m = model.m; L = model.L; T = model.T;
         
         % compute the ultimate frequency
         wmin = (-pi/2)/L;    % lower bound
         wmax = (-pi)/L;      % upper bound
         w    = real(logspace(log10(wmin),log10(wmax),1024));
         phaseM = angle(m*exp(-j*L*w)./(1+j*w*T));
         wu = w(find(phaseM==min(phaseM)));
         
         k1  = 1/abs(m*exp(-j*L*wu)/(1+j*wu*T));
         th1 = L/T;
         
         if th1>1 & k1<1.5
            regStruct = 'PI';
            msgbox('Bad results expected','AutotunerPID','warn');
         elseif (th1>0.6 & th1<1) & (k1>1.5 & k1<2.25)
            regStruct = 'PI';
         elseif th1<0.6 & k1>2.25
            regStruct = 'PID';
         else
            regStruct = 'PID';
            msgbox('Bad results expected','AutotunerPID','warn');
         end
      else
         regStruct = 'PID';
      end
      
   otherwise
      msgbox('Unknown structure','AutotunerPID','warn');
      regStruct  = 'PID';
end