public class Plotter {
  
  int maxSize;
  FloatList data;
  int i = 0;
  float maxData;
  
  Plotter (int maxSize) {
    this.maxSize = maxSize;
    this.data = new FloatList();
  }
  
  void addData (float d) {
    this.data.append(d);
    while (this.data.size() > maxSize) {
      this.data.remove(0);
    }
  }
  
  void plot (int x, int y, int w, int h) {
    float maxData = this.data.max();
    float minData = this.data.min();
    plot(x, y, w, h, minData, maxData);
  }
  
  void plot (int x, int y, int w, int h, float minData, float maxData) {
    for (int i = 0; i < maxSize - 1; i++) {
      float xi = i < this.data.size() ? this.data.get(i) : 0;
      float xi1 = i + 1 < this.data.size() ? this.data.get(i + 1) : 0;
      //line(
      //  x + i * w / maxSize, 
      //  y + h - (xi - minData) * h / (maxData - minData), 
      //  x + (i + 1) * w / maxSize, 
      //  y + h - (xi1 - minData) * h / (maxData - minData));
      line(
        x + (xi - minData) * w / (maxData - minData), 
        y + h - i * h / maxSize, 
        x + (xi1 - minData) * w / (maxData - minData), 
        y + h - (i + 1) * h / maxSize);
    }
  }
}
