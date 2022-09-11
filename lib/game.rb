class Game
  WIDTH = 30
  HEIGHT = 30

  attr_reader :snake, :apples, :score

  def initialize
    @snake = [[0, 0]] # голова - первым элементом
    @direction = :up
    @apples = []

    @score = 0
    @over = false
    @tick = 0

    generate_apple_if_needed
  end

  def just_ate_apple?
    @just_ate_apple
  end

  # direction: :up | :down | :left | :right | nil
  def step!(new_direction)
    @just_ate_apple = false

    return if @over

    @tick += 1

    if new_direction && !opposite_directions?(@direction, new_direction)
      @direction = new_direction
    end

    new_head_position = next_cell(@snake[0], @direction)

    case cell_type(new_head_position)
    when :snake
      @over = true
      return
    when :apple
      @just_ate_apple = true
      @snake.unshift(new_head_position)
      @apples.delete(new_head_position)
      @score += 1
    when :empty
      @snake.unshift(new_head_position)
      @snake.pop
    end

    generate_apple_if_needed
  end

  def over?
    @over
  end

  def cell_type(cell)
    if @snake.include?(cell)
      :snake
    elsif @apples.include?(cell)
      :apple
    else
      :empty
    end
  end

  def width
    WIDTH
  end

  def height
    HEIGHT
  end

  private

  def opposite_directions?(first, second)
    directions = [first, second].sort
    directions == [:down, :up] || directions == [:left, :right]
  end

  def next_cell(current_cell, direction)
    x, y = current_cell

    result =
      case direction
      when :up
        [x, y + 1]
      when :down
        [x, y - 1]
      when :left
        [x - 1, y]
      when :right
        [x + 1, y]
      end

    result[0] = 0 if result[0] == WIDTH
    result[0] = WIDTH - 1 if result[0] == -1
    result[1] = 0 if result[1] == HEIGHT
    result[1] = HEIGHT - 1 if result[1] == -1

    result
  end

  def generate_apple_if_needed
    should_generate_apple =
      @tick % 10 == 0 && # каждый 10-й такт
      @apples.length < 10 && # не более 10 яблок
      (@snake.length + @apples.length) < WIDTH * HEIGHT # есть свободные клетки
    return unless should_generate_apple

    # номер свободной клетки, если все нумеровать по порядку
    n = rand(1..(WIDTH * HEIGHT - @snake.length - @apples.length))

    (0..WIDTH - 1).each do |x|
      (0..HEIGHT - 1).each do |y|
        if n == 0
          @apples << [x, y]
          return
        end

        if cell_type([x, y]) == :empty
          n -= 1
        end
      end
    end
  end
end
