module Utils
  GL_VIEWPORT = 0x0BA2

  class << self
    def color_to_vec4(color)
      # В Gosu - ARGB и значения 0-255, в GLSL RGBA и значения 0.0-1.0
      # См. также https://apidock.com/ruby/String/unpack
      [color].pack("L>").unpack("C4").rotate.map { |x| x.to_f / 255 }
    end

    def viewport
      Gl.glGetDoublev(GL_VIEWPORT)[2..].map(&:to_i)
    end
  end
end
