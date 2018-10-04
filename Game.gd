extends Node2D

# TODO dad dodges mom
# TODO touch goto

var pickup_class = preload("res://Pickup.tscn")

var sounds = [
  preload("res://soundfx/pick.wav"),
  preload("res://soundfx/pick2.wav")
]
var dad = [preload("res://soundfx/dad.wav")]
var baby = [preload("res://soundfx/baby.wav")]
var mum = [preload("res://soundfx/mom.wav")]
var images = [
  preload("res://fruits/38.png"),
  preload("res://fruits/40.png"),
  preload("res://fruits/41.png"),
  preload("res://fruits/48.png"),
  preload("res://fruits/49.png"),
  preload("res://fruits/52.png")
]

func _ready():
  randomize()
  # listen to collision events
  $Player.connect("hit", self, "on_player_hit")
  $Baby.connect("hit", self, "on_other_hit")
  $Mom.connect("hit", self, "on_other_hit")
  $Dad.connect("hit", self, "on_other_hit")

func _input(event):
 # Mouse in viewport coordinates
 if event is InputEventMouseButton:
   $Player.goto = event.position

# utils: quit on escape key
func _unhandled_input(event):
  if event is InputEventKey:
    if event.pressed and event.scancode == KEY_ESCAPE:
      get_tree().quit()

# utils: play sound (and ignore request to play that sound again until its done)
var sound_ignore_list = []

func play_sound(sound, ignore_item):
  if sound:
    if not ignore_item in sound_ignore_list:
      if ignore_item:
        sound_ignore_list.append(ignore_item)
      var player = AudioStreamPlayer.new()
      player.stream = sound
      self.add_child(player)
      player.play(0)
      player.connect("finished", self, "on_player_done", [player, ignore_item])

func on_player_done(player, ignore_item):
  player.queue_free()
  sound_ignore_list.erase(ignore_item)

# collisions
func on_player_hit(body, body_2):
  if body == $Baby:
    play_sound(baby[randi() % baby.size()], body)
  if body == $Dad:
    play_sound(dad[randi() % dad.size()], body)
  if body == $Mom:
    play_sound(mum[randi() % mum.size()], body)

func on_other_hit(body, body_2):
  if body == $Player:
    on_player_hit(body_2, body)

# pickup items
func _on_pickup_body_entered(body):
  if body == $Player:
    # clear children of $PickupPlaceholder
    for child in $PickupPlaceholder.get_children():
      child.queue_free()
    # play sound if any
    play_sound(sounds[randi() % sounds.size()], null)
    # spawn another pikcup later
    $PickupTimer.start()

func _on_PickupTimer_timeout():
  # spawn a pickup
  var pickup = pickup_class.instance()
  pickup.get_node("Sprite").texture = images[randi() % images.size()]
  # spawn at a free location in the tilemap
  var s = $TileMap.cell_size * $TileMap.scale
  var rect = $TileMap.get_used_rect()
  var x = 0
  var y = 0
  var px = 0
  var py = 0
  # also make sure its not too close to player
  # TODO I would prefer a do...while loop here, instead of initializing my variable to known invalid states
  while $TileMap.get_cell(x, y) != -1  or Vector2(px, py).distance_to($Player.position) < s.x:
    x = randi() % int(rect.end.x)
    y = randi() % int(rect.end.y)
    px = x * s.x + s.x/2
    py = y * s.y + s.y/2
  pickup.position = Vector2(px, py)
  pickup.connect("body_entered", self, "_on_pickup_body_entered")
  $PickupPlaceholder.add_child(pickup)