public class SpectogramPlotter {
  
  int maxSize;
  ArrayList<FloatList> data;
  int i = 0;
  float maxData;
  
  SpectogramPlotter (int maxSize) {
    this.maxSize = maxSize;
    this.data = new ArrayList<FloatList>();
  }
  
  void addData (FloatList d) {
    this.data.add(d);
    while (this.data.size() > maxSize) {
      this.data.remove(0);
    }
  }
  
  void plot (int x, int y, int w, int h, float minData, float maxData) {

    for (int i = 0; i < maxSize; i++) {
      if (i < this.data.size()) {
        for (int j = 0; j < this.data.get(i).size(); j++) {
          float d = this.data.get(i).get(j);
          noStroke();
          fill((d - minData) / (maxData - minData) * 255);
          //rect(
          //  x + i * w / maxSize, 
          //  y + h - j * h / this.data.get(i).size(), 
          //  w / maxSize,
          //  h / this.data.get(i).size());
          rect(
            x + j * w / this.data.get(i).size(), 
            y + h - i * h / maxSize, 
            w / this.data.get(i).size(),
            h / maxSize);
        }          
      }
    }
  }
  
  void plot (int x, int y, int w, int h) {
    
    float maxData = 0;
    float minData = 99999;
    for (int i = 0; i < this.data.size(); i++) {
      for (int j = 0; j < this.data.get(i).size(); j++) {
        float d = this.data.get(i).get(j);
        if (d > maxData)
          maxData = d;
        if (d < minData)
          minData = d;
      }
    }
    
    print(minData);
    print(" ");
    print(maxData);
    plot(x, y, w, h, minData, maxData);
  }
}
