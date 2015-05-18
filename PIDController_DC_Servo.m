%Investigating derivative gains Kd ranging from 0.05 to 0.25
Kp = 21;
Ki = 500;
Kd = 0.05;

C = pid(3,3,3);
for i = 1:3
    C(:,:,i) = pid(Kp,Ki,Kd);
    Kd = Kd + 0.1;
end

sys_cl = feedback(C*P_motor,1);
t = 0:0.001:0.1;
step(sys_cl(:,:,1), sys_cl(:,:,2), sys_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Reference with K_p = 21, K_i = 500 and Different Values of K_d')
legend('K_d = 0.05', 'K_d = 0.15', 'K_d = 0.25')

%With step disturbance input
dist_cl = feedback(P_motor,C);
t = 0:0.001:0.2;
step(dist_cl(:,:,1), dist_cl(:,:,2), dist_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Disturbance with K_p = 21, K_i = 500 and Different values of K_d')
legend('K_d = 0.05', 'K_d = 0.15', 'K_d = 0.25')

%Looking at the plots, design requirements can be met when kd = 0.15

%To determine the precise characteristics of the step response, below is
%the command
stepinfo(sys_cl(:,:,2))

%From the above, we see that the response to a step reference has a settlin
%g time of roughly 34ms (< 40 ms), overshoot of 12% (< 16%), and no steady-
%state error. Additionally, the step disturbance response also has no stea-
%dy-state error. So now we know that if we use a PID controller with

%Kp = 21, Ki = 500, and Kd = 0.15,

%all of our design requirements will be satisfied.