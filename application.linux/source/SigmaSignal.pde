
class SigmaSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  
  SigmaSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) {
    float lambda = int(2048 / this.freq);
    for ( int i = 0; i < samp.length; i += lambda )
    {
      for ( int j = 0; j < lambda && (i+j) < samp.length; j++ )
      {
        samp[i + j] = map(j, 0, lambda, -this.vol, this.vol);
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
