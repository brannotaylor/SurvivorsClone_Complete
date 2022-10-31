extends TextureRect

@onready var itemTexture = $ItemTexture
var upgrade = null


func _ready():
	if upgrade != null:
		itemTexture.texture = load(UpgradeDb.UPGRADES[upgrade]["icon"])

