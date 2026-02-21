# Poligono vs Formas - Juego Asimetrico de Terror (Roblox)

Juego multijugador asimetrico de terror para Roblox Studio con **Rojo**. Un jugador es el **Poligono** (el malo) y los demas son **Formas** que deben sobrevivir y escapar.

## Estructura del Proyecto

```
default.project.json          ← Configuracion de Rojo
src/
├── ReplicatedStorage/
│   └── Modules/
│       ├── Config.lua            ← Constantes compartidas (tiempos, vida, colores)
│       └── RemoteManager.lua     ← Crea/obtiene RemoteEvents
├── ServerScriptService/
│   └── GameManager/
│       ├── init.server.lua       ← Orquestador principal (bucle de rondas)
│       ├── MapBuilder.lua        ← Construye mapa, arena, lobby, obstaculos
│       ├── PlayerManager.lua     ← Roles, atributos, teletransporte, apariencia
│       ├── DoorSystem.lua        ← Puertas de escape
│       └── DamageSystem.lua      ← Daño validado en servidor con cooldown
├── StarterGui/
│   └── GameUI/
│       └── init.client.lua       ← UI completa (timer, vida, seleccion, pantallas)
└── StarterPlayerScripts/
    └── GolpeAbility.client.lua   ← Input del Poligono para atacar
```

## Instalacion con Rojo (recomendado)

1. Instalar [Rojo](https://rojo.space/) (CLI + plugin de Roblox Studio).
2. Clonar este repositorio.
3. En la terminal, ejecutar en la carpeta del proyecto:
   ```bash
   rojo serve
   ```
4. En Roblox Studio, abrir un lugar vacio y conectarse desde el plugin Rojo.
5. Todos los scripts se sincronizan automaticamente.
6. Probar con **Test > Local Server** (minimo 2 jugadores).

## Instalacion manual (sin Rojo)

Crear estos elementos en Roblox Studio manualmente:

| Archivo | Destino en Studio | Tipo |
|---------|-------------------|------|
| `Config.lua` | `ReplicatedStorage.Modules.Config` | ModuleScript |
| `RemoteManager.lua` | `ReplicatedStorage.Modules.RemoteManager` | ModuleScript |
| `init.server.lua` | `ServerScriptService.GameManager` | Script |
| `MapBuilder.lua` | `ServerScriptService.GameManager.MapBuilder` | ModuleScript |
| `PlayerManager.lua` | `ServerScriptService.GameManager.PlayerManager` | ModuleScript |
| `DoorSystem.lua` | `ServerScriptService.GameManager.DoorSystem` | ModuleScript |
| `DamageSystem.lua` | `ServerScriptService.GameManager.DamageSystem` | ModuleScript |
| `init.client.lua` | `StarterGui.GameUI` | LocalScript |
| `GolpeAbility.client.lua` | `StarterPlayer.StarterPlayerScripts.GolpeAbility` | LocalScript |

El mapa, spawns, paredes, obstaculos y RemoteEvents se crean automaticamente al ejecutar.

## Ciclo del Juego

### Fase 1: Descanso (40 s)
- Todos en el Lobby
- Timer en pantalla
- Espera minimo 2 jugadores

### Fase 2: Seleccion (30 s)
- Pantalla negra → se elige un Poligono al azar
- Las Formas eligen personaje: Cono, Esfera, Cubo, Tubo o Rectangulo
- Si no eligen a tiempo, se asigna una forma aleatoria

### Fase 3: Partida (5 min)
- El Poligono caza a las Formas en una arena oscura con obstaculos
- A los 60 s finales se abren 3 puertas de escape
- Las Formas deben tocar una puerta para escapar

### Reinicio
- 5 s de espera → vuelve a Descanso

## Mecanicas

### Poligono
- Habilidad "Golpe": 10 de daño, cooldown 2.1 s
- Click izquierdo para atacar al jugador mas cercano (12 studs)
- Apariencia negra con Neon, ojos rojos, tamaño aumentado

### Formas
- 100 puntos de vida
- Barra de vida animada (verde → amarillo → rojo)
- Cada forma tiene color unico
- Indicador de nombre sobre la cabeza

### Puertas de Escape
- Aparecen en posiciones aleatorias de la arena
- Brillan en verde con cartel "SALIDA"
- Tocar una puerta = escapar al Lobby

### Mapa
- Lobby separado con suelo claro
- Arena oscura con paredes perimetrales
- 8 obstaculos para esconderse
- Iluminacion tenebrosa (medianoche, niebla, atmosfera oscura)

## Condiciones de Victoria
- **Poligono gana**: todas las Formas mueren antes de escapar
- **Formas ganan**: al menos una Forma escapa

## Requisitos Tecnicos Implementados
- Daño validado en servidor (anti-cheat) con verificacion de rango
- Cooldown validado en servidor (no se puede hacer bypass desde cliente)
- Atributos de jugador: `Role`, `Health`, `Escaped`, `Shape`
- Manejo de desconexiones (Poligono se va → Formas ganan)
- Minimo 2 jugadores para iniciar partida
- Reinicio automatico de rondas
- Arquitectura modular (Config, RemoteManager, MapBuilder, PlayerManager, DoorSystem, DamageSystem)
