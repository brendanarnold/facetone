
class GammaSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  int phase = 0;
  
  GammaSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) {
    float high = this.vol;
    int theta = 0;
    int inter = int(out.sampleRate() / this.freq);
    for (int i=0; i < samp.length; i++) {
      theta = (i + this.phase) % inter;
      if (theta == 0) {
        high *= -1;
      }
      samp[i] = samp[i] + high;
    }
    this.phase = theta;
  }
  // this is a stricly mono signal
  void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
