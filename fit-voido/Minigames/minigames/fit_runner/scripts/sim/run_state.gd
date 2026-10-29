class_name FrRunState
extends RefCounted
## Phases of one FIT Runner attempt. Lives in its own file so the HUD and the runner never depend on each other.

enum Phase { READY, COUNTDOWN, RUNNING, PAUSED, FINISHED }
