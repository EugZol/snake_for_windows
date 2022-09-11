# version 330 core

uniform sampler2D Texture;

uniform int ScreenWidth;
uniform int ScreenHeight;

uniform int Width;
uniform int Height;

out vec4 color;

void main(void)
{
  float x = float(gl_FragCoord.x) * float(Width) / float(ScreenWidth);
  float y = (float(gl_FragCoord.y) + ScreenHeight - Height) * float(Height) / float(ScreenHeight);
  color = texture(Texture, vec2(x, y) / vec2(ScreenWidth, ScreenHeight));
}
