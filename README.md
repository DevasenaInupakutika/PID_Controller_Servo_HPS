## Controlling Yaw (Movement of Submarine fins) in order to make it move in a Straight desired path

The code present in PID_AdaptiveTunings will be used as a base to further tweak it based on the Input variable, SetPoint and Output variables.

We have used Arduino PID Library for this purpose.

The header file `PID_v1.h` and its functions definitions inside `PID_v1.cpp` should be created at the path below:

`{Arduino}\libraries` directory under a newly created directory say `PID_Basic` etc. Since this include file (`.h`) is meant to be shared by multiple sketches. 

