class GameSprite
  include Rubygame::Sprites::Sprite
  
  attr_reader :name
  
  def initialize(name)
    super()
    @name = name
    @image = Rubygame::Surface.load("#{name}.png")
    @image = @image.zoom(0.5, true)
    @rect = @image.make_rect
    @target_pos = nil
    @target_dir = ""
    @step = 100
  end
  
  def update(seconds_passed)
    if @target_dir =~ /left/
      @rect.centerx -= seconds_passed * @step
      if @rect.centerx <= @target_pos[0]
        @target_dir.gsub!("left", "")
      end
    elsif @target_dir =~ /right/
      @rect.centerx += seconds_passed * @step
      if @rect.centerx >= @target_pos[0]
        @target_dir.gsub!("right", "")
      end
    end
    if @target_dir =~ /up/
      @rect.centery -= seconds_passed * @step
      if @rect.centery <= @target_pos[1]
        @target_dir.gsub!("up", "")
      end
    elsif @target_dir =~ /down/
      @rect.centery += seconds_passed * @step
      if @rect.centery >= @target_pos[1]
        @target_dir.gsub!("down", "")
      end
    end
  end
  
  def move(pos)
    @target_pos = pos
    @target_dir = ""
    if @rect.x > @target_pos[0]
      @target_dir += "left"
    else
      @target_dir += "right"
    end
    if @rect.y > @target_pos[1]
      @target_dir += "up"
    else
      @target_dir += "down"
    end
  end
  
  def draw(on_surface)
    @image.blit(on_surface, @rect)
  end
  
end
