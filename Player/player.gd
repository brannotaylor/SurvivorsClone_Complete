extends CharacterBody2D


var movement_speed = 40.0
var hp = 50
var maxhp = 50
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

@onready var sprite = $Sprite2D
@onready var walkTimer = $Timer


#Attacks
var iceSpear = preload("res://Player/Attacks/icespear.tscn")
var tornado = preload("res://Player/Attacks/tornado.tscn")
var javelin = preload("res://Player/Attacks/javelin.tscn")

#AttackNodes
@onready var iceSpearTimer = $Attack/IceSpearTimer
@onready var iceSpearAttackTimer = $Attack/IceSpearTimer/IceSpearAttackTimer
@onready var tornadoTimer = $Attack/TornadoTimer
@onready var tornadoAttackTimer = $Attack/TornadoTimer/TornadoAttackTimer
@onready var javelinBase = $Attack/Javelins

#Upgrades
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#IceSpear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5
var icespear_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#Javelins
var javelin_ammo = 0
var javelin_level = 0

#Enemy Related
var enemy_close = []

#GUI Elements
@onready var experienceBar = $GUILayer/GUI/ExperienceBar
@onready var labelLevel = $GUILayer/GUI/lbl_level
@onready var upgradeOptions = $GUILayer/GUI/LevelUp/UpgradeOptions
@onready var levelUpContainer = $GUILayer/GUI/LevelUp
@onready var itemOption = preload("res://Utility/item_option.tscn")
@onready var healthBar = $GUILayer/GUI/HealthBar
@onready var lblTime = $GUILayer/GUI/lbl_timer
@onready var collectedWeapons = $GUILayer/GUI/CollectedWeapons
@onready var collectedUpgrades = $GUILayer/GUI/CollectedUpgrades
@onready var collectedItems = preload("res://Player/GUI/item_container.tscn")
@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")


#Sounds
@onready var sndLevelUp = $GUILayer/GUI/LevelUp/snd_levelup


#Signals
signal playerdeath()

func _ready():
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hitbox_hurt(0,0,0)
	upgrade_character("icespear1")

func _physics_process(_delta):
	movement()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if x_mov > 0:
		sprite.flip_h = true
	elif x_mov < 0:
		sprite.flip_h = false
	
	if mov != Vector2.ZERO:
		last_movement = mov
		if walkTimer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else:
				sprite.frame += 1
			walkTimer.start()
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()

func attack():
	#Weapons Start
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()
			
func get_random_target():
	var rand_choice_num = enemy_close.size()
	if rand_choice_num > 0:
		var array_num = randi_range(0,rand_choice_num - 1)
		return enemy_close[array_num].global_position
	else:
		return Vector2.UP


func _on_hitbox_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	if hp <= 0:
		death()
	healthBar.max_value = maxhp
	healthBar.value = hp

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50), 3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >=300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()
		


func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo+additional_attacks
	iceSpearAttackTimer.start()

func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()

func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo+additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo+additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#Update Javelin as well
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif exp_cap < 40:
		exp_cap = 95 + (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	experienceBar.value = set_value
	experienceBar.max_value = set_max_value
	

func levelup():
	sndLevelUp.play()
	labelLevel.text = str("Level:",experience_level)
	var tween = levelUpContainer.create_tween()
	tween.tween_property(levelUpContainer,"position",Vector2(220,50), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelUpContainer.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOption.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelUpContainer.visible = false
	levelUpContainer.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					pass
				else:
					dblist.append(i)
		else: #If there are no prequisites
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist[randi_range(0,dblist.size()-1)]
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func adjust_gui_collection(upgrade):
	var get_upgraded_displaynames = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displaynames in get_collected_displaynames:
			var new_item = collectedItems.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.grab()
		calculate_experience(gem_exp)

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	var string = str(get_m,":",get_s)
	lblTime.text = string
	

func _on_button_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")

