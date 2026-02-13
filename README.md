# Polígono vs Formas - Juego Asimétrico de Terror (Roblox)

Juego multijugador asimétrico de terror para Roblox Studio. Un jugador es el **Polígono** (el malo) y los demás son **Formas** que deben sobrevivir y escapar.

## Estructura del Proyecto

```
src/
├── ServerScriptService/
│   └── GameManager.server.lua      -- Script principal del servidor (rondas, roles, daño, puertas)
├── StarterGui/
│   └── GameUI.client.lua           -- Toda la UI del jugador (timer, vida, selección, pantallas)
├── StarterPlayerScripts/
│   └── GolpeAbility.client.lua     -- Input del Polígono para atacar
├── ReplicatedStorage/
│   └── RemoteEvents/               -- (creados automáticamente por GameManager)
└── Workspace/                      -- (mapa creado automáticamente)
```

## Instalación en Roblox Studio

1. Abrir Roblox Studio y crear un nuevo lugar vacío (Baseplate).
2. Eliminar la Baseplate por defecto.
3. Copiar cada archivo en su ubicación correspondiente:

| Archivo | Destino en Roblox Studio | Tipo |
|---------|-------------------------|------|
| `GameManager.server.lua` | `ServerScriptService > GameManager` | Script |
| `GameUI.client.lua` | `StarterGui > GameUI` | LocalScript |
| `GolpeAbility.client.lua` | `StarterPlayerScripts > GolpeAbility` | LocalScript |

4. Los RemoteEvents, el mapa y los spawns se crean automáticamente al ejecutar.
5. Hacer Play con al menos 2 jugadores (usar Test > Local Server con 2+ jugadores).

## Ciclo del Juego

### Fase 1: Descanso (40 s)
- Todos en el Lobby
- Timer en pantalla

### Fase 2: Selección (30 s)
- Pantalla negra → se elige un Polígono al azar
- Las Formas eligen su personaje: Cono, Esfera, Cubo, Tubo o Rectángulo
- Si no eligen, se asigna una forma aleatoria

### Fase 3: Partida (5 min)
- El Polígono caza a las Formas
- A los 60 s finales se abren puertas de escape
- Las Formas deben escapar tocando las puertas

## Mecánicas

### Polígono
- Habilidad "Golpe": 10 de daño, cooldown 2.1 s
- Click izquierdo para atacar al jugador más cercano (12 studs de rango)
- Apariencia negra con material Neon

### Formas
- 100 puntos de vida
- Barra de vida en pantalla
- Cada forma tiene un color diferente

### Puertas de Escape
- Se abren cuando quedan 60 segundos
- 3 puertas en posiciones aleatorias del mapa
- Tocar una puerta = escapar

## Condiciones de Victoria
- **Polígono gana**: todas las Formas mueren
- **Formas ganan**: al menos una Forma escapa

## Requisitos Técnicos Implementados
- Daño validado en servidor (anti-cheat)
- Cooldown validado en servidor
- Atributos de jugador: Role, Health, Escaped, Shape
- Manejo de desconexiones
- Mínimo 2 jugadores para iniciar
- Reinicio automático de rondas
