// https://www.shadertoy.com/view/XdtfzX
# version 330 core

#define WIDTH 0.47
#define HEIGHT 0.3
#define CURVE 3.5
#define SMOOTH 0.004
#define SHINE 0.4

#define BEZEL_COL vec4(0.8, 0.8, 0.6, 0.0)

#define REFLECTION_BLUR_ITERATIONS 5
#define REFLECTION_BLUR_SIZE 0.04

uniform sampler2D Texture;

uniform int ScreenWidth;
uniform int ScreenHeight;

uniform bool LightsOn;
uniform vec4 PhosphorColor;

out vec4 color;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 CurvedSurface(vec2 uv, float r)
{
  return r * uv/sqrt(r * r - dot(uv, uv));
}

vec2 crtCurve(vec2 uv, float r, bool content, bool shine)
{
  r = CURVE * r;
  uv = (uv / vec2(float(ScreenWidth), float(ScreenHeight)) - 0.5) / vec2(float(ScreenHeight)/float(ScreenWidth), 1.) * 2.0;
  uv = CurvedSurface(uv, r);
  if(content) uv *= 0.5 / vec2(WIDTH, HEIGHT);
  uv = (uv / 2.0) + 0.5;

  return uv;
}

float roundSquare(vec2 p, vec2 b, float r)
{
  return length(max(abs(p)-b,0.0))-r;
}

// standard roundSquare
float stdRS(vec2 uv, float r)
{
  return roundSquare(uv - 0.5, vec2(WIDTH, HEIGHT) + r, 0.05);
}

// Calculate normal to distance function and move along
// normal with distance to get point of reflection
vec2 borderReflect(vec2 p, float r)
{
  float eps = 0.0001;
  vec2 epsx = vec2(eps,0.0);
  vec2 epsy = vec2(0.0,eps);
  vec2 b = (1.+vec2(r,r))* 0.5;
  r /= 3.0;

  p -= 0.5;
  vec2 normal = vec2(roundSquare(p-epsx,b,r)-roundSquare(p+epsx,b,r),
                     roundSquare(p-epsy,b,r)-roundSquare(p+epsy,b,r))/eps;
  float d = roundSquare(p, b, r);
  p += 0.5;
  return p + d*normal;
}

