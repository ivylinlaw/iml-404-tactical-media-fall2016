/*
Reference:
  https://forum.processing.org/one/topic/minim-how-to-use-the-sound-frequency-information-to-transform-it-into-colors-processing-beginner.html
  https://github.com/shiffman/OpenKinect-for-Processing (Daniel Shiffman, Kinect Point Cloud example)
  https://soundcloud.com/giraffage/music-sounds-better-with-you
*/
 
import org.openkinect.freenect.*;
import org.openkinect.processing.*;
import ddf.minim.*;

AudioPlayer player;
Minim minim;

// Kinect Library object
Kinect kinect;

// Angle for rotation
// float a = 0.0;

float s = 0.0;

//color c = color(0, random(0, 125), random(0, 125));

//depth filtering
float depthNear = 0;
float depthFar = 800;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

void setup() {
  // Rendering in P3D
  size(1024, 728, P3D); 
  
  kinect = new Kinect(this);
  kinect.initDepth();

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
  
  // audio
  minim = new Minim(this);
  player = minim.loadFile("soundcloud.mp3", 2048);
  player.play();
  player.loop(); 
}

void draw() {

  background(0);
  
  stroke(255, 255, 255, 125);
  for(int i=0; i<height; i+=height/10){
    for (int j = 0; j < player.left.size()-1; j+=5) {
      line(j, i + player.right.get(j)*50, j+1, i + player.right.get(j+1)*50);
    }
  }
  
  float freq_sum = 0;
  for (int i = 0; i < player.left.size(); i++) {
    freq_sum += 100 + player.left.get(i)*50;
  }
  
  float freq_avg =freq_sum / player.left.size();
  //println("avg = "+avg);

  // Get the raw depth as array of integers
  int[] depth = kinect.getRawDepth();

  // We're just going to calculate and draw every skip-th pixel (equivalent of 160x120)
  int skip = 6;

  // Translate
  translate(width/2, height/2, -50);
  
  // Nested for loop that initializes x and y pixels and, for those less than the
  // maximum threshold and at every skiping point, the offset is caculated to map
  // them on a plane instead of just a line
  ArrayList<Float> points = new ArrayList<Float>();
  
 for (int y = 0; y < kinect.height; y += skip) {
  for (int x = 0; x < kinect.width; x += skip) {
    //for (int y = 0; y < kinect.height; y += skip) {
      int offset = x + y*kinect.width;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      
      if(rawDepth >= depthNear && rawDepth <= depthFar){
        PVector v = depthToWorld(x, y, rawDepth);
  
        stroke(255);
        pushMatrix();
        
        // Scale up
        float factor = 900;
        
        float x2 = v.x*factor;
        float y2 = v.y*factor;
        float z2 = factor-v.z*factor;
        
        points.add(x2);
        points.add(y2);
        points.add(z2);
        
        //translate(v.x*factor, v.y*factor, factor-v.z*factor);
        
        popMatrix();
      }
    }
  }

  s = abs(cos(freq_avg)*1.2);
  println("s = "+s);
  
  scale(s);
  stroke(0, random(0, 125), random(0, 125));
  for(int i=0; i<points.size(); i+=3) {
    for(int j=0; j<points.size(); j+=3) {
      float dis = dist(points.get(i), points.get(i+1), points.get(j), points.get(j+1));
      if(dis > 6  && dis < 12) {
        line(points.get(i), points.get(i+1), points.get(i+2), points.get(j), points.get(j+1), points.get(j+2));
        //line(points.get(i), points.get(i+1), points.get(j), points.get(j+1));
      }
    }
  }
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

// Only needed to make sense of the ouput depth values from the kinect
PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

// Drawing the result vector to give each point its three-dimensional space
  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}

void stop(){
  player.close();
  minim.stop(); 
  super.stop();
}