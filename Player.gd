extends KinematicBody2D

export var speed = 50
export (String, "static", "player", "patrol", "navigate", "follow") var ai = "static"
export (NodePath) var target = null
export (NodePath) var nav = null
export (SpriteFrames) var frames
var idle = "default"
const fudge = 2
var goto = null

signal hit

func _ready():
  #var frames = preload("res://mom/mom.tres")
  $AnimatedSprite.set_sprite_frames(frames)

func go_towards(other_position):
  var velocity = Vector2()
  if self.position.x + fudge < other_position.x:
    velocity.x += 1
  if self.position.x - fudge > other_position.x:
    velocity.x -= 1
  if self.position.y + fudge < other_position.y:
    velocity.y += 1
  if self.position.y - fudge > other_position.y:
    velocity.y -= 1
  return velocity

func _physics_process(delta):
  var velocity = Vector2()

  # player control
  if(ai == "player"):
    if Input.is_action_pressed("ui_right"):
      goto = null
      velocity.x += 1
    if Input.is_action_pressed("ui_left"):
      goto = null
      velocity.x -= 1
    if Input.is_action_pressed("ui_down"):
      goto = null
      velocity.y += 1
    if Input.is_action_pressed("ui_up"):
      goto = null
      velocity.y -= 1
    if goto:
      # simple goto, not accounting for walls
      velocity = go_towards(goto)
      # use navigation map to walk around walls (feels a little cheap)
      #var n = get_node(nav)
      #var path = n.get_simple_path(self.position, goto)
      #var index = 1
      #while velocity.length() == 0 and index < path.size():
      #  velocity = go_towards(path[index])
      #  index = index + 1

  # follow target blindly (blocked by walls)
  if(ai == "follow"):
    velocity = go_towards(get_node(target).position)

  # patrol path
  if(ai == "patrol"):
    var path = get_node(target)
    while velocity.length() == 0:
      velocity = go_towards(path.position)
      if velocity.length() == 0:
        path.set_offset(path.get_offset() + 10)

  # navigate towards player (going around walls)
  if(ai == "navigate"):
    # TODO only refresh the path once in a while
    var n = get_node(nav)
    var t = get_node(target)
    var path = n.get_simple_path(self.position, t.position)
    var index = 1
    while velocity.length() == 0 and index < path.size():
      velocity = go_towards(path[index])
      index = index + 1

  if velocity.length() > 0:
    velocity = velocity.normalized() * speed
    $AnimatedSprite.play()
  else:
    $AnimatedSprite.animation = idle
  if velocity.x > 0:
      $AnimatedSprite.animation = "right"
      idle = "right_idle"
  elif velocity.x < 0:
      $AnimatedSprite.animation = "left"
      idle = "left_idle"
  elif velocity.y > 0:
      $AnimatedSprite.animation = "down"
      idle = "down_idle"
  elif velocity.y < 0:
      $AnimatedSprite.animation = "up"
      idle = "up_idle"
  move_and_slide(velocity, Vector2())
  for i in get_slide_count():
    emit_signal("hit", get_slide_collision(i).collider, self)

  # update z index
  self.z_index = self.position.y