extends TextureButton

@onready var item_sprite: Sprite2D = $ItemSprite

func update_item(item: inv_item):
	if !item:
		item_sprite.visible = false
	else:
		item_sprite.visible = true
		item_sprite.texture = item.texture
		item_sprite.scale = Vector2(2,2)
