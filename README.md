# Leventheil

A 2.5D arena combat demo built in Godot 4, where **your weapon is also your weight**.

Spikes orbit your character. They make you strong, armored and slow. Every time you use them they are spent, and you get lighter and faster. To get them back, you have to switch to your light, fragile stance and earn them by killing.

> **Status:** in development. A playable web demo is planned for itch.io in December 2026.

## Core loop

- **Weight:** spike count sets your weight. Weight scales attack speed, attack animation, dash speed and movement speed.
- **Spike stance (heavy):** your dash spins the spike ring and hits every enemy inside it for damage that scales with your spike count. Jumping throws a spike at the cursor; missed spikes plant themselves in the ground. While spikes are up, hits strip spikes instead of health.
- **Light stance:** no weight, fast sword. Kills here are the only way to regain spikes.
- **Stance swap (Q):** has a short lock and cooldown, so switching is a decision, not a reflex.
- **Parry:** dash into a heavy enemy's wind-up with spikes up to stun it. Enough parries trigger a finisher.
- **Waves:** five waves, ending in a parry-only boss with an enrage phase. Dying restarts the current wave.

In progress on the `vine` branch: a vine stance that roots enemies, pulls them in with an aimed throw, and sprouts planted spikes into traps. Rooted enemies take double damage, so vines set up what spikes finish.

## Controls

| Action | Input |
| --- | --- |
| Move | WASD |
| Run | Shift |
| Attack | Left mouse |
| Dash / parry | Right mouse |
| Jump / throw | Space |
| Swap stance | Q |

## Architecture

- **Signal-driven skills:** skills are child nodes of the player that listen to its signals (`dash_started`, `jump_pressed`, `stance_toggled`, `attack_landed`...). The player script does not know any skill exists, so new skills are added without touching it.
- **Duck-typed hooks:** the player asks its children whether anything absorbs damage, enables parry or replaces the jump (`absorb_damage`, `enables_parry`, `replaces_jump`). Skills opt in by implementing the method.
- **Event bus:** an `Events` autoload carries game-wide signals (enemy deaths, camera requests, HUD updates, wave and boss events). No node reaches into another by path.
- **Enemy base class:** `EnemyBase` owns health, hit flash, death, root and pull states. Enemies override a single `_on_damaged` hook for their own reaction. The heavy enemy and the boss share one script; the boss is configured entirely through exported values in its scene.
- **Single death path:** every kill goes through `die()`, so rewards and wave counting can never double-fire.

## Running the project

Built with **Godot 4.6**, Compatibility renderer (targeting web export).

The Mixamo animation files and textures are not included in this repository for licensing reasons, so the project will not run as-is from a clone. They are expected under `romero/`.

## Credits

- Character and animations: [Mixamo](https://www.mixamo.com) (Adobe)
- Code and design: Mehmet Bilen

## Planned after the demo

- A posture meter for the boss, so damage slowly builds toward a stagger alongside parries
- Story and lore for the world
- Custom character, enemy and environment art
