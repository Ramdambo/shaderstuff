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

//float2 enable(

void main(void)
{
	vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
	uv -= 0.5;
  
	uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv *= vec2(sin(fGlobalTime * 0.2) * 2 + 3, sin(fGlobalTime * 0.2) * 2 + 3);
  
  vec4 texLow = texture ( texFFTIntegrated, 0.02);
  vec4 texHigh = texture ( texFFTIntegrated, 0.99);
  
  uv.x += sin(texHigh.r * 0.01 * fGlobalTime * 0.5) * 0.1;
  uv.y += cos(texLow.r * 0.01) * 0.1;
  
  vec2 m;
	m.x = atan(sin(uv.x) / uv.y) / 3.14; //* sin( fGlobalTime * 0.1);
	m.y = length(uv) + clamp(texLow.r, 0, 1) * max(sin (fGlobalTime * 0.1) * 0.1, 0.0) * cos(fGlobalTime * 0.1 ) * 10;
  
	float d = sin(m.x) * sin(m.x) * sin(texLow.r) * 2 + cos(m.y) * cos(m.y) * cos(texLow.r) * 4;
  
	float f = texture(texFFT, d * clamp(sin(texLow.r * 0.5), 0.5, 3)).r;
  float g = texture(texFFTSmoothed, d).r;
  
  vec4 col = vec4 (sin(f) * 100, sin(f) * 50, atan(f) * 0.1, 0.0);
  vec4 col2 = vec4 (sin(g) * 100, texHigh.r, texHigh.r * 0.5, 0);
  
  m.x += texLow.r * texHigh.r * 0.01;
  m.y += texLow.r;
  m.y += fGlobalTime * 0.1;
  
	vec4 t = texture(texComplex, m.xy);
  vec4 t2 = texture(texWall, m.xy);
  
  m.x = atan(sin(uv.x) / uv.y) / 3.14 * sin( fGlobalTime * 0.1);
	m.y = length(uv) + clamp(texLow.r, 0, 1) * max(sin (fGlobalTime * 0.1) * 0.1, 0.0) * cos(fGlobalTime * 0.1 ) * 10;
  vec4 old = texture(texPreviousFrame, m.xy);
  
	out_color = (col + t * col2 + col2 * t2 * (old - col) / clamp(3*cos(fGlobalTime), 2, 3.0));
  //out_color = t;
}
