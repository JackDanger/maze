
class Maze

  attr_accessor :width, :height,
                :grid,
                :origin, :finish

  def initialize width, height
    @width, @height = width, height
    @grid = Array.new(width) { Array.new(height) }
    (0...width).each do |column|
      (0...height).each do |row|
        grid[column][row] = Cell.new column, row
      end
    end
    select_openings
    explore origin
    finish.walls[outlet_from(finish.x, finish.y)] = false
    origin.walls[outlet_from(origin.x, origin.y)] = false
  end

  def to_html
    out header
    out '<table>'
    (0...height).each do |y|
      out '<tr>'
      (0...width).each do |x|
        out grid[x][y].to_html
      end
      out '</tr>'
    end
    out '</table>'
    out '</body></html>'
    out
  end

  protected

    def out string = nil
      @out ||= ''
      @out << string if string
      @out
    end

    def header
      <<-EOCSS
      <html><style>
        table, tr, td {
          font-size: 10px;
          padding:0; margin:0; border-spacing: 0
        }
        td { border: 1px solid #FFF; width: 10px; height: 10px;
             text-align: center; vertical-align: center; }
        td span   { display: none }
        td.top    { border-top-color:    #666 }
        td.right  { border-right-color:  #666 }
        td.bottom { border-bottom-color: #666 }
        td.left   { border-left-color:   #666 }
      </style><body>
      EOCSS
    end

    def possible_openings
      [
        [0,           rand(height)],
        [width-1,     rand(height)],
        [rand(width), 0           ],
        [rand(width), height-1    ]
      ]
    end

    def select_openings
      doorways = possible_openings.shuffle[0..1]
      raise "Let's get better openings" if doorways.first == doorways.last
      @origin = grid[doorways[0][0]][doorways[0][1]]
      @finish = grid[doorways[1][0]][doorways[1][1]]
    rescue
      retry
    end

    def outlet_from x, y
      return :left   if x == 0
      return :right  if x == width-1
      return :top    if y == 0
      return :bottom if y == height-1
    end

    def explore cell
      neighbors cell do |neighbor|
        unless neighbor.discovered?
          neighbor.discover_from! cell
          explore neighbor
        end
      end
    end

    def neighbor_top cell
      yield grid[cell.x][cell.y-1] if cell.y > 0
    end

    def neighbor_right cell
      yield grid[cell.x+1][cell.y] if cell.x < width-1
    end

    def neighbor_bottom cell
      yield grid[cell.x][cell.y+1] if cell.y < height-1
    end

    def neighbor_left cell
      yield grid[cell.x-1][cell.y] if cell.x > 0
    end

    def neighbors cell, &block
      [:neighbor_top,
       :neighbor_right,
       :neighbor_bottom,
       :neighbor_left
      ].shuffle.each do |neighbor|
        send neighbor, cell, &block
      end
    end

  class Cell
    attr_accessor :walls, :x, :y

    def self.count; @count ||= 0; end
    def self.count= val; @count = val; end

    def initialize x, y
      @x, @y = x, y
      @walls = {:top    => true,
                :right  => true,
                :bottom => true,
                :left   => true}
    end

    def inspect
      {:walls => walls,
       :x => x,
       :y => y}.inspect
    end

    def to_s
      "(#{x},#{y})"
    end

    def to_html
      "<td class='#{wall_status}'><span>#{@count}</span></td>\n"
    end

    def discover_from! neighbor
      Cell.count += 1
      @count = Cell.count
      if neighbor.x > x
        walls[:right] = neighbor.walls[:left] = false
      elsif neighbor.x < x
        walls[:left] = neighbor.walls[:right] = false
      elsif neighbor.y > y
        walls[:bottom] = neighbor.walls[:top] = false
      elsif neighbor.y < y
        walls[:top] = neighbor.walls[:bottom] = false
      end
    end

    def discovered?
      [true,true,true,true] != walls.values
    end

    protected

      def wall_status
        walls.select {|side, status| status }.map(&:first).join(' ')
      end
  end
end


if $0 == __FILE__
  maze = Maze.new ARGV.shift.to_i, ARGV.shift.to_i
  puts maze.to_html
end
