import oscP5.*;

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
  
  OscMessage toOscMessage (String address) {
    OscMessage message = new OscMessage(address);
    message.add(this.direction);
    message.add(this.frequency);
    message.add(this.amplitude);
    message.add(this.isBoosting);
    return message;
  }
}
