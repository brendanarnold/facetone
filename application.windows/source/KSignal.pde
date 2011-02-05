class KSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  KSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) {
    int high = 1;
    float lambda = int(2048 / this.freq);
    for (int i=0; i < samp.length; i++) {
      samp[i] = vol*sin(TWO_PI * i / lambda);
    }
  }
  // this is a stricly mono signal
  void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
