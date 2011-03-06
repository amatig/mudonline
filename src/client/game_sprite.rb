class GameSprite
  include Rubygame::Sprites::Sprite
  
  def initialize
    super()
    @image = Rubygame::Surface.load("mario.png")
    @rect = @image.make_rect
    @new_pos = nil
  end
  
  def update(seconds_passed)
    #puts seconds_passed
    if @new_pos 
      if@rect.x > @new_pos[0]
        @rect.x -= seconds_passed * 50
      else
        @rect.x += seconds_passed * 50
      end
    end
  end
  
  def move(pos)
    @new_pos = pos
  end
  
  def draw(on_surface)
    @image.blit(on_surface, @rect)
  end
  
end
