extends Node

enum DeviceType {
    DESKTOP,
    MOBILE,
    WEB,
    UNKNOWN
}

var _platform_name := "Onbekend"
var _device_type: DeviceType = DeviceType.UNKNOWN

func _ready() -> void:
    _detect_device()

func _detect_device() -> void:
    _platform_name = OS.get_name()
    if OS.has_feature("web"):
        _device_type = DeviceType.WEB
    elif OS.has_feature("mobile") or _platform_name in ["Android", "iOS"]:
        _device_type = DeviceType.MOBILE
    elif _platform_name in ["Windows", "Linux", "FreeBSD", "macOS"]:
        _device_type = DeviceType.DESKTOP
    else:
        _device_type = DeviceType.UNKNOWN

func is_mobile() -> bool:
    return _device_type == DeviceType.MOBILE

func is_desktop() -> bool:
    return _device_type == DeviceType.DESKTOP

func has_touchscreen() -> bool:
    return DisplayServer.is_touchscreen_available()

func has_controller() -> bool:
    return not Input.get_connected_joypads().is_empty()

func has_keyboard_mouse() -> bool:
    return is_desktop() or not has_touchscreen()

func get_device_type() -> String:
    match _device_type:
        DeviceType.DESKTOP:
            return "desktop"
        DeviceType.MOBILE:
            return "mobile"
        DeviceType.WEB:
            return "web"
        _:
            return "unknown"

func get_platform_name() -> String:
    return _platform_name

func get_summary() -> String:
    var inputs: Array[String] = []
    if has_keyboard_mouse():
        inputs.append("toetsenbord/muis")
    if has_touchscreen():
        inputs.append("touchscreen")
    if has_controller():
        inputs.append("controller")
    return "%s | %s" % [get_platform_name(), ", ".join(inputs) if not inputs.is_empty() else "geen invoerapparaat"]
