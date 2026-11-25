# BLACK SITE

A short first-person psychological horror game about a facility that remembers you.

**Play in your browser:** https://alviya-fatima.github.io/black-site/

You wake in Intake 03. The door is unlocked. The building is not empty. Find a way out, read what the staff left behind, and try not to come back.

## Controls

- **WASD** move
- **Mouse** look
- **Shift** run
- **E** interact
- **Tab** case notes
- **Esc** pause

## Features

- Six endings
- Original low-poly facility, lighting, and audio
- Documents, notes, keypads, fuses, and hidden routes
- A very persistent bear

## Run locally

1. Install [Godot 4.7](https://godotengine.org/) or newer.
2. Open `project.godot`.
3. Press **F5**.

## Web build

The game is exported for the web with Godot's GL Compatibility renderer.

```powershell
godot --headless --path . --export-release "Web" "build/web/index.html"
python -m http.server 8060 --directory build/web
```

Then open `http://127.0.0.1:8060/`.

## License

MIT. See [LICENSE](LICENSE).

## Credits

Created by [alviya-fatima](https://github.com/alviya-fatima).

Built with [Godot Engine 4.7](https://godotengine.org/).
