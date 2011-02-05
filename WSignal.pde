class WSignal implements AudioSignal {
  float freq = 0;
  float vol = 0; // Between 0 and 1
  float phase = 0.0;
  
  WSignal(float freq, float vol) {
    this.freq = freq;
    this.vol = vol;
  }
  
  void generate(float[] samp) 
  {
    float theta = 0.0;
    //int inter = int(44100 / this.freq);
    int inter = int(out.sampleRate() / this.freq);
    for (int i=0; i < samp.length; i++) {
      theta = (i % inter) * TWO_PI / inter;
      samp[i] = samp[i] + vol * sin(theta + this.phase);
    }
    this.phase += theta;
    while (this.phase > TWO_PI) {
      this.phase -= TWO_PI;
    }
    //println("Phase=" + this.phase);
  }
  
  // this is a stricly mono signal
  void generate(float[] left, float[] right)
  {
    generate(left);
    generate(right);
  }
}
