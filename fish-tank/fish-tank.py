#!/usr/bin/env python3
"""
ASCII Fish Tank Simulator
A virtual pet fish that grows and changes over time.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
import random

# Data file path
DATA_DIR = Path.home() / ".claude" / "fish-data"
DATA_FILE = DATA_DIR / "fish_state.json"
HISTORY_FILE = DATA_DIR / "fish_history.json"

# Fish growth stages (in days)
GROWTH_STAGES = {
    "egg": (0, 1),        # 0-1 days
    "fry": (1, 3),        # 1-3 days
    "juvenile": (3, 7),   # 3-7 days
    "adult": (7, 30),     # 7-30 days
    "elder": (30, float('inf'))  # 30+ days
}

# Fish ASCII art for different stages and states
FISH_ART = {
    "egg": [
        " (o) ",
    ],
    "fry": [
        "<><",
    ],
    "juvenile": [
        "><((('>",
    ],
    "adult": [
        "><(((('>",
    ],
    "elder": [
        "><((((((*>",
    ],
}

# Sleeping fish (closed eye)
FISH_ART_SLEEP = {
    "egg": [
        " (-) ",
    ],
    "fry": [
        "<->",
    ],
    "juvenile": [
        ">-((('-",
    ],
    "adult": [
        ">-(((('-",
    ],
    "elder": [
        ">-(((((-*-",
    ],
}

# Hungry fish (mouth open wide)
FISH_ART_HUNGRY = {
    "egg": [
        " (o) ",
    ],
    "fry": [
        "<°>",
    ],
    "juvenile": [
        ">°((('>",
    ],
    "adult": [
        ">°(((('>",
    ],
    "elder": [
        ">°((((((*>",
    ],
}

# Dead fish (upside down)
FISH_ART_DEAD = [
    " <'))))><",
]

def get_tank_width():
    """Get terminal width for tank sizing."""
    try:
        import shutil
        return min(shutil.get_terminal_size().columns, 60)
    except:
        return 50

def create_initial_state():
    """Create a new fish."""
    return {
        "name": generate_fish_name(),
        "birth_time": datetime.now().isoformat(),
        "last_fed_time": datetime.now().isoformat(),
        "last_viewed_time": datetime.now().isoformat(),
        "times_viewed": 0,
        "is_alive": True,
        "happiness": 100,
        "hunger": 0,
    }

def generate_fish_name():
    """Generate a random fish name."""
    prefixes = ["Bubble", "Fin", "Splash", "Coral", "Wave", "Blue", "Goldie", "Nemo", "Dory", "Gill"]
    suffixes = ["y", "ie", "o", "a", ""]
    return random.choice(prefixes) + random.choice(suffixes)

def load_state():
    """Load fish state from file."""
    if DATA_FILE.exists():
        try:
            with open(DATA_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return None

def save_state(state):
    """Save fish state to file."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(DATA_FILE, 'w') as f:
        json.dump(state, f, indent=2)

def save_history(state, rendered_frame):
    """Save viewing history."""
    history = []
    if HISTORY_FILE.exists():
        try:
            with open(HISTORY_FILE, 'r') as f:
                history = json.load(f)
        except:
            pass

    history.append({
        "timestamp": datetime.now().isoformat(),
        "stage": get_growth_stage(state),
        "is_sleeping": is_sleeping(),
        "hunger": state.get("hunger", 0),
        "happiness": state.get("happiness", 100),
        "frame": rendered_frame
    })

    # Keep only last 100 entries
    history = history[-100:]

    with open(HISTORY_FILE, 'w') as f:
        json.dump(history, f, indent=2)

def get_age_days(state):
    """Calculate fish age in days."""
    birth = datetime.fromisoformat(state["birth_time"])
    now = datetime.now()
    return (now - birth).total_seconds() / 86400

def get_growth_stage(state):
    """Determine fish growth stage based on age."""
    age = get_age_days(state)
    for stage, (min_age, max_age) in GROWTH_STAGES.items():
        if min_age <= age < max_age:
            return stage
    return "elder"

def get_hours_since_last_fed(state):
    """Get hours since last feeding."""
    last_fed = datetime.fromisoformat(state["last_fed_time"])
    now = datetime.now()
    return (now - last_fed).total_seconds() / 3600

def get_hours_since_last_viewed(state):
    """Get hours since last viewing."""
    last_viewed = datetime.fromisoformat(state["last_viewed_time"])
    now = datetime.now()
    return (now - last_viewed).total_seconds() / 3600

