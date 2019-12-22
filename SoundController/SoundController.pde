import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.ugens.*;
import ddf.minim.analysis.*;
import javax.sound.sampled.*;

Minim minim;
AudioInput in;
Minim minim2;
AudioInput in2;
float diff = 0;
boolean shouldPause = false;
int maxShift = 10;
float dirFromShift = 0;

int PORT_INDEX = 5;
int SAMPLING_RATE = 48000;
int N_SAMPLES = 2048;
int MAX_SAMPLES_SHIFT = 8;
int PEAK_TIMEOUT_MS = 100;
int ENERGY_WINDOW = 250;

float ENERGY_THRESH = 1;
float THRESH_FALLING = 1;

int clapCount = 0;
boolean threshActivated = false;
int timeTriggered = 0;

float[] energyPlot;
float[] shiftHist;
 
SmoothFloat bestShiftSmoothed = new SmoothFloat(0, 7);
SmoothFloat rmsSdSmoothed = new SmoothFloat(0, 2);
SmoothFloat energySmoothed = new SmoothFloat(0, 2);
SmoothFloat rateSmoothed = new SmoothFloat(0, 3);

Plotter rPlotter = new Plotter(256);;
Plotter bestShiftPlotter = new Plotter(256);;
Plotter rmsPlotter = new Plotter(256);
Plotter energyPlotter = new Plotter(256);
SpectogramPlotter shiftPlotter  = new SpectogramPlotter(256);

float MIN_SIGNAL_AMP = 0.02;
float ENERGY_SD_THRESH = 0.8;
float MAX_ENERGY = 1.5;
float MIN_ENERGY = 0.05;

int PEAK_TIMEOUT = 100;
float energy, lastEnergy, energyDiff, lastEnergyDiff;
 
int PADDLE_TIMEOUT = 300;

int lastBeatTime = 0;

FloatList energyHist = new FloatList();
int energyHistmaxSize = 60;

boolean dummyMode = true;

FFT fft;
  
void setup()
{
  Mixer.Info[] mixerInfo;
  mixerInfo = AudioSystem.getMixerInfo();
  for (int i = 0; i < mixerInfo.length; i++) {
    println(i + " = " + mixerInfo[i].getName());
  } 
  
  size(1024, 256, P3D);
  minim = new Minim(this);
  //Mixer mixer = AudioSystem.getMixer(mixerInfo[PORT_INDEX]);
  //minim.setInputMixer(mixer);
  in = minim.getLineIn(Minim.STEREO, N_SAMPLES, SAMPLING_RATE);
  //in = minim.getLineIn(Minim.MONO, N_SAMPLES, SAMPLING_RATE);
  
  ////minim2 = new Minim(this);
  ////Mixer mixer2 = AudioSystem.getMixer(mixerInfo[4]);
  ////minim2.setInputMixer(mixer2);
  ////in2 = minim2.getLineIn(Minim.MONO, N_SAMPLES, SAMPLING_RATE);
  
  //background(0);
  
  //energyPlot = new float[N_SAMPLES];
  //shiftHist = new float[N_SAMPLES];
  
  
  //size(512, 512, P3D);

  //minim = new Minim(this);
  
  //// use the getLineIn method of the Minim object to get an AudioInput
  //in = minim.getLineIn();
  
  fft = new FFT( in.bufferSize(), in.sampleRate() );
}


void draw() {
  if (dummyMode) {
    drawDummyMode();
  } else {
    drawRealMode();
  }
}