void main(void)
{
  vec4 c = vec4(0.0, 0.0, 0.0, 0.0);
  vec2 fragCoord = gl_FragCoord.xy;

  vec2 uvC = crtCurve(fragCoord, 1., true, false);     // Content Layer
  vec2 uvS = crtCurve(fragCoord, 1., false, false);    // Screen Layer
  vec2 uvE = crtCurve(fragCoord, 1.25, false, false);    // Enclosure Layer

  if (LightsOn) {
    // From my shader https://www.shadertoy.com/view/MtBXW3

    const float ambient = 0.33;

    // Glass Shine
    vec2 uvSh = crtCurve(fragCoord, 1., false, true);
    c += max(0.0, SHINE - distance(uvSh, vec2(0.5, 1.0))) *
        smoothstep(SMOOTH/2.0, -SMOOTH/2.0, stdRS(uvS + vec2(0., 0.03), 0.0));

    // Ambient
    c += max(0.0, ambient - 0.5*distance(uvS, vec2(0.5,0.5))) *
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvS, 0.0));

    // Enclosure Layer
    uvSh = crtCurve(fragCoord, 1.25, false, true);
    vec4 b = vec4(0., 0., 0., 0.);
    for(int i=0; i<12; i++)
        b += (clamp(BEZEL_COL + rand(uvSh+float(i))*0.05-0.025, 0., 1.) +
            rand(uvE+1.0+float(i))*0.25 * cos((uvSh.x-0.5)*3.1415*1.5))/12.;

    // Inner Border
    const float HHW = 0.5 * HEIGHT/WIDTH;

    c += b/3.*( 1. + smoothstep(HHW - 0.025, HHW + 0.025, abs(atan(uvS.x-0.5, uvS.y-0.5))/3.1415)
            + smoothstep(HHW + 0.025, HHW - 0.025, abs(atan(uvS.x-0.5, 0.5-uvS.y))/3.1415) )*
        smoothstep(-SMOOTH, SMOOTH, stdRS(uvS, 0.0)) *
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvE, 0.05));

    // Inner Border Shine
      c += (b - 0.4)*
        smoothstep(-SMOOTH*2.0, SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.505), vec2(WIDTH, HEIGHT) + 0.05, 0.05)) *
        smoothstep(SMOOTH*2.0, -SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.495), vec2(WIDTH, HEIGHT) + 0.05, 0.05));

    // Outer Border
    c += b *
        smoothstep(-SMOOTH, SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.05, 0.05)) *
        smoothstep(SMOOTH, -SMOOTH, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.15, 0.05));

    // Outer Border Shine
    c += (b - 0.4)*
        smoothstep(-SMOOTH*2.0, SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.495), vec2(WIDTH, HEIGHT) + 0.15, 0.05)) *
        smoothstep(SMOOTH*2.0, -SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.505), vec2(WIDTH, HEIGHT) + 0.15, 0.05));

    // Table and room
    c += max(0. , (1. - 2.0* fragCoord.y/float(ScreenHeight))) * vec4(1, 1, 1, 0.) *
        smoothstep(-0.25, 0.25, roundSquare(uvC - vec2(0.5, -0.2), vec2(WIDTH+0.25, HEIGHT-0.15), .1)) *
        smoothstep(-SMOOTH*2.0, SMOOTH*2.0, roundSquare(uvE-vec2(0.5, 0.5), vec2(WIDTH, HEIGHT) + 0.15, 0.05));

  } else {
    // From my shader https://www.shadertoy.com/view/lt2SDK

    const float ambient = 0.2;

    // Ambient
    c += max(0.0, ambient - 0.3*distance(uvS, vec2(0.5,0.5))) *
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvS, 0.0));

    // Inner Border
      c += BEZEL_COL * ambient * 0.7 *
        smoothstep(-SMOOTH, SMOOTH, stdRS(uvS, 0.0)) *
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvE, 0.05));

    // Corner
      c -= (BEZEL_COL )*
        smoothstep(-SMOOTH*2.0, SMOOTH*10.0, stdRS(uvE, 0.05)) *
        smoothstep(SMOOTH*2.0, -SMOOTH*2.0, stdRS(uvE, 0.05));

    // Outer Border
    c += BEZEL_COL * ambient *
            smoothstep(-SMOOTH, SMOOTH, stdRS(uvE, 0.05)) *
        smoothstep(SMOOTH, -SMOOTH, stdRS(uvE, 0.15));

    // Inner Border Reflection
    for(int i = 0; i < REFLECTION_BLUR_ITERATIONS; i++)
    {
        vec2 uvR = borderReflect(uvC + (vec2(rand(uvC+float(i)), rand(uvC+float(i)+0.1))-0.5)*REFLECTION_BLUR_SIZE, 0.05);
        c += (PhosphorColor - BEZEL_COL*ambient) * texture(Texture, uvR) / float(REFLECTION_BLUR_ITERATIONS) *
            smoothstep(-SMOOTH, SMOOTH, stdRS(uvS, 0.0)) *
            smoothstep(SMOOTH, -SMOOTH, stdRS(uvE, 0.05));
    }

    // Bloom using composed MipMaps
    c += (textureLod(Texture, uvC, 3.) +
          textureLod(Texture, uvC, 4.) +
          textureLod(Texture, uvC, 5.))
        * smoothstep(0., -SMOOTH*20., stdRS(uvS, -0.02)) * 0.25;
  }

  if (uvC.x > 0. && uvC.x < 1. && uvC.y > 0. && uvC.y < 1.)
    c += texture(Texture, uvC);

  color = c;
}
