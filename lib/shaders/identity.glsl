# version 330 core

uniform sampler2D Texture;
uniform int ScreenWidth;
uniform int ScreenHeight;

out vec4 color;

void main(void)
{
  color = texture(Texture, gl_FragCoord.xy / vec2(ScreenWidth, ScreenHeight));
}
