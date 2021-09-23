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
 
// Constants
#define PI 3.1415925359
//#define TWO_PI 6.2831852
#define MAX_STEPS 200 // Mar Raymarching steps
#define MAX_DIST 20. // Max Raymarching distance
#define SURF_DIST 0.1 // Surface Distance
 
///////////////////////
// Boolean Operators
///////////////////////
 
float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}
 
float unionSDF(float distA, float distB) {
    return min(distA, distB);
}
 
float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = v2Resolution.x/freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p, f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

float GetDist(vec3 p) 
{
  float planeDist = p.y + noise(p.xz, 1000) + noise(p.xz, 2000) + 0.2 * noise(p.xz, 4000);
  return planeDist;
}
 
float RayMarch(vec3 ro, vec3 rd) 
{ 
  float dO = 0.; //Distane Origin
  for(int i=0;i<MAX_STEPS;i++)
  {
    vec3 p = ro + rd * dO;
    float ds = GetDist(p); // ds is Distance Scene
    dO += ds;
    if (ds < SURF_DIST || ds > MAX_DIST) 
      break;
  }
  return dO;
}

vec3 GetNormal(vec3 p) {
  return vec3(0, 1, 0);
}
 
float GetLight(vec3 p)
{ 
    // Directional light
    vec3 lightPos = vec3(0, 10, fGlobalTime); // Light Position
    vec3 l = normalize(lightPos-p); // Light Vector
    vec3 n = GetNormal(p); // Normal Vector
   
    float dif = dot(n,l); // Diffuse light
    dif = clamp(dif,0.,1.); // Clamp so it doesnt go below 0
   
    // Shadows
    float d = RayMarch(p+n*SURF_DIST*2., l); 
     
    if(d<length(lightPos-p)) dif *= .1;
 
    return dif + 0.2;
}
 
void main()
{
    vec2 uv = (gl_FragCoord.xy-.5*v2Resolution.xy)/v2Resolution.y;
     
    vec3 ro = vec3(0,1,fGlobalTime); // Ray Origin/Camera
    vec3 rd = normalize(vec3(uv.x,uv.y,1)); // Ray Direction
   
    float d = RayMarch(ro,rd); // Distance

    vec3 p = ro + rd * d;
    float dif = GetLight(p); // Diffuse lighting
    d*= .2;
    vec3 color = vec3(dif);
    //color += GetNormal(p);
    //float color = GetLight(p);
 
    // Set the output color

    out_color = vec4(color,1.0);
}