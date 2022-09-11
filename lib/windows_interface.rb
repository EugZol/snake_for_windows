require 'gosu'

require_relative 'low_level/shader'
require_relative 'low_level/utils'

class WindowsInterface < Gosu::Window
  attr_reader :width, :height

  WINDOW_WIDTH = 1024
  WINDOW_HEIGHT = 768

  TICK_LENGTH = 1 # длина тика, миллисекунд

  # alpha, r, g, b
  APPLE_COLOR = 0xFFA82D43
  SNAKE_COLOR = 0xFF060000
  NONE_COLOR = 0xFF657A6E
  BACKGROUND_COLOR = 0xFF9EAEA5

  APPLE_LIGHTING_COLOR = 0xFF875459

  def initialize(game)
    @game = game
    @width = WINDOW_WIDTH
    @height = WINDOW_HEIGHT

    super(@width, @height, update_interval: TICK_LENGTH)
    self.caption = "Snake – Хороший программист / eugzol@goodprogrammer.ru"

    # Шейдеры для отладки
    #
    # @identity_shader = Shader.new(self, "#{__dir__}/shaders/identity.glsl")
    #
    # @blur_shader = Shader.new(self, "#{__dir__}/shaders/blur.glsl")
    # @blur_shader['BlurFactor'] = 0.15
    # @blur_shader['BrightFactor'] = 1.0
    # @blur_shader['origin_x'] = 0.5
    # @blur_shader['origin_y'] = 0.5
    # @blur_shader['passes'] = 16

    # Шейдер для подсвечивания яблок
    @light_shader = Shader.new(self, "#{__dir__}/shaders/light.glsl")
    @light_shader['light_color'] = Utils.color_to_vec4 APPLE_COLOR #(APPLE_LIGHTING_COLOR)
    @light_shader['game_width'] = @game.width
    @light_shader['game_height'] = @game.height
    @light_shader['ambient_color'] = Utils.color_to_vec4(NONE_COLOR)
    @light_shader['count'] = 0

    # Шейдер для убирания чёрных полос из-за того, что размер экрана не делится нацело на размер поля
    @stretch_shader = Shader.new(self, "#{__dir__}/shaders/stretch.glsl")
    @stretch_shader['Width'] = tile_width * @game.width
    @stretch_shader['Height'] = tile_height * @game.height

    # Шейдер для рисования ЭЛТ-монитора
    @crt_shader = Shader.new(self, "#{__dir__}/shaders/crt.glsl")
    @lights_on = true
    @crt_shader['LightsOn'] = @lights_on
    @crt_shader['PhosphorColor'] = Utils.color_to_vec4(NONE_COLOR)

    @big_font = Gosu::Font.new((@height.to_f / 5).round, name: "#{__dir__}/../assets/lucon.ttf")
    @small_font = Gosu::Font.new((@height.to_f / 10).round, name: "#{__dir__}/../assets/lucon.ttf")

    @tick_sound = Gosu::Sample.new("#{__dir__}/../assets/tick.ogg")
    @apple_sound = Gosu::Sample.new("#{__dir__}/../assets/apple.ogg")
    @game_over_sound = Gosu::Sample.new("#{__dir__}/../assets/game_over.ogg")

    @start_up_song = Gosu::Song.new("#{__dir__}/../assets/start_up.ogg")
    @start_up_song.volume = 0.1
    @main_song = Gosu::Song.new("#{__dir__}/../assets/main.ogg")
    @main_song.volume = 0.1
    @shut_down_song = Gosu::Song.new("#{__dir__}/../assets/shut_down.ogg")
    @shut_down_song.volume = 0.1

    @scheduled_update = Gosu.milliseconds + TICK_LENGTH
  end

  def update
    return super unless Gosu.milliseconds > @scheduled_update
    @scheduled_update = Gosu.milliseconds + 300

    if @will_shut_down
      close if Gosu.milliseconds > @will_shut_down
    end

    unless @game.over? || @will_shut_down
      @tick_sound.play(0.02)

      @game.step!(@direction)
      @direction = nil

      if @game.just_ate_apple?
        @apple_sound.play(0.02)
      end
    end
  end

  def draw
    update_song

    @game.width.times do |x|
      @game.height.times do |y|
        draw_tile(x, @game.height - y - 1, @game.cell_type([x, y]))
      end
    end

    update_lighting

    @stretch_shader.apply

    if @game.over?
      @big_font.draw_text_rel("GAME OVER", @width * 0.5, @height * 0.3, 1.0, 0.5, 0.5)
      @big_font.draw_text_rel("SCORE: #{@game.score}", @width * 0.5, @height * 0.5, 1.0, 0.5, 0.5)
      @small_font.draw_text_rel("Esc – exit", @width * 0.5, @height * 0.7, 1.0, 0.5, 0.5)
      @small_font.draw_text_rel("Enter – restart", @width * 0.5, @height * 0.8, 1.0, 0.5, 0.5)
    end

    @light_shader.apply
    @crt_shader.apply
  end

  def button_down(id)
    direction = key_to_direction(id)
    if direction
      @direction = direction
    elsif id == Gosu::KB_SPACE
      @lights_on = !@lights_on
      @crt_shader['LightsOn'] = @lights_on
    elsif id == Gosu::KB_ESCAPE
      @will_shut_down = Gosu.milliseconds + 2_000
    elsif [Gosu::KB_ENTER, Gosu::KB_RETURN].include?(id)
      @game = Game.new
      @game_over_sound_played = false
    end
  end

  private

  def draw_tile(x, y, kind)
    fg_color =
      case kind
      when :empty
        NONE_COLOR
      when :snake
        SNAKE_COLOR
      when :apple
        APPLE_COLOR
      end
    Gosu.draw_rect(x * tile_width, y * tile_height, tile_width, tile_height, fg_color)
    Gosu.draw_rect(x * tile_width + frame_width, y * tile_height + frame_height,
      tile_width - 2 * frame_width, tile_height - 2 * frame_height, BACKGROUND_COLOR)
    Gosu.draw_rect(x * tile_width + 2 * frame_width, y * tile_height + 2 * frame_height,
      tile_width - 4 * frame_width, tile_height - 4 * frame_height, fg_color)
  end

  def frame_width
    (0.1 * tile_width).floor
  end

  def frame_height
    (0.1 * tile_height).floor
  end

  def key_to_direction(id)
    case id
    when Gosu::KB_A
      :left
    when Gosu::KB_D
      :right
    when Gosu::KB_W
      :up
    when Gosu::KB_S
      :down
    # else nil
    end
  end

  def ten_apples
    (0..9).map { |i| @game.apples[i] || [-1, -1] }
  end

  def tile_width
    [@width.to_f / @game.width, @height.to_f / @game.height].map(&:floor).min
  end

  def tile_height
    [@width.to_f / @game.width, @height.to_f / @game.height].map(&:floor).min
  end

  def update_lighting
    @light_shader['count'] = @game.apples.length
    @game.apples.each.with_index(1) { |apple, i| @light_shader["light#{i}_tile_position"] = apple }
  end

  def update_song
    if @game.over? && !@game_over_sound_played
      @game_over_sound.play(0.01)
      @game_over_sound_played = true
    end

    if !@start_up_song_played
      @start_up_song.play
      @start_up_song_played = true
    end

    if !@start_up_song.playing? && !@main_song.playing? && !@shut_down_song.playing?
      @main_song.play(true)
    end

    if @will_shut_down && !@shut_down_song.playing?
      @shut_down_song.play
    end
  end
end
