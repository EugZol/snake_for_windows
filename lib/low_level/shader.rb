# https://www.libgosu.org/cgi-bin/mwf/topic_show.pl?tid=236

require 'gl'

class Shader
  include Gl

  QUAD_SHADER_FILE = "#{__dir__}/quad.glsl"

  attr_reader :window, :shader_filename
  attr_reader :program_id, :vertex_shader_id, :fragment_shader_id

  @@canvas_texture_id = nil

  def initialize(window, shader_filename)
    @window = window
    @shader_filename = shader_filename

    @program_id = nil
    @vertex_shader_id = nil
    @fragment_shader_id = nil

    create_canvas unless @@canvas_texture_id
    compile
  end

  def apply
    @window.gl do
      # copy frame buffer to canvas texture
      glBindTexture(GL_TEXTURE_2D, @@canvas_texture_id)
      glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 0, @window.width, @window.height, 0)

      # apply shader
      glUseProgram(@program_id)

      # draw processed canvas texture over the screen
      glBindTexture(GL_TEXTURE_2D, @@canvas_texture_id)

      # Для совместимости с некоторыми драйверами задаём произвольный вершинный атрибут
      # https://community.khronos.org/t/draw-with-fragment-shader-without-vertices/70964
      glVertexAttrib1f(0, 0);

      # В vertex-шейдере quad.glsl рисуем квадрат во весь экран, здесь четыре произвольных точки
      glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

      # done, disable shader
      glUseProgram(0)
    end
  end

  def uniform(name, value)
    glUseProgram(@program_id)

    location = glGetUniformLocation(@program_id, name)
    return false unless location >= 0

    case value
    when Float
      glUniform1f(location, value)
    when Integer
      glUniform1i(location, value)
    when true, false
      glUniform1i(location, value ? 1 : 0)
    when Array # vec2, vec4, vec4
      case value.length
      when 2
        glUniform2f(location, *value)
      when 3
        glUniform3f(location, *value)
      when 4
        glUniform4f(location, *value)
      end
    else
      raise ArgumentError, "Uniform data type not supported"
    end

    glUseProgram(0)
  end

  alias []= uniform

  private

  def create_canvas
    @@canvas_texture_id = glGenTextures(1).first
    glBindTexture(GL_TEXTURE_2D, @@canvas_texture_id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    return @@canvas_texture_id
  end

  def compile
    # create program
    @program_id = glCreateProgram

    # create vertex shader
    @vertex_shader_id = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(@vertex_shader_id, File.read(QUAD_SHADER_FILE))
    glCompileShader(@vertex_shader_id)
    glAttachShader(@program_id, @vertex_shader_id)

    # create fragment shader
    @fragment_shader_id = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(@fragment_shader_id, File.read(@shader_filename))
    glCompileShader(@fragment_shader_id)
    glAttachShader(@program_id, @fragment_shader_id)

    # compile program
    glLinkProgram(@program_id)

    # check for compile errors
    unless glGetProgramiv(@program_id, GL_LINK_STATUS) == GL_TRUE
      raise glGetProgramInfoLog(@program_id).chomp
    end

    uniform("ScreenWidth", @window.width)
    uniform("ScreenHeight", @window.height)

    return @program_id
  end
end
