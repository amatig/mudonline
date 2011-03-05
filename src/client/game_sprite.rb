class GameSprite
  include Rubygame::Sprites::Sprite
  
  def initialize
    super()
    @image = Rubygame::Surface.load("mario.png")
    @rect = @image.make_rect
  end
  
  def update(seconds_passed)
    
  end
  
  def move(pos)
    @rect.move!(*pos)
  end
  
  def draw(on_surface)
    @image.blit(on_surface, @rect)
  end
  
end
