#!/usr/bin/env node
/**
 * HOPE: RETRO TERMINAL RACER
 * Pure Node.js (No HTML/Browser) Arcade Highway Car Game
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

if (process.stdout.setDefaultEncoding) {
  process.stdout.setDefaultEncoding('utf8');
}

// ============================================================================
// ANSI ESCAPE CODES & THEMES
// ============================================================================
const ANSI = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  hideCursor: '\x1b[?25l',
  showCursor: '\x1b[?25h',
  home: '\x1b[H',
  clear: '\x1b[2J\x1b[H',
  fg: {
    black: '\x1b[30m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    magenta: '\x1b[35m',
    cyan: '\x1b[36m',
    white: '\x1b[37m',
    gray: '\x1b[90m',
    brightRed: '\x1b[91m',
    brightGreen: '\x1b[92m',
    brightYellow: '\x1b[93m',
    brightBlue: '\x1b[94m',
    brightMagenta: '\x1b[95m',
    brightCyan: '\x1b[96m',
    brightWhite: '\x1b[97m',
  }
};

const THEMES = [
  {
    name: 'NEON SYNTH',
    border: ANSI.fg.brightMagenta,
    curbA: ANSI.fg.brightCyan,
    curbB: ANSI.fg.brightMagenta,
    lane: ANSI.fg.gray,
    tree: ANSI.fg.brightGreen,
    player: ANSI.fg.brightCyan,
    hudTitle: ANSI.fg.brightYellow,
  },
  {
    name: 'CLASSIC ARCADE',
    border: ANSI.fg.brightCyan,
    curbA: ANSI.fg.brightRed,
    curbB: ANSI.fg.brightWhite,
    lane: ANSI.fg.white,
    tree: ANSI.fg.green,
    player: ANSI.fg.brightYellow,
    hudTitle: ANSI.fg.brightCyan,
  },
  {
    name: 'MATRIX GRID',
    border: ANSI.fg.brightGreen,
    curbA: ANSI.fg.green,
    curbB: ANSI.fg.brightGreen,
    lane: ANSI.fg.green,
    tree: ANSI.fg.brightGreen,
    player: ANSI.fg.brightWhite,
    hudTitle: ANSI.fg.brightGreen,
  },
  {
    name: 'NIGHT FURY',
    border: ANSI.fg.brightRed,
    curbA: ANSI.fg.yellow,
    curbB: ANSI.fg.red,
    lane: ANSI.fg.gray,
    tree: ANSI.fg.cyan,
    player: ANSI.fg.brightRed,
    hudTitle: ANSI.fg.brightYellow,
  }
];

const TRAFFIC_COLORS = [
  ANSI.fg.brightRed,
  ANSI.fg.brightYellow,
  ANSI.fg.brightGreen,
  ANSI.fg.brightMagenta,
  ANSI.fg.brightBlue,
  ANSI.fg.white,
];

// ============================================================================
// CONSTANTS & DIMENSIONS
// ============================================================================
const NUM_LANES = 4;
const LANE_WIDTH = 9;
const ROAD_ROWS = 22;
const CAR_HEIGHT = 4;
const PLAYER_ROW = 16; // Rows 16..19
const PLAYFIELD_WIDTH = 47; // 3(scenery) + 1(curb) + 39(road) + 1(curb) + 3(scenery)
const HUD_WIDTH = 28;
const HIGHSCORE_FILE = path.join(__dirname, 'highscore.json');

// ============================================================================
// SPRITES (Each sprite row is strictly 7 characters wide)
// ============================================================================
const SPRITES = {
  player: [
    ' ▄▀▀▀▄ ',
    '██▓▓▓██',
    ' █▀▀▀█ ',
    '██▄▄▄██',
  ],
  enemySports: [
    '██▀▀▀██',
    ' █▓▓▓█ ',
    '██░░░██',
    ' ▀▄▄▄▀ ',
  ],
  enemyTruck: [
    '███████',
    '█▓▓▓▓▓█',
    '█▓▓▓▓▓█',
    '██▄▄▄██',
  ],
  coin: [
    '  ▄█▄  ',
    '  █$█  ',
    '  ▀█▀  ',
  ],
  fuel: [
    '  ▄█▄  ',
    '  █F█  ',
    '  ▀▀▀  ',
  ],
  nitro: [
    '  ╔═╗  ',
    '  ║N║  ',
    '  ╚═╝  ',
  ],
  crash: [
    ' ╲ ▼ ╱ ',
    '─ *#* ─',
    '─ #*# ─',
    ' ╱ ▲ ╲ ',
  ]
};

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================
function stripAnsi(str) {
  return str.replace(/\x1b\[[0-9;]*m/g, '');
}

function padRightVisible(str, width) {
  const visibleLen = stripAnsi(str).length;
  if (visibleLen >= width) return str;
  return str + ' '.repeat(width - visibleLen);
}

function centerVisible(str, width) {
  const visibleLen = stripAnsi(str).length;
  if (visibleLen >= width) return str;
  const left = Math.floor((width - visibleLen) / 2);
  const right = width - visibleLen - left;
  return ' '.repeat(left) + str + ' '.repeat(right);
}

function makeBar(ratio, length, fillColor, emptyColor = ANSI.fg.gray) {
  const clamped = Math.max(0, Math.min(1, ratio));
  const filled = Math.round(clamped * length);
  const empty = length - filled;
  return (
    fillColor + '█'.repeat(filled) +
    emptyColor + '░'.repeat(empty) +
    ANSI.reset
  );
}

function loadHighScore() {
  try {
    if (fs.existsSync(HIGHSCORE_FILE)) {
      const data = JSON.parse(fs.readFileSync(HIGHSCORE_FILE, 'utf8'));
      return Number(data.highScore) || 0;
    }
  } catch (_) {
    // Ignore errors
  }
  return 0;
}

function saveHighScore(score) {
  try {
    fs.writeFileSync(
      HIGHSCORE_FILE,
      JSON.stringify({ highScore: Math.floor(score), updatedAt: new Date().toISOString() }, null, 2),
      'utf8'
    );
  } catch (_) {
    // Ignore write errors
  }
}

// ============================================================================
// GAME ENGINE CLASS
// ============================================================================
class TerminalRacer {
  constructor() {
    this.themeIndex = 0;
    this.highScore = loadHighScore();
    this.state = 'MENU'; // MENU | PLAYING | PAUSED | GAMEOVER
    this.resetGame();
  }

  resetGame() {
    this.playerLane = 1; // 0..3
    this.playerRow = PLAYER_ROW;
    this.score = 0;
    this.distance = 0; // km
    this.coins = 0;
    this.level = 1;
    this.baseSpeed = 120; // km/h
    this.speedOffset = 0; // -40..+80 manual throttle
    this.nitroAmount = 100; // 0..100
    this.nitroActive = false;
    this.nitroTicks = 0;
    this.fuel = 100; // 0..100
    this.scrollTick = 0;
    this.frameCount = 0;
    this.entities = []; // Traffic & pickups
    this.spawnCooldown = 0;
    this.statusMessage = 'Yola cixildi! Uğurlar!';
    this.statusColor = ANSI.fg.brightGreen;
    this.statusTimer = 30;
    this.crashReason = '';
  }

  get currentSpeed() {
    if (this.state !== 'PLAYING') return 0;
    const nitroBonus = this.nitroActive ? 110 : 0;
    return Math.max(60, Math.min(360, this.baseSpeed + this.speedOffset + nitroBonus));
  }

  setFlashMessage(msg, color = ANSI.fg.brightYellow, duration = 28) {
    this.statusMessage = msg;
    this.statusColor = color;
    this.statusTimer = duration;
  }

  // --------------------------------------------------------------------------
  // INPUT HANDLING
  // --------------------------------------------------------------------------
  handleInput(keyName, rawSeq) {
    const key = (keyName || rawSeq || '').toLowerCase();

    if (key === 'q') {
      this.quit();
      return;
    }

    if (key === 't') {
      this.themeIndex = (this.themeIndex + 1) % THEMES.length;
      this.setFlashMessage(`Tema: ${THEMES[this.themeIndex].name}`, ANSI.fg.brightCyan, 25);
      return;
    }

    if (this.state === 'MENU') {
      if (key === 'return' || key === 'enter' || key === 'space' || rawSeq === ' ') {
        this.resetGame();
        this.state = 'PLAYING';
      }
      return;
    }

    if (this.state === 'GAMEOVER') {
      if (key === 'r' || key === 'return' || key === 'enter' || key === 'space' || rawSeq === ' ') {
        this.resetGame();
        this.state = 'PLAYING';
      }
      return;
    }

    if (key === 'p') {
      this.state = this.state === 'PLAYING' ? 'PAUSED' : 'PLAYING';
      return;
    }

    if (this.state !== 'PLAYING') return;

    // Steering Left / Right
    if (key === 'left' || key === 'a') {
      if (this.playerLane > 0) {
        this.playerLane--;
      }
    } else if (key === 'right' || key === 'd') {
      if (this.playerLane < NUM_LANES - 1) {
        this.playerLane++;
      }
    }

    // Throttle Up / Down
    if (key === 'up' || key === 'w') {
      this.speedOffset = Math.min(90, this.speedOffset + 15);
    } else if (key === 'down' || key === 's') {
      this.speedOffset = Math.max(-50, this.speedOffset - 15);
    }

    // Nitro Boost
    if (key === 'space' || rawSeq === ' ') {
      if (!this.nitroActive && this.nitroAmount >= 20) {
        this.nitroActive = true;
        this.nitroTicks = 28;
        this.setFlashMessage('>>> NITRO TURBO AKTIV! (3x XAL) <<<', ANSI.fg.brightCyan, 28);
      } else if (this.nitroAmount < 20) {
        this.setFlashMessage('Nitro kifayet deyil! (Min 20%)', ANSI.fg.brightRed, 20);
      }
    }
  }

  // --------------------------------------------------------------------------
  // GAME UPDATE LOGIC
  // --------------------------------------------------------------------------
  update() {
    if (this.state !== 'PLAYING') return;

    this.frameCount++;
    const speed = this.currentSpeed;

    // Speed factor determines how often the world advances a row
    // At 120 km/h -> advances every 2 ticks; at 240+ km/h -> advances every tick
    const stepFrequency = speed >= 230 ? 1 : speed >= 130 ? 2 : 3;
    const shouldAdvanceRow = (this.frameCount % stepFrequency) === 0;

    // Handle Nitro drain
    if (this.nitroActive) {
      this.nitroTicks--;
      this.nitroAmount = Math.max(0, this.nitroAmount - 1.4);
      if (this.nitroTicks <= 0 || this.nitroAmount <= 0) {
        this.nitroActive = false;
      }
    } else {
      // Passive slight recharge
      this.nitroAmount = Math.min(100, this.nitroAmount + 0.08);
    }

    // Fuel consumption
    const fuelDrain = this.nitroActive ? 0.18 : 0.10 + (speed / 3000);
    this.fuel = Math.max(0, this.fuel - fuelDrain);
    if (this.fuel <= 0) {
      this.triggerGameOver('Yanacaq bitdi! (Out of Fuel)');
      return;
    }

    // Score & Distance progression
    const multiplier = this.nitroActive ? 3 : (this.speedOffset > 30 ? 2 : 1);
    this.score += (speed / 60) * multiplier;
    this.distance += (speed / 3600) * 0.25;

    if (this.score > this.highScore) {
      this.highScore = Math.floor(this.score);
    }

    // Level up every 1000 points
    const newLevel = Math.min(10, 1 + Math.floor(this.score / 1000));
    if (newLevel > this.level) {
      this.level = newLevel;
      this.baseSpeed = Math.min(220, 120 + (this.level - 1) * 12);
      this.setFlashMessage(`★ SEVIYYE ${this.level}! Suret artdi! ★`, ANSI.fg.brightMagenta, 35);
    }

    if (this.statusTimer > 0) {
      this.statusTimer--;
    }

    if (shouldAdvanceRow) {
      this.scrollTick++;
      this.advanceEntities();
      this.spawnEntities();
    }

    this.checkCollisions();
  }

  advanceEntities() {
    for (let i = this.entities.length - 1; i >= 0; i--) {
      const ent = this.entities[i];
      ent.row += 1;

      // Near-miss detection when enemy car passes right beside the player
      if (
        ent.isObstacle &&
        !ent.passed &&
        ent.row > this.playerRow + CAR_HEIGHT - 1
      ) {
        ent.passed = true;
        if (Math.abs(ent.lane - this.playerLane) === 1) {
          this.score += 35;
          this.setFlashMessage('YAXIN KECID! (Near Miss +35)', ANSI.fg.brightYellow, 18);
        } else {
          this.score += 10;
        }
      }

      if (ent.row > ROAD_ROWS + 4) {
        this.entities.splice(i, 1);
      }
    }
  }

  spawnEntities() {
    if (this.spawnCooldown > 0) {
      this.spawnCooldown--;
      return;
    }

    // Find lanes that are free near the top of the screen
    const busyLanes = new Set(
      this.entities.filter(e => e.row < 6).map(e => e.lane)
    );
    const availableLanes = [0, 1, 2, 3].filter(l => !busyLanes.has(l));
    if (availableLanes.length <= 1) return; // Always leave at least 1 lane passable

    const lane = availableLanes[Math.floor(Math.random() * availableLanes.length)];
    const roll = Math.random();

    // If fuel is low, boost fuel spawn probability
    const fuelChance = this.fuel < 35 ? 0.25 : 0.10;

    if (roll < fuelChance) {
      this.entities.push({
        type: 'fuel',
        isObstacle: false,
        lane,
        row: -3,
        height: 3,
        color: ANSI.fg.brightGreen,
        sprite: SPRITES.fuel,
      });
      this.spawnCooldown = 3;
    } else if (roll < fuelChance + 0.14) {
      this.entities.push({
        type: 'coin',
        isObstacle: false,
        lane,
        row: -3,
        height: 3,
        color: ANSI.fg.brightYellow,
        sprite: SPRITES.coin,
      });
      this.spawnCooldown = 2;
    } else if (roll < fuelChance + 0.22) {
      this.entities.push({
        type: 'nitro',
        isObstacle: false,
        lane,
        row: -3,
        height: 3,
        color: ANSI.fg.brightCyan,
        sprite: SPRITES.nitro,
      });
      this.spawnCooldown = 3;
    } else {
      const isTruck = Math.random() < 0.3;
      const color = TRAFFIC_COLORS[Math.floor(Math.random() * TRAFFIC_COLORS.length)];
      this.entities.push({
        type: isTruck ? 'truck' : 'car',
        isObstacle: true,
        lane,
        row: -4,
        height: 4,
        color,
        sprite: isTruck ? SPRITES.enemyTruck : SPRITES.enemySports,
        passed: false,
      });
      // Higher level = tighter traffic
      this.spawnCooldown = Math.max(3, 7 - Math.floor(this.level / 2));
    }
  }

  checkCollisions() {
    const pTop = this.playerRow;
    const pBottom = this.playerRow + CAR_HEIGHT - 1;

    for (let i = this.entities.length - 1; i >= 0; i--) {
      const ent = this.entities[i];
      if (ent.lane !== this.playerLane) continue;

      const eTop = ent.row;
      const eBottom = ent.row + ent.height - 1;
      const overlaps = !(eBottom < pTop || eTop > pBottom);

      if (overlaps) {
        if (ent.isObstacle) {
          this.triggerGameOver('Masinla toqqusdunuz! (Crash!)');
          return;
        } else {
          // Pickup item collected
          if (ent.type === 'coin') {
            this.coins++;
            this.score += 100;
            this.setFlashMessage('[$] SIKKE TOPLANDI! (+100 Xal)', ANSI.fg.brightYellow, 22);
          } else if (ent.type === 'fuel') {
            this.fuel = Math.min(100, this.fuel + 35);
            this.score += 50;
            this.setFlashMessage('[F] YANACAQ DOLDU! (+35% Fuel)', ANSI.fg.brightGreen, 22);
          } else if (ent.type === 'nitro') {
            this.nitroAmount = Math.min(100, this.nitroAmount + 40);
            this.score += 50;
            this.setFlashMessage('[N] NITRO BALONU! (+40% Nitro)', ANSI.fg.brightCyan, 22);
          }
          this.entities.splice(i, 1);
        }
      }
    }
  }

  triggerGameOver(reason) {
    this.state = 'GAMEOVER';
    this.crashReason = reason;
    if (this.score >= this.highScore) {
      this.highScore = Math.floor(this.score);
      saveHighScore(this.highScore);
    }
  }

  // --------------------------------------------------------------------------
  // RENDERING (PURE ANSI / ASCII FRAMEBUFFER)
  // --------------------------------------------------------------------------
  buildPlayfieldRow(r, theme) {
    // 1. Roadside Scenery (3 chars each side)
    const treeCycle = (r + this.scrollTick) % 5;
    const leftScenery = treeCycle === 0 ? `${theme.tree} ▲ ${ANSI.reset}` : (treeCycle === 2 ? `${ANSI.fg.gray} · ${ANSI.reset}` : '   ');
    const rightScenery = treeCycle === 2 ? `${theme.tree} ▲ ${ANSI.reset}` : (treeCycle === 4 ? `${ANSI.fg.gray} · ${ANSI.reset}` : '   ');

    // 2. Curb (1 char each side)
    const curbColor = ((r + this.scrollTick) % 2 === 0) ? theme.curbA : theme.curbB;
    const curb = `${curbColor}█${ANSI.reset}`;

    // 3. Build 4 lanes
    const lanesOut = [];
    for (let lane = 0; lane < NUM_LANES; lane++) {
      let cellContent = ' '.repeat(LANE_WIDTH);

      // Check entities in this lane covering row r
      for (const ent of this.entities) {
        if (ent.lane === lane && r >= ent.row && r < ent.row + ent.height) {
          const spriteLine = ent.sprite[r - ent.row];
          cellContent = ` ${ent.color}${ANSI.bold}${spriteLine}${ANSI.reset} `;
          break;
        }
      }

      // Check player car in this lane covering row r
      if (lane === this.playerLane && r >= this.playerRow && r < this.playerRow + CAR_HEIGHT) {
        const spriteIdx = r - this.playerRow;
        if (this.state === 'GAMEOVER') {
          cellContent = ` ${ANSI.fg.brightRed}${ANSI.bold}${SPRITES.crash[spriteIdx]}${ANSI.reset} `;
        } else {
          const carColor = this.nitroActive ? ANSI.fg.brightWhite : theme.player;
          cellContent = ` ${carColor}${ANSI.bold}${SPRITES.player[spriteIdx]}${ANSI.reset} `;
        }
      } else if (
        // Nitro exhaust flame directly below player car
        this.state === 'PLAYING' &&
        this.nitroActive &&
        lane === this.playerLane &&
        r === this.playerRow + CAR_HEIGHT
      ) {
        const flame = (this.frameCount % 2 === 0) ? '  ▼▼▼  ' : ' ░▒▓▒░ ';
        cellContent = ` ${ANSI.fg.brightYellow}${ANSI.bold}${flame}${ANSI.reset} `;
      } else if (
        // Headlight beams 1-2 rows ahead of player car
        this.state === 'PLAYING' &&
        lane === this.playerLane &&
        (r === this.playerRow - 1 || r === this.playerRow - 2) &&
        stripAnsi(cellContent).trim() === ''
      ) {
        cellContent = ` ${ANSI.fg.gray} ░   ░ ${ANSI.reset} `;
      }

      lanesOut.push(cellContent);
    }

    // 4. Lane dividers
    const isDash = ((r + this.scrollTick) % 3) !== 0;
    const divider = isDash ? `${theme.lane}│${ANSI.reset}` : ' ';

    return leftScenery + curb + lanesOut.join(divider) + curb + rightScenery;
  }

  buildHudPanel(theme) {
    const speed = Math.floor(this.currentSpeed);
    const speedRatio = speed / 360;
    const fuelColor = this.fuel < 25 ? ANSI.fg.brightRed : ANSI.fg.brightGreen;

    const lines = [
      centerVisible(`${theme.hudTitle}${ANSI.bold}═══ HOPE RACER ═══${ANSI.reset}`, HUD_WIDTH),
      ` Tema : ${ANSI.fg.brightCyan}${theme.name}${ANSI.reset}`,
      `────────────────────────────`,
      ` XAL (SCORE)  : ${ANSI.fg.brightWhite}${ANSI.bold}${Math.floor(this.score)}${ANSI.reset}`,
      ` REKORD (TOP) : ${ANSI.fg.brightYellow}${ANSI.bold}${this.highScore}${ANSI.reset}`,
      ` SEVIYYE (LVL): ${ANSI.fg.brightMagenta}${ANSI.bold}${this.level}${ANSI.reset}   SIKKE: ${ANSI.fg.brightYellow}${this.coins}${ANSI.reset}`,
      ` MESAFE       : ${ANSI.fg.white}${this.distance.toFixed(2)} km${ANSI.reset}`,
      `────────────────────────────`,
      ` SURET: ${ANSI.fg.brightCyan}${ANSI.bold}${String(speed).padStart(3, ' ')} km/h${ANSI.reset}`,
      ` [${makeBar(speedRatio, 24, ANSI.fg.brightCyan)}]`,
      ` YANACAQ (FUEL): ${fuelColor}${Math.floor(this.fuel)}%${ANSI.reset}`,
      ` [${makeBar(this.fuel / 100, 24, fuelColor)}]`,
      ` NITRO (TURBO) : ${ANSI.fg.brightYellow}${Math.floor(this.nitroAmount)}%${ANSI.reset}`,
      ` [${makeBar(this.nitroAmount / 100, 24, ANSI.fg.brightYellow)}]`,
      `────────────────────────────`,
      ` ${ANSI.bold}IDAREETME (CONTROLS):${ANSI.reset}`,
      ` ${ANSI.fg.brightGreen}[A/D] / [◄/►]${ANSI.reset} : Zolaq sec`,
      ` ${ANSI.fg.brightGreen}[W/S] / [▲/▼]${ANSI.reset} : Qaz/Tormoz`,
      ` ${ANSI.fg.brightCyan}[SPACE]${ANSI.reset}       : Nitro Turbo`,
      ` ${ANSI.fg.brightYellow}[P]${ANSI.reset} Fasile   ${ANSI.fg.brightMagenta}[T]${ANSI.reset} Tema`,
      ` ${ANSI.fg.brightRed}[R]${ANSI.reset} Restart  ${ANSI.fg.brightRed}[Q]${ANSI.reset} Cixis`,
      `────────────────────────────`,
    ];

    return lines.map(l => padRightVisible(l, HUD_WIDTH));
  }

  renderFrame() {
    const theme = THEMES[this.themeIndex];
    const b = theme.border;
    const rst = ANSI.reset;

    const topBorder = `${b}╔${'═'.repeat(PLAYFIELD_WIDTH)}╦${'═'.repeat(HUD_WIDTH)}╗${rst}`;
    const midDivider = `${b}╠${'═'.repeat(PLAYFIELD_WIDTH)}╩${'═'.repeat(HUD_WIDTH)}╣${rst}`;
    const botBorder = `${b}╚${'═'.repeat(PLAYFIELD_WIDTH + 1 + HUD_WIDTH)}╝${rst}`;

    const hudLines = this.buildHudPanel(theme);
    const rows = [topBorder];

    for (let r = 0; r < ROAD_ROWS; r++) {
      let roadLine = this.buildPlayfieldRow(r, theme);

      // Overlays for MENU, PAUSED, GAMEOVER
      if (this.state === 'MENU' && r >= 6 && r <= 13) {
        const menuBox = [
          `${ANSI.fg.brightCyan}╔═════════════════════════════════════╗${rst}`,
          `${ANSI.fg.brightCyan}║${rst}   ${ANSI.fg.brightYellow}${ANSI.bold}>> HOPE: TERMINAL HIGHWAY RACER <<${rst}${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}║${rst}      Tamamile HTML-siz Node.js      ${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}║${rst}                                     ${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}║${rst}   Sikkeleri ($) ve Yanacagi (F)     ${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}║${rst}     toplayin, masinlardan qacin!    ${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}║${rst}  ${ANSI.fg.brightGreen}${ANSI.bold}>> BASLAMAQ UCUN [SPACE] BASIN <<${rst}  ${ANSI.fg.brightCyan}║${rst}`,
          `${ANSI.fg.brightCyan}╚═════════════════════════════════════╝${rst}`,
        ];
        roadLine = centerVisible(menuBox[r - 6], PLAYFIELD_WIDTH);
      } else if (this.state === 'PAUSED' && r >= 8 && r <= 12) {
        const pauseBox = [
          `${ANSI.fg.brightYellow}╔═══════════════════════════════╗${rst}`,
          `${ANSI.fg.brightYellow}║${rst}       ${ANSI.bold}OYUN DAYANDIRILDI${rst}       ${ANSI.fg.brightYellow}║${rst}`,
          `${ANSI.fg.brightYellow}║${rst}                               ${ANSI.fg.brightYellow}║${rst}`,
          `${ANSI.fg.brightYellow}║${rst}      Davam et : ${ANSI.fg.brightGreen}[P]${rst}           ${ANSI.fg.brightYellow}║${rst}`,
          `${ANSI.fg.brightYellow}╚═══════════════════════════════╝${rst}`,
        ];
        roadLine = centerVisible(pauseBox[r - 8], PLAYFIELD_WIDTH);
      } else if (this.state === 'GAMEOVER' && r >= 6 && r <= 13) {
        const overBox = [
          `${ANSI.fg.brightRed}╔═════════════════════════════════════╗${rst}`,
          `${ANSI.fg.brightRed}║${rst}          ${ANSI.fg.brightRed}${ANSI.bold}!! QEZA BAS VERDI !!${rst}       ${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}║${rst}  ${centerVisible(this.crashReason, 33)}  ${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}║${rst}                                     ${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}║${rst}  Toplam Xal : ${ANSI.fg.brightWhite}${ANSI.bold}${String(Math.floor(this.score)).padEnd(20, ' ')}${rst}  ${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}║${rst}  Rekord Xal : ${ANSI.fg.brightYellow}${ANSI.bold}${String(this.highScore).padEnd(20, ' ')}${rst}  ${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}║${rst}   ${ANSI.fg.brightGreen}${ANSI.bold}Yeniden: [R] / [SPACE]${rst}  Cixis: ${ANSI.fg.brightRed}[Q]${rst}${ANSI.fg.brightRed}║${rst}`,
          `${ANSI.fg.brightRed}╚═════════════════════════════════════╝${rst}`,
        ];
        roadLine = centerVisible(overBox[r - 6], PLAYFIELD_WIDTH);
      }

      const paddedRoad = padRightVisible(roadLine, PLAYFIELD_WIDTH);
      const hudLine = hudLines[r] || ' '.repeat(HUD_WIDTH);
      rows.push(`${b}║${rst}${paddedRoad}${b}║${rst}${hudLine}${b}║${rst}`);
    }

    rows.push(midDivider);

    // Status bar at the bottom
    const statusText = this.statusTimer > 0
      ? `${this.statusColor}${ANSI.bold} STATUS: ${this.statusMessage}${rst}`
      : `${ANSI.fg.gray} STATUS: Zolaq ${this.playerLane + 1}/4 | Nitro ucun [SPACE], Tema ucun [T], Cixis ucun [Q]${rst}`;
    rows.push(`${b}║${rst}${padRightVisible(statusText, PLAYFIELD_WIDTH + 1 + HUD_WIDTH)}${b}║${rst}`);
    rows.push(botBorder);

    return rows.join('\n');
  }

  // --------------------------------------------------------------------------
  // LIFECYCLE & TERMINAL LOOP
  // --------------------------------------------------------------------------
  start() {
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) {
      process.stdin.setRawMode(true);
    }
    process.stdin.resume();

    process.stdin.on('keypress', (str, key) => {
      if (key && key.ctrl && key.name === 'c') {
        this.quit();
        return;
      }
      this.handleInput(key ? key.name : '', str);
    });

    process.on('SIGINT', () => this.quit());
    process.on('exit', () => {
      process.stdout.write(ANSI.showCursor + ANSI.reset);
    });

    process.stdout.write(ANSI.clear + ANSI.hideCursor);

    this.loopId = setInterval(() => {
      this.update();
      const frame = this.renderFrame();
      process.stdout.write(ANSI.home + frame);
    }, 55); // ~18 FPS crisp terminal tick
  }

  quit() {
    if (this.loopId) clearInterval(this.loopId);
    process.stdout.write(ANSI.showCursor + ANSI.reset + '\n');
    console.log(`${ANSI.fg.brightCyan}Oyun bitdi! Son Xal: ${Math.floor(this.score)} | Rekord: ${this.highScore}${ANSI.reset}`);
    process.exit(0);
  }
}

// ============================================================================
// SELF-TEST SUITE (--test)
// ============================================================================
function runSelfTests() {
  const assert = require('assert');
  console.log('Running Hope Terminal Racer automated self-tests...');

  const verifyAlignment = (game, stateLabel) => {
    const rendered = game.renderFrame();
    const lines = rendered.split('\n');
    assert.strictEqual(lines.length, ROAD_ROWS + 4, `[${stateLabel}] Frame should have ${ROAD_ROWS + 4} rows`);
    for (let i = 0; i < lines.length; i++) {
      const visibleWidth = stripAnsi(lines[i]).length;
      assert.strictEqual(
        visibleWidth,
        PLAYFIELD_WIDTH + HUD_WIDTH + 3,
        `[${stateLabel}] Row ${i} visible width (${visibleWidth}) must equal ${PLAYFIELD_WIDTH + HUD_WIDTH + 3}`
      );
    }
  };

  const game = new TerminalRacer();
  assert.strictEqual(game.state, 'MENU', 'Initial state should be MENU');
  verifyAlignment(game, 'MENU');

  // Start game via Space
  game.handleInput('space', ' ');
  assert.strictEqual(game.state, 'PLAYING', 'State should transition to PLAYING');
  assert.strictEqual(game.playerLane, 1, 'Initial lane should be 1');
  verifyAlignment(game, 'PLAYING');

  // Test steering
  game.handleInput('right', '');
  assert.strictEqual(game.playerLane, 2, 'Should move right to lane 2');
  game.handleInput('left', '');
  assert.strictEqual(game.playerLane, 1, 'Should move left back to lane 1');

  // Test Pause & Resume
  game.handleInput('p', 'p');
  assert.strictEqual(game.state, 'PAUSED', 'Should pause game');
  verifyAlignment(game, 'PAUSED');
  game.handleInput('p', 'p');
  assert.strictEqual(game.state, 'PLAYING', 'Should resume game');

  // Test Nitro activation
  game.handleInput('space', ' ');
  assert.strictEqual(game.nitroActive, true, 'Nitro should activate');
  verifyAlignment(game, 'PLAYING+NITRO');

  // Test coin pickup
  const scoreBefore = game.score;
  game.entities.push({
    type: 'coin',
    isObstacle: false,
    lane: game.playerLane,
    row: game.playerRow,
    height: 3,
    color: ANSI.fg.brightYellow,
    sprite: SPRITES.coin,
  });
  game.checkCollisions();
  assert.strictEqual(game.coins, 1, 'Coin count should increment');
  assert.ok(game.score >= scoreBefore + 100, 'Score should increase by 100 on coin pickup');
  verifyAlignment(game, 'COIN_PICKUP');

  // Test obstacle collision -> GAMEOVER
  game.entities.push({
    type: 'car',
    isObstacle: true,
    lane: game.playerLane,
    row: game.playerRow,
    height: 4,
    color: ANSI.fg.brightRed,
    sprite: SPRITES.enemySports,
  });
  game.checkCollisions();
  assert.strictEqual(game.state, 'GAMEOVER', 'Obstacle overlap should trigger GAMEOVER');
  verifyAlignment(game, 'GAMEOVER');

  console.log('✔ All automated self-tests passed! Frame alignment and game mechanics verified.');
}

if (process.argv.includes('--test')) {
  runSelfTests();
} else if (process.argv.includes('--preview')) {
  const game = new TerminalRacer();
  game.state = 'PLAYING';
  game.nitroActive = true;
  game.score = 1480;
  game.highScore = 2450;
  game.coins = 7;
  game.level = 2;
  game.distance = 3.45;
  game.entities = [
    { type: 'car', isObstacle: true, lane: 0, row: 3, height: 4, color: ANSI.fg.brightRed, sprite: SPRITES.enemySports },
    { type: 'truck', isObstacle: true, lane: 2, row: 8, height: 4, color: ANSI.fg.brightMagenta, sprite: SPRITES.enemyTruck },
    { type: 'coin', isObstacle: false, lane: 1, row: 11, height: 3, color: ANSI.fg.brightYellow, sprite: SPRITES.coin },
    { type: 'fuel', isObstacle: false, lane: 3, row: 14, height: 3, color: ANSI.fg.brightGreen, sprite: SPRITES.fuel },
  ];
  console.log(game.renderFrame());
} else {
  const game = new TerminalRacer();
  game.start();
}
