class Node {
  int x, y;
  String name;
  Node(String name) {
    this.name = name;
  }
  void draw(boolean highlight) {
    pushStyle();
    noStroke();
    color fillCol = color(255, 0, 0);
    if (highlight) fillCol = color(0, 200, 0);
    fill(fillCol);
    ellipse(this.x, this.y, 10, 10);
    text(this.name, this.x + 15, this.y + 15, 0);
    popStyle();
  }
  float getFreq() {
    float freq = map(atan2(this.y, this.x), 0, PI/2, 60, 1500);
    return freq;
  }
  float getVol() {
    float vol = map(sqrt(sq(this.x) + sq(this.y)), 0, sqrt(sq(width) + sq(height)), 0.0, 1.0);
    return vol;
  }
}
