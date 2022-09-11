# См.:
# - https://github.com/gosu/gosu/wiki/Getting-Started-on-Windows
# - https://github.com/gosu/gosu/wiki/Ruby-Tutorial

require_relative 'lib/windows_interface'
require_relative 'lib/game'

game = Game.new
interface = WindowsInterface.new(game)

interface.show
