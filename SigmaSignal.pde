
class SigmaSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  int phase = 0;
  
  SigmaSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) {
    int inter = int(out.sampleRate() / this.freq);
    int theta = 0;
    for ( int i = 0; i < samp.length; i += inter )
    {
      for ( int j = 0; j < inter && (i+j) < samp.length; j++ )
      {
        theta = (j + this.phase) % inter;
        samp[i + j] = samp[i + j] + map(theta, 0, inter, -this.vol, this.vol);
      }
    
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