void drawRealMode()
{
  // compute

  FloatList lSamples = new FloatList();
  FloatList rSamples = new FloatList();
    
  for(int i = 0; i < in.bufferSize() - 1; i++)
  {
    float li = in.left.get(i);
    float ri = in.right.get(i);
    float li1 = in.left.get(i + 1);
    float ri1 = in.right.get(i + 1);
    
    line( i, 50 + li*50, i+1, 50 + li1*50 );
    line( i, 150 + ri*50, i+1, 150 + ri1*50 );
    
    lSamples.append(li);
    rSamples.append(ri);
  }
  
  
  
  
  //calculate wave energy
  //calculate rate
  int t = millis();
  fft.forward(in.left);
  lastEnergy = energy;
  energy = fft.calcAvg(0, 2000);
   
  lastEnergyDiff = energyDiff;
  energyDiff = energy - lastEnergy;
  
  energyPlotter.addData(energy);
  
  print(nfp(energy, 1, 4));
  //print(" ");
  //print(nfp(lastEnergy, 1, 4));
  //print(" ");
  //print(nfp(energyDiff, 1, 4));
  //print(" ");
  //print(nfp(lastEnergyDiff, 1, 4));
  println(" ");
  
  if (energy > ENERGY_THRESH && energyDiff < 0 && lastEnergyDiff >= 0 && t - timeTriggered > PEAK_TIMEOUT) {
    // local peak
    timeTriggered = millis();
    
    clapCount++;
    //print("!!!!!!!!!!!!!!!!!!!!!! ");
    //print(nfp(energy, 1, 4));
    //print(" ");
    //println(clapCount);
    float rate = 1000.0 / (t - lastBeatTime);
    lastBeatTime = t;
    rateSmoothed.set(rate);
  }
  
  if (t - lastBeatTime > PADDLE_TIMEOUT) {
    rateSmoothed.set(0);
  }
  
  float energyNormalized = constrain(map(energy, MIN_ENERGY, MAX_ENERGY, 0, 1), 0, 1);
  
  
  
    
  // calculate impulse vs continuous wave
  energyHist.append(energy);
  while (energyHist.size() > energyHistmaxSize) {
    energyHist.remove(0);
  }
  float energyHistMean = calculateMean(energyHist);
  float energyHistSd = calculateStandardDev(energyHist, energyHistMean);
  rmsSdSmoothed.set(energyHistSd, energyHistSd > rmsSdSmoothed.get());
  boolean isImpulses = rmsSdSmoothed.get() > ENERGY_SD_THRESH;
  
  rmsPlotter.addData(rmsSdSmoothed.get());
  print(energyHistSd);
  print(" ");
  print(rmsSdSmoothed.get());
  print(" ");
  println(isImpulses);
  
  Plotter energyFramePlotter = new Plotter(energyHist.size());
  for (int i = 0; i < energyHist.size(); i++) {
    energyFramePlotter.addData(energyHist.get(i));
    //print(nfp(r, 1, 2));
    //print(" ");
  }

  
  
  
  // calculate sound directionality
  FloatList shiftFrame = new FloatList();
  Plotter framePlotter = new Plotter(MAX_SAMPLES_SHIFT * 2 + 1);
  for (int s = -MAX_SAMPLES_SHIFT; s <= MAX_SAMPLES_SHIFT; s++) {
    float r = calculateCorrelationWithShift(lSamples, rSamples, s);
    shiftFrame.append(r);
    framePlotter.addData(r);
    //print(nfp(r, 1, 2));
    //print(" ");
  }
  shiftPlotter.addData(shiftFrame);
  //print(": ");
  //println(shiftFrame.max());
  
  
  int indexOfMax = 0;
  float maxR = shiftFrame.max();
  for (int i = 0; i < shiftFrame.size(); i++) {
    if (shiftFrame.get(i) == maxR) {
      indexOfMax = i;
      break;
    }
  }
  //print(": ");
  int shift = shiftFrame.max() > 0.95 ? indexOfMax - MAX_SAMPLES_SHIFT : 0;
  //println(shift);
  
  //bestShiftSmoothed.set(shift);
  bestShiftSmoothed.set(shift);//, abs(shift) > abs(bestShiftSmoothed.get()));
  bestShiftPlotter.addData(bestShiftSmoothed.get());
  

  
  boolean isBoosting = !isImpulses && energy > ENERGY_THRESH;
  // transmit data
  FrameData fd = new FrameData(
    bestShiftSmoothed.get() / MAX_SAMPLES_SHIFT,  // direction
    rateSmoothed.get(),                           // paddling frequency
    energyNormalized,                             // amplitude
    isBoosting);                                 // isBoosting
    
  fd.print();
  
  
  
  // draw
  if (isBoosting)
    background(0, 0, 255);
  else
    background(0);
  stroke(255);
  
  //shiftPlotter.plot(0, 0, width, height, 0.95, 1.5);
  //stroke(0, 0, 255);
  //framePlotter.plot(0, 0, width, height, 0.8, 1);
  
  //energyPlotter.plot(0, 0, width, height);
  
  fill(255, 100);
  noStroke();
  rect(0, (1 - energyNormalized) * height, width, energyNormalized * height);
  
  stroke(255, 0, 0);
  line(width / 2, 0, width / 2, height);
  
  stroke(255);
  bestShiftPlotter.plot(0, 0, width, height, -MAX_SAMPLES_SHIFT, MAX_SAMPLES_SHIFT);
  
  //noStroke();
  //fill(255, 255, 0);
  //scatterPlot(lSamples, rSamples, 5, 0, 0, width, height);


  //stroke(0, 255, 255);
  //rmsPlotter.plot(0, 0, width, height, 0, 5);
  
  //stroke(255);
  //energyFramePlotter.plot(0, 0, width, height, 0, 5);
  
  textSize(72); 
  textAlign(CENTER, CENTER);
  text(nf(rateSmoothed.get(), 2, 2), width / 2, height / 2);
}



