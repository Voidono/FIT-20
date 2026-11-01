## Centralised platform detection and mobile-UI helpers.
## Registered as an AutoLoad singleton named "DeviceInput" in project.godot
## so every scene can call DeviceInput.is_mobile() without boilerplate.
##
## Usage:
##   if DeviceInput.is_mobile():
##       show touch controls
##   else:
##       show keyboard hint label

extends Node


## Returns true on phones / tablets: native Android/iOS, or a web export
## running on a mobile browser.
static func is_mobile() -> bool:
	return (
		OS.has_feature("mobile")
		or OS.has_feature("android")
		or OS.has_feature("ios")
		or OS.has_feature("web_android")
		or OS.has_feature("web_ios")
	)


## Returns true on desktop operating systems (Windows, macOS, Linux).
static func is_desktop() -> bool:
	return not is_mobile()
