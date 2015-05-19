function [B,A] = butterdesign(N,Wc)
%BUTTERDESIGN Butterworth analog lowpass filter design.
%
%   [B,A] = BUTTERDESIGN(N,Wc) returns the numerator and denominator for an
%   N-th order Butterworth analog with a bandwith Wc.
%   The resulting filter has N poles around the circle of radius Wn in the
%   left half plane, and no zeros. 
%
%   Author:    William Spinelli (wspinell@elet.polimi.it)
%   Copyright  2004 W.Spinelli
%   $Revision: 1.0 $  $Date: 2004/02/27 12:00:00 $

% Poles are on the circle of radius Wn in the left-half plane.
p = Wc*exp(i*(pi*(1:2:N-1)/(2*N) + pi/2));
p = [p; conj(p)];
p = p(:);
if rem(N,2)==1, p = [p; -Wc]; end
A = poly(p);
B = real(prod(-p));