FloatList calculateEnvelope (FloatList s, int windowSize) {
  FloatList sEnv = new FloatList();
  for (int i = 0; i < s.size() - windowSize; i++) {
    float maxS = 0;
    for (int j = 0; j < windowSize; j++) {
      if (s.get(i + j) > maxS)
        maxS = s.get(i + j);
    }
    sEnv.append(maxS);
  }
  return sEnv;
}



float calculateRmsSd (FloatList s, int windowSize) {
  int stride = 1;
  FloatList rmsList = new FloatList();
  for (int i = 0; i < s.size() - windowSize; i += stride) {
    rmsList.append(calculateRms(s, i, i + windowSize));
  }
  
  float rmsBar = calculateMean(rmsList);
  float rmsSd = calculateStandardDev(rmsList, rmsBar);
  return rmsSd / rmsBar;  // Normalized SD
}

float calculateRms (FloatList s, int start, int end) {
  float rms = 0;
  for (int j = start; j < end; j++) {
     rms += s.get(j) * s.get(j);
  }
  return sqrt(rms / (end - start));
}

void scatterPlot(FloatList xList, FloatList yList, int shift, int x0, int y0, int w, int h) {
  //FloatList xList = new FloatList(x);
  //FloatList yList = new FloatList(y);
  
  int n = min(xList.size(), yList.size()) - abs(shift);
  
  for (int i = 0; i < n; i++) {
    float xMax = xList.max();
    float xMin = xList.min();
    float yMax = yList.max();
    float yMin = yList.min();
    
    if (shift >= 0) {
      rect(
        x0 + (xList.get(i) - xMin) / (xMax - xMin) * w,
        y0 + h - (yList.get(i + shift) - yMin) / (yMax - yMin) * h,
        1, 1);
    } else {
      rect(
        x0 + (xList.get(i - shift) - xMin) / (xMax - xMin) * w,
        y0 + h - (yList.get(i) - yMin) / (yMax - yMin) * h,
        1, 1);
    }
  }
}


