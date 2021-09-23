#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)
uniform float fFrameTime; // duration of the last frame, in seconds

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texPreviousFrame; // screenshot of the previous frame
uniform sampler2D texComplex;
uniform sampler2D texArrows;
uniform sampler2D texWall;
uniform sampler2D texWater;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything


vec2 squareImaginary(vec2 number){
	return vec2(
		pow(number.x,2)-pow(number.y,2),
		2*number.x*number.y
	);
}


float iterateMandelbrot(vec2 coord, vec2 c, float maxIterations){
	vec2 z = coord;
	for(int i=0; i < maxIterations; i++){
		z = squareImaginary(z) + c;
		if ( length(z) > 2 ) return i / maxIterations;
	}
	return maxIterations;
}

vec4 colorScheme(float val, float maxVal) {
  if (val < 0.1) {
    return vec4(0, 0, 0, 0);
  }
  if (val < 0.4) {
    return vec4(0, 0, 1, 0); 
  }
  if (val < 0.6) {
    return vec4(0, 1, 0, 0);
  }
  if (val < 0.8) {
    return vec4(1, 1, 0, 0);
  }
  if (val < 0.9) {
    return vec4(1, 0.5, 0, 0);
  }
  return vec4(1, 0, 0, 0);
}

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, -s, s, c);
	return m * v;
}

void main(void)
{
	
  // Pixel <-> UV coordinates
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  //uv *= 2;
  
  vec2 c = vec2(sin(fGlobalTime * 0.2) * 0.3 + 0.4, cos(fGlobalTime * 0.2) * 0.1 + 0.4);  

	vec2 suck = uv;
	//suck.x += sin(fGlobalTime * 0.5) * 0.1;
  //suck.y += cos(fGlobalTime * 0.5) * 0.1;
	suck.x = sin(suck.x) / cos(suck.y) * 3.14;
	suck.y = length(suck) * max(sin (fGlobalTime * 0.1) * 0.1, 0.0) * cos(fGlobalTime * 0.1 ) * 10;
  
  //float val = iterateMandelbrot(suck.xy, c, 100);
  //vec4 col = colorScheme(val, 100);
  
  vec4 col = texture(texComplex, suck.xy);
  
  out_color = col;
}
