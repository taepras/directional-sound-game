public class FrameData {
  
  protected boolean isBoosting;
  protected float direction;      // continuous, -1 = left and 1 = right
  protected float frequency;
  protected float amplitude;
  
  FrameData (float direction, float frequency, float amplitude, boolean isBoosting) {
    this.isBoosting = isBoosting;
    this.direction = direction;
    this.frequency = frequency;
    this.amplitude = amplitude;
  }
  
  void print () {
    
  }
}