def is_sleeping():
    """Check if it's nighttime (fish sleeping)."""
    hour = datetime.now().hour
    return hour < 6 or hour >= 22  # Sleep between 10pm and 6am

def is_hungry(state):
    """Check if fish is hungry."""
    hours_since_fed = get_hours_since_last_fed(state)
    return hours_since_fed > 8

def is_very_hungry(state):
    """Check if fish is very hungry (starving)."""
    hours_since_fed = get_hours_since_last_fed(state)
    return hours_since_fed > 48

def update_state(state):
    """Update fish state based on time passed."""
    hours_away = get_hours_since_last_viewed(state)

    # Update hunger
    hours_since_fed = get_hours_since_last_fed(state)
    state["hunger"] = min(100, int(hours_since_fed * 4))  # +4% per hour

    # Update happiness based on visits and hunger
    if hours_away > 24:
        state["happiness"] = max(0, state["happiness"] - int(hours_away / 24) * 10)

    if is_very_hungry(state):
        state["happiness"] = max(0, state["happiness"] - 20)

    # Fish dies if starving for too long (7 days without food)
    if hours_since_fed > 168:  # 7 days
        state["is_alive"] = False

    # Update view count and time
    state["times_viewed"] = state.get("times_viewed", 0) + 1
    state["last_viewed_time"] = datetime.now().isoformat()

    return state

def get_fish_art(state):
    """Get appropriate fish ASCII art based on state."""
    if not state["is_alive"]:
        return FISH_ART_DEAD

    stage = get_growth_stage(state)

    if is_sleeping():
        return FISH_ART_SLEEP.get(stage, FISH_ART_SLEEP["adult"])
    elif is_hungry(state):
        return FISH_ART_HUNGRY.get(stage, FISH_ART_HUNGRY["adult"])
    else:
        return FISH_ART.get(stage, FISH_ART["adult"])

def get_bubbles(state):
    """Generate bubble patterns."""
    if not state["is_alive"]:
        return []

    if is_sleeping():
        return ["z", "Z"]  # Sleeping zzz

    return [".", "o", "O"]

