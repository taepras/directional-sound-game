import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.ugens.*;
import javax.sound.sampled.*;
Minim minim;
AudioInput in;
Minim minim2;
AudioInput in2;
float diff = 0;
boolean shouldPause = false;
int maxShift = 30;
float dirFromShift = 0;

int SAMPLING_RATE = 44100;
int N_SAMPLES = 1024;
int MAX_SAMPLES_SHIFT = 30;
int IMPULSE_TIMEOUT_MS = 100;
int ENERGY_WINDOW = 250;

float THRESH_RISING = 0.2;
float THRESH_FALLING = 0.15;

int clapCount = 0;
boolean threshActivated = false;
int timeTriggered = 0;

float[] energyPlot;
float[] shiftHist;
  
void setup()
{
  Mixer.Info[] mixerInfo;
  mixerInfo = AudioSystem.getMixerInfo();
  for (int i = 0; i < mixerInfo.length; i++) {
    println(i + " = " + mixerInfo[i].getName());
  } 
  
  size(1024, 1000);
  minim = new Minim(this);
  Mixer mixer = AudioSystem.getMixer(mixerInfo[3]);
  minim.setInputMixer(mixer);
  //in = minim.getLineIn(Minim.STEREO, N_SAMPLES, SAMPLING_RATE);
  in = minim.getLineIn(Minim.MONO, N_SAMPLES, SAMPLING_RATE);
  
  minim2 = new Minim(this);
  Mixer mixer2 = AudioSystem.getMixer(mixerInfo[4]);
  minim2.setInputMixer(mixer2);
  in2 = minim2.getLineIn(Minim.MONO, N_SAMPLES, SAMPLING_RATE);
  
  background(0);
  
  energyPlot = new float[N_SAMPLES];
  shiftHist = new float[N_SAMPLES];
}
void draw()
{
  if (shouldPause) {
    //delay(1000);
    shouldPause = false;
  }
  fill(0, 0, 0, 20);
  //fill(0, 0, 0);
  rect(0, 0, width, height);
  stroke(255);
  noFill();
  
  float energyL = 0;
  float energyR = 0;
  float e = 0.5;
  
  float[] lSamples = new float[N_SAMPLES];
  float[] rSamples = new float[N_SAMPLES];
  
  //float[] rSamples = new float[N_SAMPLES];
  
  float diffSqDist = 0;
  
  // draw the waveforms so we can see what we are monitoring
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    float x = 500;
    float lm = 1;
    float rm = 1;
    float m = 0.0005;
    float li = in.left.get(i) * lm;
    //float ri = in.right.get(i) * rm;
    float ri = in2.left.get(i) * rm;
    float li1 = in.left.get(i + 1) * lm;
    //float ri1 = in.right.get(i + 1) * rm;
    float ri1 = in2.left.get(i + 1) * lm;
    
    float dx = (li != 0 && ri != 0) ? ((float)1 / abs(li) - (float)1 / abs(ri)) : 0;
    float dx1 = (li1 != 0 && ri1 != 0) ? ((float)1 / abs(li1) - (float)1 / abs(ri1)) : 0;
    diffSqDist += dx;
    
    line( i, 50 + li * x, (i + 1), 50 + li1 * x );
    //line( i, 100 + dx * m, (i + 1), 100 + dx1 * m);
    line( i, 150 + ri * x, (i + 1), 150 + ri1 * x );
    
    if (i < ENERGY_WINDOW) {
      energyL += li * li;
      energyR += ri * ri;
    }
    
    lSamples[i] = li;
    rSamples[i] = ri;
  }
  
  if ((energyL + energyR) / 2 > THRESH_RISING) {
    threshActivated = true;
    timeTriggered = millis();
  } else if (threshActivated && (energyL + energyR) / 2 < THRESH_FALLING) {
    threshActivated = false;
    int t = millis() - timeTriggered;
    //if (t < IMPULSE_TIMEOUT_MS) {
    //  clapCount++;
    //  //print(clapCount);
    //  //print(" ");
    //  //println(t);
    //}
  }
  
  //println((energyL + energyR) / 2);
  int bestShift = 0;
    
  if ((energyL + energyR) / 2 > 0.001) {
      
    float bestSumDiff = 1000000000;
    for (int s = -MAX_SAMPLES_SHIFT; s <= MAX_SAMPLES_SHIFT; s++) {
      float sumDiff = 0;
      for (int i = 0; i < lSamples.length - abs(s); i++) {
        float diff = 0;
        if (s < 0)
          diff += lSamples[i - s] - rSamples[i];
        else
          diff += lSamples[i] - rSamples[i + s];
        sumDiff += diff * diff;
      }
      
      if (sumDiff < bestSumDiff) {
        bestSumDiff = sumDiff;
        bestShift = s;
      }
      //print(sumDiff);
      //print(" ");
    }
    //println(bestShift);
    shouldPause = true;
  }
  
  for(int i = energyPlot.length - 1; i > 0; i--) {
    energyPlot[i] = energyPlot[i - 1];
  }
  energyPlot[0] = (energyL + energyR) / 2; //energyPlot[1] * e + (energyL + energyR) / 2 * (1 - e);
  line( 0, height - THRESH_RISING * height / 4, width, height - THRESH_RISING * height / 4);
  line( 0, height - THRESH_FALLING * height / 4, width, height - THRESH_FALLING * height / 4);
  for(int i = 0; i < energyPlot.length - 2; i++) {
    line( i, height - energyPlot[i] * height / 4, i + 1, height - energyPlot[i + 1] * height / 4);
    //line( 
    //  i, 
    //  height / 2 - (energyPlot[i + 1] - energyPlot[i]) * height / 4, 
    //  i + 1, 
    //  height / 2 - (energyPlot[i + 2] - energyPlot[i + 1]) * height / 4
    //  );
  }
  
  stroke(0, 255, 0);
  for(int i = energyPlot.length - 1; i > 0; i--) {
    shiftHist[i] = shiftHist[i - 1];
  }
  shiftHist[0] = bestShift; //energyPlot[1] * e + (energyL + energyR) / 2 * (1 - e);
  for(int i = 0; i < shiftHist.length - 2; i++) {
    line( i, height / 2 - shiftHist[i] / MAX_SAMPLES_SHIFT * height / 4, i + 1, height / 2 - shiftHist[i + 1] / MAX_SAMPLES_SHIFT * height / 4);
    //line( 
    //  i, 
    //  height / 2 - (energyPlot[i + 1] - energyPlot[i]) * height / 4, 
    //  i + 1, 
    //  height / 2 - (energyPlot[i + 2] - energyPlot[i + 1]) * height / 4
    //  );
  }
  
  if (
    threshActivated &&
    (energyPlot[2] - energyPlot[1]) > 0 &&
    (energyPlot[1] - energyPlot[0]) <= 0
  ) {
    clapCount++;
    print("!tap ");
    print(bestShift);
    println();
    //println(clapCount);
  }
  
  
  dirFromShift = dirFromShift * e + bestShift * (1 - e);
  
  fill(255, 0, 0);
  line(width / 2, 0, width / 2, height);
  float k = 0.001;
  if (energyL > 0.1 && energyR > 0.1)
    diff = diff * e + (k / energyR - k / energyL) * (1 - e);
  else
    diff = diff * e + 0 * (1 - e);
  //diff = diff * e + diffSqDist * 0.000002 * (1 - e);
  circle(constrain(width / 2 + diff * 1000 * width / 2, 0, width), height / 2, 20);
  circle(constrain(width / 2 + (float)dirFromShift / MAX_SAMPLES_SHIFT * width / 2, 0, width), height / 2 + 30, 20);
  
  rect(
    width / 2,
    0,
    (float)dirFromShift / MAX_SAMPLES_SHIFT * width / 2,
    (energyL + energyR) / 4 * height
  );
  
  line(
    0,
    (energyL + energyR) / 2 * height,
    width,
    (energyL + energyR) / 2 * height
  );
  ////print(energyL);
  ////print(" ");
  ////print(k / energyL - k / energyR);
  ////print(" ");
  ////println(diff);
  
  String monitoringState = in.isMonitoring() ? "enabled" : "disabled";
  text( "Input monitoring is currently " + monitoringState + ".", 5, 15 );
}
void keyPressed()
{
  if ( key == 'm' || key == 'M' )
  {
    if ( in.isMonitoring() )
    {
      in.disableMonitoring();
    }
    else
    {
      in.enableMonitoring();
    }
  }
}