float calculateCorrelationWithShift (FloatList x, FloatList y, int shift) {
  if (x.size() != y.size()) {
    println("calculateCorrelationWithShift(): X AND Y LENGTHS DIFFER");
  }
  
  int absShift = abs(shift);
  FloatList xt = new FloatList();
  FloatList ytShifted = new FloatList();
  
  int n = min(x.size(), y.size());
  
  for(int i = 0; i < n - absShift; i++) {
    if (shift >= 0) {
      xt.append(x.get(i));
      ytShifted.append(y.get(i + absShift));
      // 0,5 1,6 2,7 ...
    } else {
      xt.append(x.get(i + absShift));
      ytShifted.append(y.get(i));
      // 0,-5 1,-4 2,-3
      // 5,0 6,1 7,2
    }
  }
  return calculateCorrelation(xt, ytShifted);
}



float calculateCorrelation (FloatList x, FloatList y) {
  
  if (x.size() != y.size()) {
    println("calculateCorrelation(): X AND Y LENGTHS DIFFER");
  }
  
  float xBar = calculateMean(x);
  float yBar = calculateMean(y);
  
  float sx = calculateStandardDev(x, xBar);
  float sy = calculateStandardDev(y, yBar);
  
  int n = min(x.size(), y.size());
  
  //float[] zx = new float[n];
  //float[] zy = new float[n];
  float sumProduct = 0;
  
  int countQualified = 0;
  for (int i = 0; i < n; i++) {
    float zx = (x.get(i) - xBar) / sx;
    float zy = (y.get(i) - yBar) / sy;
    
    if (max(abs(x.get(i)), y.get(i)) > MIN_SIGNAL_AMP) {
      sumProduct += zx * zy;
      countQualified++;
    }
  }
  
  return countQualified > 0 ? sumProduct / countQualified : 0;
}

float calculateMean (FloatList x) {
  float sum = 0;
  for (int i = 0; i < x.size(); i++) {
    sum += x.get(i);
  }
  return sum / x.size();
}

float calculateStandardDev (FloatList x, float xBar) {
  float sum = 0;
  for (int i = 0; i < x.size(); i++) {
    float dx = x.get(i) - xBar;
    sum += dx * dx; 
  }
  return sqrt(sum / x.size());
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// DUMMY MODE

void drawDummyMode () {
  boolean isBoosting = mousePressed;
  float direction = (float)mouseX / (width / 2) - 1;
  float energy = 1 - (float)mouseY / height;
  float rowingRate = rateSmoothed.get();
  
  if (millis() - lastBeatTime > PADDLE_TIMEOUT) {
    rateSmoothed.set(0);
  }
  
  FrameData fd = new FrameData(
    direction,   // direction
    rowingRate,  // paddling frequency
    energy,      // amplitude
    isBoosting); // isBoosting
    
  fd.print();
  
  if (isBoosting)
    background(0, 0, 255);
  else
    background(0);
  stroke(255);
  
  fill(255, 100);
  noStroke();
  rect(0, (1 - energy) * height, width, energy * height);
  
  stroke(255, 0, 0);
  line(width / 2, 0, width / 2, height);
  
  stroke(255);
  bestShiftPlotter.addData(direction);
  bestShiftPlotter.plot(0, 0, width, height, -1, 1);
  
  textSize(18);
  fill(255);
  textAlign(LEFT, TOP);
  text("DUMMY MODE: ON", 10, 10);
  
  textSize(72);
  fill(255);
  textAlign(CENTER, CENTER);
  text(nf(rateSmoothed.get(), 2, 2), width / 2, height / 2);
  
  delay(50);
}

void keyPressed () {
  if (dummyMode) {
    if (key == ' ') {
      int t = millis();
      timeTriggered = t;
    
      clapCount++;
      //print("!!!!!!!!!!!!!!!!!!!!!! ");
      //print(nfp(energy, 1, 4));
      //print(" ");
      //println(clapCount);
      float rate = 1000.0 / (t - lastBeatTime);
      lastBeatTime = t;
      rateSmoothed.set(rate);
    }
  }
  
  if (key == 'd' || key == 'D') {
    dummyMode = !dummyMode;
  }
}
