// https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson6

# version 330 core

# define FALLOFF vec3(0.2, 20.0, 100.0)
# define HEIGHT -0.05

uniform sampler2D Texture;

uniform int ScreenWidth;
uniform int ScreenHeight;

// OpenGL-биндинги не поддерживают uniform buffers и glUniform{x}fv-функции, так
// что делаем вот так вот
uniform vec2 light1_tile_position;
uniform vec2 light2_tile_position;
uniform vec2 light3_tile_position;
uniform vec2 light4_tile_position;
uniform vec2 light5_tile_position;
uniform vec2 light6_tile_position;
uniform vec2 light7_tile_position;
uniform vec2 light8_tile_position;
uniform vec2 light9_tile_position;
uniform vec2 light10_tile_position;

uniform int count;

uniform vec4 light_color;
uniform vec4 ambient_color;
uniform int game_width;
uniform int game_height;

out vec4 color;

mat3 rotateZ(float angle) {
  return mat3(
    cos(angle), sin(angle), 0.0,
    -sin(angle), cos(angle), 0.0,
    0.0, 0.0, 1.0
  );
}

// https://jameshfisher.com/2017/10/18/generated-normal-map/
vec3 normal_map_of_tile(vec2 tile_coordinates) {
  vec2 middle_coordinates = tile_coordinates + vec2(0.5, 0.5);
  float angle = atan(middle_coordinates.y, middle_coordinates.x);
  vec3 normal = rotateZ(angle) * normalize(vec3(1.0, 0.0, 0.0));
  return normal;
}

vec3 dynamic_normal_map(vec2 texture_coordinates) {
  return normal_map_of_tile(fract(texture_coordinates * vec2(game_width, game_height)));
}

void main(void) {
  vec2 texture_coordinates = gl_FragCoord.xy / vec2(ScreenWidth, ScreenHeight);

  if (count == 0) {
    color = texture(Texture, texture_coordinates);
    return;
  }

  vec4 diffuse_color = texture(Texture, texture_coordinates);
  vec3 normal_map = dynamic_normal_map(texture_coordinates);
  vec3 ambient = ambient_color.rgb * ambient_color.a;

  vec2 lights[10] = vec2[10](light1_tile_position, light2_tile_position, light3_tile_position, light4_tile_position, light5_tile_position,
    light6_tile_position, light7_tile_position, light8_tile_position, light9_tile_position, light10_tile_position);

  // Обрабатываем только ближайший источник
  vec3 light_directions[10];
  float light_distances[10];
  int selected_light = 0;
  float min_distance = 999;
  for (int i = 0; i < count; i++) {
    vec3 light_position = vec3((lights[i] + 0.5) / vec2(game_width, game_height), HEIGHT);
    light_directions[i] = vec3(light_position.xy - texture_coordinates, light_position.z);
    light_distances[i] = length(light_directions[i]);
    if (light_distances[i] < min_distance) {
      selected_light = i;
      min_distance = light_distances[i];
    }
  }

  vec3 light_direction = light_directions[selected_light];
  float d = length(light_direction);
  vec3 n = normalize(normal_map * 2.0 - 1.0);
  vec3 l = normalize(light_direction);

  vec3 diffuse = (light_color.rgb * light_color.a) * max(dot(n, l), 0.0);
  float attenuation = 1.0 / (FALLOFF.x + (FALLOFF.y * d) + (FALLOFF.z * d * d));

  vec3 intensity = ambient + diffuse * attenuation;
  vec3 final_color = diffuse_color.rgb * intensity;

  color = vec4(final_color, diffuse_color.a);
}
