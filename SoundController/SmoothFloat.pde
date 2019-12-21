public class SmoothFloat {
  
  float targetValue = 0;
  float lastTargetValue = 0;
  
  int timeSinceTargetChanged = 0;
  float maxChangeRate = 1;  // unit per second
  
  SmoothFloat (float initalVal, float maxChangeRate) {
    this.targetValue = initalVal;
    this.lastTargetValue = initalVal;
    
    this.maxChangeRate = maxChangeRate;
    this.timeSinceTargetChanged = millis();
  }
  
  void set(float targetVal) {
    float currentValue = get();
    if ((targetVal - currentValue) * (this.targetValue - currentValue) >= 0) {  //same direction
      this.lastTargetValue = currentValue;
      this.timeSinceTargetChanged = millis();
    } 
    
    this.targetValue = targetVal;   
  }
  
  void set(float targetVal, boolean force) {
    if (force) {
      this.timeSinceTargetChanged = millis();
      this.targetValue = targetVal;   
      this.lastTargetValue = targetVal;
    } else {
      set(targetVal);
    }
  }
  
  float get() {
    float dt = (float)(millis() - timeSinceTargetChanged) / 1000;
    if (this.targetValue > this.lastTargetValue) {
      return easeRange(
        min(this.lastTargetValue + dt * maxChangeRate, this.targetValue), 
        this.lastTargetValue, 
        this.targetValue);
    } else if (this.targetValue < this.lastTargetValue) {
      return easeRange(
        max(this.lastTargetValue - dt * maxChangeRate, this.targetValue), 
        this.lastTargetValue, 
        this.targetValue);
    }
    return this.targetValue;
  }
  
  float ease (float t) {
    return t;
    //return t<.5 ? 2*t*t : -1+(4-2*t)*t;
  }
  
  float easeRange(float t, float m, float M) {
    return map(ease(map(t, m, M, 0, 1)), 0, 1, m, M);
  }
}
