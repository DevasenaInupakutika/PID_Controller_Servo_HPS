% AutotunerPID Toolkit
% Version 1.0 (27-Feb-2004)
%
% General purpose functions
%   bodePIDcompare      - Comparison of Bode diagrams with different
%                         autotuning methods.
%   butterdesign        - Butterworth analog lowpass filter design.
%   idareas             - Identification of a FOPDT model using the method
%                         of the areas.
%   pid_structure       - Structure selection for a PID regulator.
%   pid_tuning          - Tuning of the parameters of PID.
%   stepPIDcompare      - Comparison of step responses with different
%                         autotuning methods.
%
% S-functions
%   autogui             - PID control panel.
%   envgui              - Environment control panel.
%   pid_autotuner       - Supervisor of a PID autotuner.
%   pid_isatd           - Discrete time ISA-PID.
%
% Simulink models
%   autotunerPID.mdl    - Simulink model of the control system
%   steppidsupport.mdl  - Simulink model supporting stepPIDcompare
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

