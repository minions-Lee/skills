---
name: fish-tank
description: Raise a virtual ASCII fish that grows and changes over time. The fish remembers its state between sessions - it can grow, get hungry, sleep at night, and needs care. Run /fish to check on your fish!
user_invocable: true
---

# ASCII Fish Tank Skill

A virtual pet fish that lives in your terminal! The fish persists between sessions and changes based on real time.

## Features

- **Time-based changes**: The fish grows from egg → fry → juvenile → adult → elder
- **Day/Night cycle**: Fish sleeps at night (10pm - 6am)
- **Hunger system**: Feed your fish regularly or it gets hungry
- **Happiness**: Visit often to keep your fish happy
- **History**: Each viewing is recorded with timestamp

## How It Works

When you run this skill, it will:
1. Load the fish's saved state (or create a new fish if first time)
2. Calculate changes based on time elapsed since last visit
3. Display the current ASCII fish tank with the fish's status
4. Save the updated state

## Running the Skill

Simply execute the fish tank script:

```bash
python3 ~/.claude/skills/fish-tank/fish-tank.py
```

## Fish Life Stages

| Stage    | Age (days) | Appearance     |
|----------|------------|----------------|
| Egg      | 0-1        | `(o)`          |
| Fry      | 1-3        | `<><`          |
| Juvenile | 3-7        | `><((('>`      |
| Adult    | 7-30       | `><(((('>`     |
| Elder    | 30+        | `><((((((*>`   |

## Fish States

- **Normal**: Swimming happily with eye open
- **Sleeping**: Eyes closed (night time 10pm-6am)
- **Hungry**: Mouth wide open (not fed for 8+ hours)
- **Starving**: Very hungry, happiness decreasing (48+ hours without food)
- **Dead**: If not fed for 7 days, the fish passes away

## Interactive Commands

When run interactively, you can:
- `f` - Feed the fish
- `n` - Start over with a new fish
- `h` - View history of visits
- `q` - Quit

## Data Storage

Fish state is stored in `~/.claude/fish-data/fish_state.json`
View history is stored in `~/.claude/fish-data/fish_history.json`

## Example Output

```
============================================================
       ASCII FISH TANK
============================================================
+----------------------------------------------------------+
|                                                          |
|                                O                         |
|                               o                          |
|                              .                           |
|                         ><(((('> |
|                                                          |
|                                                          |
|                                                          |
|  }}}  {{{  }}}  {{{  }}}  {{{  }}}  {{{  }}}  {{{       |
| ^  @@  ^  @@  ^  @@  ^  @@  ^  @@  ^  @@  ^  @@          |
|~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
+----------------------------------------------------------+

  Name: Bubbles (Adult)
  Age: 10.5 days
  Satiety: [========--] Hungry
  Mood:    [==========] Happy
  Status: Swimming happily
  Visits: 42
```

## Instructions for Claude

When the user runs this skill:

1. Execute the fish tank script to show the current state:
   ```bash
   python3 ~/.claude/skills/fish-tank/fish-tank.py
   ```

2. If the user wants to feed the fish, run interactively or update the state manually

3. Share observations about the fish's current state based on the output

4. If the fish is hungry or sad, suggest feeding it or visiting more often

5. Celebrate milestones like the fish growing to a new life stage!