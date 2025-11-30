extends Control

func _on_zoomin():
	$Menu.show()
	$PRESSTART.hide()
	$Menu/HostGameBTN.grab_focus()
