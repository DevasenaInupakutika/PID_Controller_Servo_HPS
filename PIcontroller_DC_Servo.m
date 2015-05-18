%With step disturbance in file DC_Servo_system_model.m, larger the values of Kp, smaller the steady-state
%error in the presence of disturbance. From DC motor system modelling,
%input to the system is the voltage source (V) applied to motor's armature,
%while the output is the position of the shaft (theta). 

%Adding an integral term will eliminate the steady-state error and a
%derivative term can reduce the overshoot and settling time.

%Below is the implementation of PI controller to eliminate steady-state
%error due to disturbance.

%Setting Kp=21 and test Ki's ranging from 100 to 500. 

Kp = 21;
Ki = 100;
C = pid(3,3,3);
for i = 1:5
    C(:,:,i) = pid(Kp,Ki);
    Ki = Ki + 200;
end

%Without step-disturbance (below block)
sys_cl = feedback(C*P_motor,1);
t = 0:0.001:0.4;
step(sys_cl(:,:,1), sys_cl(:,:,2), sys_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Reference with K_p = 21 and Different Values of K_i')
legend('K_i = 100', 'K_i = 300', 'K_i = 500')

%Modifying code as below for step disturbance input but with Kp and Ki
dist_cl = feedback(P_motor,C);
step(dist_cl(:,:,1), dist_cl(:,:,2), dist_cl(:,:,3), t)
ylabel('Position, \theta (radians)')
title('Response to a Step Disturbance with K_p = 21 and Different Values of K_i')
legend('K_i = 100',  'K_i = 300',  'K_i = 500')