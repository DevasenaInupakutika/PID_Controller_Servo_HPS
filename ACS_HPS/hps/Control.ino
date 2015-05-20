
void control_update(){
  throttle=map(rx_values[2],THROTTLE_RMIN,THROTTLE_RMAX,MOTOR_ZERO_LEVEL,MOTOR_MAX_LEVEL);
  
  setpoint_update();
  pid_update();
  pid_compute();
  
  // yaw control disabled for stabilization testing...
  m0 = throttle + pid_yaw_out;
  m1 = throttle - pid_yaw_out;

  #ifdef SAFE
    if(throttle < THROTTLE_SAFE_SHUTOFF)
    {
      m0 = m1 = MOTOR_ZERO_LEVEL;
    }
  #endif
  
  update_motors(m0, m1);
}

void setpoint_update() {
  // here we allow +- 20 for noise and sensitivity on the RX controls...   
  //YAW rx at mid level?
  if(rx_values[3] > THROTTLE_RMID - 20 && rx_values[3] < THROTTLE_RMID + 20)
    pid_yaw_setpoint = 0;
  else
    pid_yaw_setpoint = map(rx_values[3],YAW_RMIN,YAW_RMAX,YAW_WMIN,YAW_WMAX);
}
