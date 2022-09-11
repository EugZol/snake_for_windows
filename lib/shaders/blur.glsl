uniform sampler2D Texture;

uniform int ScreenWidth;
uniform int ScreenHeight;

uniform float BlurFactor;
uniform float BrightFactor;

uniform float origin_x;
uniform float origin_y;

uniform int passes;

void main(void)
{
  vec2 Origin = vec2(origin_x, 1.0 - origin_y);

  vec2 TexCoord = gl_FragCoord / vec2(float(ScreenWidth), float(ScreenHeight));

  vec4 SumColor = vec4(0.0, 0.0, 0.0, 0.0);
  TexCoord -= Origin;

  for (int i = 0; i < passes; i++)
  {
    float scale = 1.0 - BlurFactor * (float(i) / float(passes - 1));
    SumColor += texture2D(Texture, TexCoord * scale + Origin);
  }

  gl_FragColor = SumColor / float(passes) * BrightFactor;
}