def get_decoration(width):
    """Get tank bottom decoration."""
    # Create seaweed and rocks that fit the tank width
    seaweed = "  }}}  {{{"
    rocks = " ^  @@  ^  @@ "
    sand = "~" * (width - 2)

    # Center and repeat to fill width
    seaweed_line = (seaweed * ((width // len(seaweed)) + 1))[:width - 2]
    rocks_line = (rocks * ((width // len(rocks)) + 1))[:width - 2]

    return [seaweed_line, rocks_line, sand]

def render_tank(state):
    """Render the complete fish tank."""
    width = get_tank_width()
    tank_height = 12

    lines = []

    # Tank top
    lines.append("+" + "-" * (width - 2) + "+")

    # Get fish art
    fish_art = get_fish_art(state)
    fish_width = max(len(line) for line in fish_art)

    # Calculate fish position (slightly randomized but consistent for session)
    random.seed(int(datetime.now().timestamp() / 60))  # Changes every minute
    fish_x = random.randint(5, width - fish_width - 5)
    fish_y = random.randint(2, 5)

    # Generate bubbles
    bubbles = get_bubbles(state)
    bubble_positions = [(fish_x + fish_width, fish_y - i - 1) for i, _ in enumerate(bubbles)]

    # Render tank body
    for y in range(tank_height - 3):
        line = "|"
        content = [" "] * (width - 2)

        # Add fish
        if 0 <= y - fish_y < len(fish_art):
            fish_line = fish_art[y - fish_y]
            for i, c in enumerate(fish_line):
                if 0 <= fish_x + i < width - 2:
                    content[fish_x + i] = c

        # Add bubbles
        for (bx, by), bubble in zip(bubble_positions, bubbles):
            if y == by and 0 <= bx < width - 2:
                content[bx] = bubble

        # Night mode - darker background
        if is_sleeping() and state["is_alive"]:
            line += "".join(content).replace(" ", ".")
        else:
            line += "".join(content)

        line += "|"
        lines.append(line)

    # Tank decoration (seaweed and rocks)
    deco = get_decoration(width)
    for d in deco:
        padded = d.center(width - 2)[:width - 2]
        lines.append("|" + padded + "|")

    # Tank bottom
    lines.append("+" + "-" * (width - 2) + "+")

    return "\n".join(lines)

def render_status(state):
    """Render fish status information."""
    lines = []

    name = state.get("name", "Fish")
    stage = get_growth_stage(state)
    age = get_age_days(state)

    if not state["is_alive"]:
        lines.append(f"  {name} has passed away...")
        lines.append(f"  Lived for {age:.1f} days")
        lines.append(f"  Rest in peace, little friend.")
        return "\n".join(lines)

    # Status bar
    hunger = state.get("hunger", 0)
    happiness = state.get("happiness", 100)

    lines.append(f"  Name: {name} ({stage.capitalize()})")
    lines.append(f"  Age: {age:.1f} days")

    # Hunger bar
    hunger_bar = "=" * (10 - hunger // 10) + "-" * (hunger // 10)
    hunger_status = "Full" if hunger < 30 else "Hungry" if hunger < 70 else "Starving!"
    lines.append(f"  Satiety: [{hunger_bar}] {hunger_status}")

    # Happiness bar
    happy_bar = "=" * (happiness // 10) + "-" * (10 - happiness // 10)
    happy_status = "Happy" if happiness > 70 else "Okay" if happiness > 30 else "Sad"
    lines.append(f"  Mood:    [{happy_bar}] {happy_status}")

    # Time info
    hour = datetime.now().hour
    if is_sleeping():
        lines.append(f"  Status: Sleeping... (Night time)")
    elif is_hungry(state):
        hours = get_hours_since_last_fed(state)
        lines.append(f"  Status: Hungry! (Not fed for {hours:.1f}h)")
    else:
        lines.append(f"  Status: Swimming happily")

    # Visit count
    visits = state.get("times_viewed", 0)
    lines.append(f"  Visits: {visits}")

    return "\n".join(lines)

def render_commands():
    """Show available commands."""
    return """
  Commands:
  [f] Feed fish  [n] New fish  [h] History  [q] Quit
"""

def feed_fish(state):
    """Feed the fish."""
    if not state["is_alive"]:
        print("  Cannot feed a fish that has passed away...")
        return state

    state["last_fed_time"] = datetime.now().isoformat()
    state["hunger"] = 0
    state["happiness"] = min(100, state["happiness"] + 10)
    print(f"  {state['name']} happily eats the food! *gulp gulp*")
    return state

def show_history():
    """Show viewing history."""
    if not HISTORY_FILE.exists():
        print("  No history yet.")
        return

    try:
        with open(HISTORY_FILE, 'r') as f:
            history = json.load(f)

        print("\n  Recent History (last 10 entries):")
        print("  " + "-" * 40)
        for entry in history[-10:]:
            ts = datetime.fromisoformat(entry["timestamp"]).strftime("%Y-%m-%d %H:%M")
            stage = entry.get("stage", "unknown")
            sleeping = " (sleeping)" if entry.get("is_sleeping") else ""
            print(f"  {ts} - {stage}{sleeping}")
        print("  " + "-" * 40)
    except:
        print("  Could not read history.")

def main():
    """Main function."""
    # Load or create state
    state = load_state()

    if state is None:
        print("\n  Welcome! A new fish egg has appeared in your tank!")
        print("  Take good care of it!\n")
        state = create_initial_state()
    else:
        hours_away = get_hours_since_last_viewed(state)
        if hours_away > 24:
            print(f"\n  It's been {hours_away:.1f} hours since your last visit!")
        state = update_state(state)

    # Render the tank
    tank = render_tank(state)
    status = render_status(state)

    # Display
    print("\n" + "=" * get_tank_width())
    print("       ASCII FISH TANK")
    print("=" * get_tank_width())
    print(tank)
    print(status)

    # Save state and history
    save_state(state)
    save_history(state, tank)

    # Interactive mode if running in terminal
    if sys.stdin.isatty():
        print(render_commands())

        while True:
            try:
                cmd = input("  > ").strip().lower()
                if cmd == 'q':
                    print("  Goodbye! Take care of your fish!")
                    break
                elif cmd == 'f':
                    state = feed_fish(state)
                    save_state(state)
                    print(render_tank(state))
                    print(render_status(state))
                elif cmd == 'n':
                    confirm = input("  Start over with a new fish? (y/n): ").strip().lower()
                    if confirm == 'y':
                        state = create_initial_state()
                        save_state(state)
                        print(f"\n  A new fish named {state['name']} has arrived!")
                        print(render_tank(state))
                        print(render_status(state))
                elif cmd == 'h':
                    show_history()
                else:
                    print("  Unknown command. Use [f]eed, [n]ew, [h]istory, or [q]uit")
            except EOFError:
                break
            except KeyboardInterrupt:
                print("\n  Goodbye!")
                break

if __name__ == "__main__":
    main()