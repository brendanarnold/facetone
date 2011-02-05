
class WSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  WSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) {
    int high = 1;
    for (int i=0; i < samp.length; i++) {
      int lambda = int(2048 / this.freq);
      if (i % lambda == 0) high *= -1;
      if (high < 0) {
        samp[i] = vol; 
      } else {
        samp[i] = 0;
      }
    }
  }
  // this is a stricly mono signal
  void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
