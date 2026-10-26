// -------------------------------------
// MIDIUS 
// A Musical Arcade Game
// Kalu Obasi
// MUSIC 256A / CS 476A
// -------------------------------------

// Core window, camera, and ship setup
GG.fullscreen();


GWindow win;
win.title("MIDIUS");




1 => int TITLE_MODE;

GCamera cam --> GG.scene();
cam.pos(0, 0, 8);
cam.lookAt(@(0, 0, 0));

GCube ship --> GG.scene();
@(0.35, 0.35, 0.001) => ship.sca;
@(2.0, 2.0, 2.0) => ship.color;
ship.pos(0, 0, 0);

GCube shipIndicator --> GG.scene();
@(0.15, 0.05, 0.001) => shipIndicator.sca;
@(2.0, 2.0, 2.0) => shipIndicator.color;
shipIndicator.pos(0, 0.5, 0);


if (TITLE_MODE)
{
    ship.sca(@(0.0, 0.0, 0.0));
    shipIndicator.sca(@(0.0, 0.0, 0.0));
}
else
{
    @(0.35, 0.35, 0.001) => ship.sca;
}

time gameStartTime;
now => gameStartTime;

// Audio buffers and global SFX
SndBuf gameOverSFX => dac;

me.dir() + "gameover.wav"
    => gameOverSFX.read;
0 => gameOverSFX.gain;

fun void playGameOverSound()
{
    0 => gameOverSFX.pos;
    1.0 => gameOverSFX.gain;
}

SndBuf sfxShield  => dac;
SndBuf sfxHeal    => dac;
SndBuf sfxDouble  => dac;
SndBuf sfxBomb    => dac;
SndBuf sfxHP;

Bitcrusher crusher;
crusher.bits(4);
crusher.downsampleFactor(6);
SndBuf titleSFX => dac;
SndBuf startGameSFX => dac;
sfxHP => crusher => dac;

me.dir() + "shield_collect.wav"
    => sfxShield.read;
0 => sfxShield.gain;

me.dir() + "heal_collect.wav"
    => sfxHeal.read;
0 => sfxHeal.gain;

me.dir() + "double_collect.wav"
    => sfxDouble.read;
0 => sfxDouble.gain;

me.dir() + "bomb_collect.wav"
    => sfxBomb.read;
0 => sfxBomb.gain;

"special:dope" => sfxHP.read;
0 => sfxHP.gain;

me.dir() + "title.wav"
    => titleSFX.read;
0 => titleSFX.gain;

me.dir() + "startgame.wav"
    => startGameSFX.read;
0 => startGameSFX.gain;

fun void playOnce(SndBuf @buf, float gain)
{
    0 => buf.pos;
    gain => buf.gain;
    1 => buf.rate;
    buf.length() => now;
    0 => buf.rate;
}

fun void playShieldSFX() { playOnce(sfxShield, 1.0); }
fun void playHealSFX()   { playOnce(sfxHeal,   1.0); }
fun void playDoubleSFX() { playOnce(sfxDouble, 1.0); }
fun void playBombSFX()   { playOnce(sfxBomb,   1.0); }
fun void playHitSFX()    { playOnce(sfxHP,     0.8); }

fun void playBulletTone(int midiNote, int velocity)
{
    PulseOsc osc => Bitcrusher crush => ADSR env => dac;
    Std.mtof(midiNote) => osc.freq;
    0.5 => osc.width;
    (velocity / 127.0) * 0.2 => float baseGain;
    baseGain => osc.gain;
    crush.bits(7);
    crush.downsampleFactor(3);
    env.set(
        5::ms,
        40::ms,
        0.0,
        60::ms
    );
    env.keyOn();
    80::ms => now;
    env.keyOff();
    80::ms => now;
    osc =< dac;
}

fun void playBombBulletTone(int midiNote)
{
    PulseOsc p => Bitcrusher bc => ADSR env => dac;
    Std.mtof(midiNote) => float baseFreq;
    baseFreq => p.freq;
    0.5 => p.gain;
    5  => bc.bits;
    6  => bc.downsample;
    env.set(5::ms, 90::ms, 0.2, 120::ms);
    env.keyOn();
    for (int i; i < 4; i++)
    {
        (baseFreq * (1.0 + 0.06 * i)) => p.freq;
        15::ms => now;
    }
    env.keyOff();
    100::ms => now;
    p =< bc =< env =< dac;
}

fun void playBombExplosionSFX()
{
    Noise n => Bitcrusher bc => BPF f => ADSR env => dac;
    0.6 => n.gain;
    1800.0 => f.freq;
    6.0    => f.Q;
    6  => bc.bits;
    8  => bc.downsample;
    env.set(3::ms, 120::ms, 0.0, 80::ms);
    env.keyOn();
    150::ms => now;
    env.keyOff();
    60::ms => now;
    n =< bc =< f =< env =< dac;
}

fun void playNeutralExplosion()
{
    Noise n => BPF f => Bitcrusher crush => ADSR env => dac;
    0.8 => n.gain;
    1800.0 => f.freq;
    6.0    => f.Q;
    crush.bits(4);
    crush.downsampleFactor(8);
    env.set(
        2::ms,
        80::ms,
        0.0,
        60::ms
    );
    env.keyOn();
    120::ms => now;
    env.keyOff();
    60::ms => now;
    env =< dac;
}

fun void playColorExplosion(int pitchClass)
{
    TriOsc osc => Bitcrusher crush => ADSR env => dac;
    0.2 => osc.gain;
    crush.bits(5);
    crush.downsampleFactor(4);
    env.set(
        3::ms,
        100::ms,
        0.0,
        80::ms
    );
    pitchClass % 12 => int pc;
    60 + pc => int rootMidi;
    [0, 4, 7, 12] @=> int intervals[];
    50::ms => dur stepDur;
    env.keyOn();
    for (int i; i < intervals.size(); i++)
    {
        Std.mtof(rootMidi + intervals[i]) => osc.freq;
        stepDur => now;
    }
    env.keyOff();
    80::ms => now;
    env =< dac;
}

fun void playShieldPad(dur howLong)
{
    SawOsc s => LPF f => Bitcrusher crush => ADSR env => dac;
    100.0 => s.freq;
    0.05  => s.gain;
    1200.0 => f.freq;
    1.0    => f.Q;
    crush.bits(6);
    crush.downsampleFactor(3);
    80::ms  => dur atk;
    200::ms => dur dec;
    0.5     => float sus;
    200::ms => dur rel;
    env.set(atk, dec, sus, rel);
    howLong - (atk + rel) => dur sustainTime;
    if (sustainTime < 0::ms) 0::ms => sustainTime;
    env.keyOn();
    (atk + dec + sustainTime) => now;
    env.keyOff();
    rel => now;
    env =< dac;
}

fun void playDoublePointsGliss()
{
    SqrOsc osc => Bitcrusher crush => ADSR env => dac;
    0.18 => osc.gain;
    crush.bits(5);
    crush.downsampleFactor(5);
    env.set(
        5::ms,
        120::ms,
        0.0,
        80::ms
    );
    [0, 2, 4, 7, 9, 12] @=> int intervals[];
    55 => int baseMidi;
    80::ms => dur stepDur;
    env.keyOn();
    for (int i; i < intervals.size(); i++)
    {
        Std.mtof(baseMidi + intervals[i]) => osc.freq;
        stepDur => now;
    }
    env.keyOff();
    100::ms => now;
    env =< dac;
}

// Score display
0 => int SCORE;

me.dir() + "PressStart2P-vaV7.ttf" 
    => string pixelFont;

vec3 SCORE_COLOR_NORMAL;
vec3 SCORE_COLOR_DOUBLE;

@(1.5, 1.5, 1.5) => SCORE_COLOR_NORMAL;
@(2.0, 2.0, 0.2) => SCORE_COLOR_DOUBLE;

GText scoreText;
scoreText --> GG.scene();
scoreText.pos(1.5, 1.9, 0);
SCORE_COLOR_NORMAL => scoreText.color;
scoreText.sca(0.15);
scoreText.font(pixelFont);

fun void refreshScoreText()
{
    scoreText.text("POINTS: " + SCORE);
}

if (TITLE_MODE)
{
    scoreText.text("");
}
else
{
    refreshScoreText();
}

// Hit points and game over state
10 => int MAX_HP;
5 => int HP;
0 => int GAME_OVER;

GText hpText;
hpText --> GG.scene();
hpText.pos(-1.9, 1.9, 0);
hpText.color(@(1.5, 1.5, 1.5));
hpText.sca(0.15);
hpText.font(pixelFont);

fun void refreshHPText()
{
    hpText.text("HP: " + HP);
}

if (TITLE_MODE)
{
    hpText.text("");
}
else
{
    refreshHPText();
}

// MIDI input configuration
MidiIn min;
MidiMsg msg;

0 => int midiDevice;

if (!min.open(midiDevice))
{
    <<< "Could not open MIDI device", midiDevice >>>;
    me.exit();
}
else
{
    <<< "Opened MIDI device", midiDevice >>>;
}

93 => int TARGET_CC;
string midiDeviceName;
min.name() => midiDeviceName;

// Title screen and UI text objects
GText titleText;
titleText --> GG.scene();
titleText.font(pixelFont);
titleText.align(2);
titleText.sca(0.4);
titleText.color(@(1.0, 0.30, 0.30));
titleText.pos(0, 0.8, 0);
titleText.text("MIDIUS");

GText subtitleText;
subtitleText --> GG.scene();
subtitleText.font(pixelFont);
subtitleText.align(2);
subtitleText.sca(0.18);
subtitleText.color(@(0.30, 1.0, 0.30));
subtitleText.pos(0, 0.0, 0);
subtitleText.text("A GAME ABOUT A SQUARE\nSHOOTING SQUARES \nAT OTHER SQUARES\n(AMONG OTHER THINGS)");

GText midiDeviceText;
midiDeviceText --> GG.scene();
midiDeviceText.font(pixelFont);
midiDeviceText.align(2);
midiDeviceText.sca(0.14);
midiDeviceText.color(@(0.30, 0.30, 1.0));
midiDeviceText.pos(0, -0.8, 0);
midiDeviceText.text("YOUR MIDI DEVICE: " + midiDeviceName);

GText titlePromptText;
titlePromptText --> GG.scene();
titlePromptText.font(pixelFont);
titlePromptText.align(2);
titlePromptText.sca(0.16);
titlePromptText.color(@(2.0, 2.0, 2.0));
titlePromptText.pos(0, -1.5, 0);
titlePromptText.text("PRESS ANY KEY TO START");

spork ~ playOnce(titleSFX, 0.9);

GText gameOverText;
gameOverText --> GG.scene();
gameOverText.font(pixelFont);
gameOverText.sca(0.35);
gameOverText.color(@(2.0, 0.1, 0.1));
gameOverText.pos(0, 0.0, 0);
gameOverText.text("");

GText restartText;
restartText --> GG.scene();
restartText.font(pixelFont);
restartText.sca(0.18);
restartText.color(@(1.5, 1.5, 1.5));
restartText.pos(0, -0.4, 0);
restartText.text("");

// Shield power-up state
0 => int SHIELD_ACTIVE;
5::second => dur SHIELD_DURATION;
time shieldEndTime;

0.25 => float SHIP_COLLISION_RADIUS;
1 => float SHIELD_COLLISION_RADIUS;

GTorus shieldRing --> GG.scene();
shieldRing.sca(@(0.0, 0.0, 0.0));
shieldRing.color(@(1.8, 1.8, 1.8));
shieldRing.pos(0, 0, 0);

// Double-points (score multiplier) state
0 => int DOUBLE_POINTS_ACTIVE;
5::second => dur DOUBLE_POINTS_DURATION;
time doubleEndTime;

// Bomb mode (AoE bullets) state
0 => int BOMB_MODE_ACTIVE;
5::second => dur BOMB_DURATION;
time bombEndTime;

// Pitch-class color palette (12-tone)
vec3 PITCH_CLASS_COLORS[12];

@(1.00, 0.10, 0.10) => PITCH_CLASS_COLORS[0];
@(1.00, 0.30, 0.05) => PITCH_CLASS_COLORS[1];
@(1.00, 0.50, 0.00) => PITCH_CLASS_COLORS[2];
@(1.00, 0.90, 0.00) => PITCH_CLASS_COLORS[3];
@(0.50, 1.00, 0.00) => PITCH_CLASS_COLORS[4];
@(0.00, 1.00, 0.20) => PITCH_CLASS_COLORS[5];
@(0.00, 1.00, 1.00) => PITCH_CLASS_COLORS[6];
@(0.00, 0.40, 1.00) => PITCH_CLASS_COLORS[7];
@(0.40, 0.00, 1.00) => PITCH_CLASS_COLORS[8];
@(0.70, 0.00, 1.00) => PITCH_CLASS_COLORS[9];
@(1.00, 0.00, 0.80) => PITCH_CLASS_COLORS[10];
@(1.00, 0.00, 0.40) => PITCH_CLASS_COLORS[11];

fun string pcToName(int pc)
{
    pc % 12 => pc;
    if (pc == 0)  return "C";
    if (pc == 1)  return "C#";
    if (pc == 2)  return "D";
    if (pc == 3)  return "D#";
    if (pc == 4)  return "E";
    if (pc == 5)  return "F";
    if (pc == 6)  return "F#";
    if (pc == 7)  return "G";
    if (pc == 8)  return "G#";
    if (pc == 9)  return "A";
    if (pc == 10) return "A#";
    return "B";
}

// Rotation state derived from encoder CC
0.0 => float rotationAngle;

fun float mapCCtoDegrees(float ccVal)
{
    return (ccVal / 127.0) * 360.0;
}

// Bullet projectile entity
class Bullet
{
    GCube shape;
    float x, y, z;
    float vx, vy, vz;
    float speed;
    int alive;
    int pitchClass;
    int isBomb;

    fun void init(float startX, float startY, float startZ,
                  float dirX, float dirY)
    {
        shape --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        4.0 => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.1, 0.1, 0.001));
        shape.pos(x, y, z);
        @(1.0, 0.9, 0.3) => shape.color;
        0 => isBomb;
        1 => alive;
    }

    fun void setBombStyle()
    {
        shape.sca(@(0.18, 0.18, 0.001));
        @(2.0, 0.4, 0.1) => shape.color;
        1 => isBomb;
    }

    fun void setColor(vec3 c)
    {
        shape.color(c);
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        if (x < -6.0 || x > 6.0 || y < -6.0 || y > 6.0)
        {
            destroy();
        }
    }
}

Bullet bullets[0];

// Neutral enemy entity
class Enemy
{
    GCube shape;
    float x, y, z;
    float vx, vy, vz;
    float speed;
    int alive;

    fun void init(float startX, float startY, float startZ, float spd)
    {
        shape --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        spd => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.2, 0.2, 0.001));
        shape.pos(x, y, z);
        @(1.5, 1.5, 1.5) => shape.color;
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        Math.sqrt(x*x + y*y) => float dist;
        if (SHIELD_ACTIVE && dist < SHIELD_COLLISION_RADIUS)
        {
            <<< "Enemy destroyed by shield!" >>>;
            spawnExplosion(x, y, @(1.3, 1.3, 1.3));
            destroy();
            return;
        }
        if (!SHIELD_ACTIVE && dist < SHIP_COLLISION_RADIUS)
        {
            <<< "Enemy reached the ship!" >>>;
            enemyHitShip();
            destroy();
            return;
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

Enemy enemies[0];

// Colored (pitch-locked) enemy entity
class EnemyColor
{
    GCube shape;
    GText label;
    float x, y, z;
    float vx, vy, vz;
    float speed;
    int alive;
    int pitchClass;

    fun void init(float startX, float startY, float startZ, int pc, float spd)
    {
        shape --> GG.scene();
        label --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        pc % 12 => pitchClass;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        spd => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.25, 0.25, 0.001));
        shape.pos(x, y, z);
        PITCH_CLASS_COLORS[pitchClass] => shape.color;
        label.font(pixelFont);
        label.text(pcToName(pitchClass));
        label.sca(0.12);
        label.color(@(1, 1, 1));
        label.pos(x, y, z + 0.001);
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
            label --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        label.pos(x, y, z + 0.01);
        Math.sqrt(x*x + y*y) => float dist;
        if (SHIELD_ACTIVE && dist < SHIELD_COLLISION_RADIUS)
        {
            <<< "Color enemy destroyed by shield!" >>>;
            PITCH_CLASS_COLORS[pitchClass] => vec3 c;
            spawnExplosion(x, y, c);
            destroy();
            return;
        }
        if (!SHIELD_ACTIVE && dist < SHIP_COLLISION_RADIUS)
        {
            <<< "Color enemy reached the ship!" >>>;
            enemyHitShip();
            destroy();
            return;
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

EnemyColor colorEnemies[0];

// Particle used for explosion / shatter effects
class Particle
{
    GCube shape;
    float x, y, z;
    float vx, vy, vz;
    float life;
    float maxLife;
    int   alive;

    fun void init(float startX, float startY, float startZ, vec3 baseColor)
    {
        shape --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        shape.sca(@(0.06, 0.06, 0.001));
        Std.rand2f(-1.0, 1.0) => float dx;
        Std.rand2f(-1.0, 1.0) => float dy;
        Math.sqrt(dx*dx + dy*dy) => float mag;
        if (mag == 0.0) { 0.0 => dx; 1.0 => dy; 1.0 => mag; }
        dx / mag => dx;
        dy / mag => dy;
        Std.rand2f(2.0, 5.0) => float speed;
        dx * speed => vx;
        dy * speed => vy;
        0.0        => vz;
        Std.rand2f(0.8, 1.2) => float k;
        @(baseColor.x * k, baseColor.y * k, baseColor.z * k) => vec3 c;
        shape.color(c);
        shape.pos(x, y, z);
        0.5 => maxLife;
        maxLife => life;
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        life - dt => life;
        if (life <= 0)
        {
            destroy();
            return;
        }
        (life / maxLife) => float a;
        shape.color(@(shape.color().x * a, 
                      shape.color().y * a, 
                      shape.color().z * a));
    }
}

// Active particles list
Particle particles[0];

// Spawn a burst of particles at a position
fun void spawnExplosion(float cx, float cy, vec3 baseColor)
{
    16 => int NUM_PARTICLES;
    for (int i; i < NUM_PARTICLES; i++)
    {
        Particle p;
        p.init(cx, cy, 0.0, baseColor);
        particles << p;
    }
}

// Shield power-up orb
class PowerUpShield
{
    GSphere shape;       
    float x, y, z;
    float vx, vy, vz;
    float speed;
    int alive;
    GText label;

    fun void init(float startX, float startY, float startZ)
    {
        shape --> GG.scene();
        label --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        0.9 => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.22, 0.22, 0.001));
        shape.pos(x, y, z);
        label.font(pixelFont);
        label.text("S");
        label.sca(0.15);
        label.color(@(2.0, 2.0, 2.0));
        label.pos(x, y, z + 0.01);
        @(0.0, 0.0, 1.5) => shape.color;
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
            label --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        label.pos(x, y, z + 0.01);
        Math.sqrt(x*x + y*y) => float dist;
        if (dist < 0.25)
        {
            <<< "Shield power-up passed by (not collected)" >>>;
            destroy();
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

PowerUpShield shieldPowerUps[0];

fun void spawnShieldPowerUp()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    PowerUpShield p;
    p.init(ex, ey, 0.0);
    shieldPowerUps << p;
    <<< "Spawning SHIELD power-up..." >>>;
}

// Heal power-up orb
class PowerUpHeal
{
    GSphere shape;
    GText   label;

    float x, y, z;
    float vx, vy, vz;
    float speed;
    int   alive;

    fun void init(float startX, float startY, float startZ)
    {
        shape --> GG.scene();
        label --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        0.8 => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.22, 0.22, 0.001));
        shape.pos(x, y, z);
        @(1.5, 0.0, 0.0) => shape.color;
        label.font(pixelFont);
        label.text("+");
        label.sca(0.2);
        label.color(@(2.0, 2.0, 2.0));
        label.pos(x, y, z + 0.01);
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
            label --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        label.pos(x, y, z + 0.01);
        Math.sqrt(x*x + y*y) => float dist;
        if (dist < 0.25)
        {
            <<< "Heal power-up passed by (not collected)" >>>;
            destroy();
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

PowerUpHeal healPowerUps[0];

fun void spawnHealPowerUp()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    PowerUpHeal p;
    p.init(ex, ey, 0.0);
    healPowerUps << p;
    <<< "Spawning HEAL power-up..." >>>;
}

// Double-points (x2) power-up orb
class PowerUpDouble
{
    GSphere shape;
    GText   label;

    float x, y, z;
    float vx, vy, vz;
    float speed;
    int   alive;

    fun void init(float startX, float startY, float startZ)
    {
        shape --> GG.scene();
        label --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        0.85 => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.22, 0.22, 0.001));
        shape.pos(x, y, z);
        @(0.0, 1.5, 0.0) => shape.color;
        label.font(pixelFont);
        label.text("x2");
        label.sca(0.10);
        label.color(@(2.0, 2.0, 2.0));
        label.pos(x, y, z + 0.01);
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
            label --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        label.pos(x, y, z + 0.01);
        Math.sqrt(x*x + y*y) => float dist;
        if (dist < 0.25)
        {
            <<< "Double-points power-up passed by (not collected)" >>>;
            destroy();
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

PowerUpDouble doublePowerUps[0];

fun void spawnDoublePowerUp()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    PowerUpDouble p;
    p.init(ex, ey, 0.0);
    doublePowerUps << p;
    <<< "Spawning DOUBLE-POINTS power-up..." >>>;
}

// Bomb (AoE mode) power-up orb
class PowerUpBomb
{
    GSphere shape;
    GText   label;

    float x, y, z;
    float vx, vy, vz;
    float speed;
    int   alive;

    fun void init(float startX, float startY, float startZ)
    {
        shape --> GG.scene();
        label --> GG.scene();
        startX => x;
        startY => y;
        startZ => z;
        -x => float dirX;
        -y => float dirY;
        Math.sqrt(dirX*dirX + dirY*dirY) => float mag;
        if (mag == 0.0)
        {
            0.0 => dirX;
            -1.0 => dirY;
            1.0 => mag;
        }
        dirX / mag => dirX;
        dirY / mag => dirY;
        0.9 => speed;
        dirX * speed => vx;
        dirY * speed => vy;
        0.0          => vz;
        shape.sca(@(0.22, 0.22, 0.001));
        shape.pos(x, y, z);
        @(1.5, 0.7, 0.0) => shape.color;
        label.font(pixelFont);
        label.text("!");
        label.sca(0.15);
        label.color(@(0.0, 0.0, 0.0));
        label.pos(x, y, z + 0.01);
        1 => alive;
    }

    fun void destroy()
    {
        if (alive)
        {
            0 => alive;
            shape --< GG.scene();
            label --< GG.scene();
        }
    }

    fun void update(float dt)
    {
        if (!alive) return;
        x + vx * dt => x;
        y + vy * dt => y;
        shape.pos(x, y, z);
        label.pos(x, y, z + 0.01);
        Math.sqrt(x*x + y*y) => float dist;
        if (dist < 0.25)
        {
            <<< "Bomb power-up passed by (not collected)" >>>;
            destroy();
        }
        if (x < -7.0 || x > 7.0 || y < -7.0 || y > 7.0)
        {
            destroy();
        }
    }
}

PowerUpBomb bombPowerUps[0];

fun void spawnBombPowerUp()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    PowerUpBomb p;
    p.init(ex, ey, 0.0);
    bombPowerUps << p;
    <<< "Spawning BOMB power-up..." >>>;
}

// Bomb AoE helper: destroys nearby enemies and awards points
fun void bombExplode(float cx, float cy)
{
    1.5 => float radius;
    radius * radius => float radius2;
    for (int j; j < enemies.size(); j++)
    {
        if (!enemies[j].alive) continue;
        (enemies[j].x - cx) => float dx;
        (enemies[j].y - cy) => float dy;
        dx*dx + dy*dy => float d2;
        if (d2 <= radius2)
        {
            spawnExplosion(enemies[j].x, enemies[j].y, @(1.3, 1.3, 1.3));
            enemies[j].destroy();
            SCORE + (100 * scoreMultiplier()) => SCORE;
        }
    }
    for (int k; k < colorEnemies.size(); k++)
    {
        if (!colorEnemies[k].alive) continue;
        (colorEnemies[k].x - cx) => float dx;
        (colorEnemies[k].y - cy) => float dy;
        dx*dx + dy*dy => float d2;
        if (d2 <= radius2)
        {
            PITCH_CLASS_COLORS[colorEnemies[k].pitchClass] => vec3 c;
            spawnExplosion(colorEnemies[k].x, colorEnemies[k].y, c);
            colorEnemies[k].destroy();
            SCORE + (150 * scoreMultiplier()) => SCORE;
        }
    }
    refreshScoreText();
}

0 => int CLEAR_DONE;

// Returns current score multiplier (1x or 2x)
fun int scoreMultiplier()
{
    if (DOUBLE_POINTS_ACTIVE) return 2;
    return 1;
}

// Handles enemy collision with the ship and game-over transition
fun void enemyHitShip()
{
    if (GAME_OVER) return;
    if (SHIELD_ACTIVE)
    {
        <<< "Enemy hit shield (no damage)!" >>>;
        return;
    }
    HP--;
    refreshHPText();
    <<< "Ship hit! HP:", HP >>>;
    if (HP > 0)
    {
        spork ~ playHitSFX();
    }
    else if (HP <= 0)
    {
        1 => GAME_OVER;
        gameOverText.text("GAME  OVER");
        restartText.text("PRESS ANY KEY TO RESTART");
        <<< "GAME OVER" >>>;
        spawnShipShatter();
        spork ~ playGameOverSound();
        scoreText.text("");
        hpText.text("");
        0 => DOUBLE_POINTS_ACTIVE;
        SCORE_COLOR_NORMAL => scoreText.color;
    }
}

// Transition from title screen into gameplay
fun void startGameFromTitle()
{
    0 => TITLE_MODE;
    titleText.text("");
    subtitleText.text("");
    midiDeviceText.text("");
    titlePromptText.text("");
    0 => GAME_OVER;
    0 => CLEAR_DONE;
    spork ~ playOnce(startGameSFX, 0.9);
    resetGame();
}

// Reset all run-specific state for a fresh game
fun void resetGame()
{
    now => gameStartTime;
    @(0.35, 0.35, 0.001) => ship.sca;
    @(0.15, 0.05, 0.001) => shipIndicator.sca;
    0 => SCORE;
    refreshScoreText();
    0 => CLEAR_DONE;
    5 => HP;
    refreshHPText();
    0 => GAME_OVER;
    gameOverText.text("");
    restartText.text("");
    @(2.0, 2.0, 2.0) => ship.color;
    @(2.0, 2.0, 2.0) => shipIndicator.color;
    0.0 => rotationAngle;
    0 => SHIELD_ACTIVE;
    shieldRing.sca(@(0.0, 0.0, 0.0));
    0 => DOUBLE_POINTS_ACTIVE;
    SCORE_COLOR_NORMAL => scoreText.color;
    for (int i; i < bullets.size(); i++)
    {
        bullets[i].destroy();
    }
    bullets.size(0);
    for (int j; j < enemies.size(); j++)
    {
        enemies[j].destroy();
    }
    enemies.size(0);
    for (int k; k < colorEnemies.size(); k++)
    {
        colorEnemies[k].destroy();
    }
    colorEnemies.size(0);
    for (int s; s < shieldPowerUps.size(); s++)
    {
        shieldPowerUps[s].destroy();
    }
    shieldPowerUps.size(0);
    for (int h; h < healPowerUps.size(); h++)
    {
        healPowerUps[h].destroy();
    }
    healPowerUps.size(0);
    for (int d; d < doublePowerUps.size(); d++)
    {
        doublePowerUps[d].destroy();
    }
    doublePowerUps.size(0);
    for (int p; p < particles.size(); p++)
    {
        particles[p].destroy();
    }
    particles.size(0);
    0 => BOMB_MODE_ACTIVE;
    for (int b; b < bombPowerUps.size(); b++)
    {
        bombPowerUps[b].destroy();
    }
    bombPowerUps.size(0);
    spork ~ playOnce(startGameSFX, 0.9);
    <<< "Game reset." >>>;
}

// Spawn a neutral (gray) enemy at the outer ring
fun void spawnEnemy()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    Enemy e;
    e.init(ex, ey, 0.0, currentEnemySpeed());
    enemies << e;
}

// Spawn a colored, pitch-locked enemy at the outer ring
fun void spawnColorEnemy()
{
    (Std.rand2f(0.0, 1.0) * 2.0 * Math.PI) => float angle;
    5.5 => float radius;
    Math.sin(angle) * radius => float ex;
    Math.cos(angle) * radius => float ey;
    Std.rand2(0, 11) => int pc;
    EnemyColor e;
    e.init(ex, ey, 0.0, pc, currentEnemySpeed());
    colorEnemies << e;
}

// Break the ship into particle fragments on game over
fun void spawnShipShatter()
{
    40 => int numParticles;
    vec3 shipShatterColor;
    @(2.0, 0.1, 0.1) => shipShatterColor;
    for (int i; i < numParticles; i++)
    {
        Particle p;
        p.init(0.0, 0.0, 0.0, shipShatterColor);
        particles << p;
    }
    ship.sca(@(0.0, 0.0, 0.0));
    @(0.0, 0.0, 0.0) => shipIndicator.sca;
}

// Create a bullet matching the ship's facing and key's pitch class
fun void spawnBullet(int midiNote)
{
    rotationAngle * Math.PI / 180.0 => float angleRad;
    Math.sin(angleRad) => float dirX;
    Math.cos(angleRad) => float dirY;
    midiNote % 12 => int pc;
    PITCH_CLASS_COLORS[pc] => vec3 color;
    Bullet b;
    b.init(0.0, 0.0, 0.0, dirX, dirY);
    b.setColor(color);
    pc => b.pitchClass;
    if (BOMB_MODE_ACTIVE)
    {
        b.setBombStyle();
    }
    bullets << b;
    ship.color(color);
    shipIndicator.color(color);
}

// Difficulty ramp: enemy speed over time
fun float currentEnemySpeed()
{
    (now - gameStartTime) / second => float t;
    t / 120.0 => float f;
    if (f > 1.0) 1.0 => f;
    return 0.4 + f * (1.0 - 0.4);
}

// Difficulty ramp: enemy spawn interval over time
fun dur currentSpawnInterval()
{
    (now - gameStartTime) / second => float t;
    t / 120.0 => float f;
    if (f > 1.0) 1.0 => f;
    1.5 - f * (1.5 - 0.5) => float intervalSec;
    return intervalSec::second;
}

// Collision tests between bullets, enemies, and power-ups
fun int bulletHitsEnemy(Bullet @b, Enemy @e)
{
    if (!b.alive || !e.alive) return 0;
    (b.x - e.x) => float dx;
    (b.y - e.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.12 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

fun int bulletHitsColorEnemy(Bullet @b, EnemyColor @e)
{
    if (!b.alive || !e.alive) return 0;
    if (b.pitchClass != e.pitchClass)
        return 0;
    (b.x - e.x) => float dx;
    (b.y - e.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.12 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

fun int bulletHitsShield(Bullet @b, PowerUpShield @p)
{
    if (!b.alive || !p.alive) return 0;
    (b.x - p.x) => float dx;
    (b.y - p.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.10 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

fun int bulletHitsHeal(Bullet @b, PowerUpHeal @p)
{
    if (!b.alive || !p.alive) return 0;
    (b.x - p.x) => float dx;
    (b.y - p.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.10 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

fun int bulletHitsDouble(Bullet @b, PowerUpDouble @p)
{
    if (!b.alive || !p.alive) return 0;
    (b.x - p.x) => float dx;
    (b.y - p.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.10 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

fun int bulletHitsBomb(Bullet @b, PowerUpBomb @p)
{
    if (!b.alive || !p.alive) return 0;
    (b.x - p.x) => float dx;
    (b.y - p.y) => float dy;
    dx*dx + dy*dy => float d2;
    0.10 => float radius2;
    if (d2 < radius2) return 1;
    return 0;
}

// MIDI event loop: encoder for rotation, note-on for shooting / start / restart
fun void midiListener()
{
    while (true)
    {
        min => now;
        while (min.recv(msg))
        {
            if ((msg.data1 & 0xF0) == 0xB0 && msg.data2 == TARGET_CC)
            {
                msg.data3 => float ccVal;
                mapCCtoDegrees(ccVal) => rotationAngle;
            }
            else if ((msg.data1 & 0xF0) == 0x90 && msg.data3 > 0)
            {
                msg.data2 => int note;
                msg.data3 => int vel;
                if (TITLE_MODE)
                {
                    <<< "Starting game from title..." >>>;
                    startGameFromTitle();
                }
                else if (GAME_OVER)
                {
                    <<< "Restarting game..." >>>;
                    resetGame();
                }
                else
                {
                    <<< "NOTE ON:", note, "vel:", vel >>>;
                    spawnBullet(note);
                    if (BOMB_MODE_ACTIVE)
                        spork ~ playBombBulletTone(note);
                    else
                        spork ~ playBulletTone(note, vel);
                }
            }
        }
    }
}

spork ~ midiListener();

// Background spork: probabilistic enemy and power-up spawns
fun void enemySpawner()
{
    while (true)
    {
        if (!GAME_OVER && !TITLE_MODE)
        {
            Std.rand2(0, 100) => int r;
            if (r < 55)
            {
                spawnColorEnemy();
            }
            else if (r < 90)
            {
                spawnEnemy();
            }
            else if (r < 93)
            {
                spawnDoublePowerUp();
            }
            else if (r < 96)
            {
                spawnShieldPowerUp();
            }
            else if (r == 99)
            {
                spawnHealPowerUp();
            }
            else
            {
                spawnBombPowerUp();
            }
        }
        currentSpawnInterval() => dur waitTime;
        waitTime => now;
    }
}

spork ~ enemySpawner();

16::ms => dur frame;
frame / second => float dt;

// Main game loop: update world, handle timers, and advance graphics frames
while (true)
{
    if (!GAME_OVER && !TITLE_MODE)
    {
        rotationAngle * Math.PI / 180.0 => float angleRad;
        ship.rotZ(-angleRad);
        Math.sin(angleRad) => float dirX;
        Math.cos(angleRad) => float dirY;
        0.3 => float noseDist;
        shipIndicator.pos(dirX * noseDist, dirY * noseDist, 0.0);
        shipIndicator.rotZ(-angleRad);
        for (int i; i < bullets.size(); i++)
        {
            if (bullets[i].alive)
                bullets[i].update(dt);
        }
        for (int j; j < enemies.size(); j++)
        {
            if (enemies[j].alive)
                enemies[j].update(dt);
        }
        for (int k; k < colorEnemies.size(); k++)
        {
            if (colorEnemies[k].alive)
                colorEnemies[k].update(dt);
        }
        for (int s; s < shieldPowerUps.size(); s++)
        {
            if (shieldPowerUps[s].alive)
                shieldPowerUps[s].update(dt);
        }
        for (int h; h < healPowerUps.size(); h++)
        {
            if (healPowerUps[h].alive)
                healPowerUps[h].update(dt);
        }
        for (int d; d < doublePowerUps.size(); d++)
        {
            if (doublePowerUps[d].alive)
                doublePowerUps[d].update(dt);
        }
        for (int b; b < bombPowerUps.size(); b++)
        {
            if (bombPowerUps[b].alive)
                bombPowerUps[b].update(dt);
        }
        if (SHIELD_ACTIVE)
        {
            shieldRing.pos(0, 0, 0);
            if (now > shieldEndTime)
            {
                0 => SHIELD_ACTIVE;
                shieldRing.sca(@(0.0, 0.0, 0.0));
                <<< "Shield EXPIRED" >>>;
            }
        }
        else
        {
            shieldRing.sca(@(0.0, 0.0, 0.0));
        }
        if (DOUBLE_POINTS_ACTIVE && now > doubleEndTime)
        {
            0 => DOUBLE_POINTS_ACTIVE;
            SCORE_COLOR_NORMAL => scoreText.color;
            <<< "Double points EXPIRED" >>>;
        }
        if (BOMB_MODE_ACTIVE && now > bombEndTime)
        {
            0 => BOMB_MODE_ACTIVE;
            <<< "Bomb mode EXPIRED" >>>;
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < enemies.size(); j++)
            {
                if (!enemies[j].alive) continue;
                if (bulletHitsEnemy(bullets[i], enemies[j]))
                {
                    enemies[j].x => float ex;
                    enemies[j].y => float ey;
                    bullets[i].destroy();
                    if (BOMB_MODE_ACTIVE)
                    {
                        bombExplode(ex, ey);
                        spork ~ playBombExplosionSFX();
                    }
                    else
                    {
                        spawnExplosion(ex, ey, @(1.3, 1.3, 1.3));
                        enemies[j].destroy();
                        <<< "Defeated neutral enemy!" >>>;
                        SCORE + (100 * scoreMultiplier()) => SCORE;
                        refreshScoreText();
                    }
                    spork ~ playNeutralExplosion();
                    break;
                }
            }
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < colorEnemies.size(); j++)
            {
                if (!colorEnemies[j].alive) continue;
                if (bulletHitsColorEnemy(bullets[i], colorEnemies[j]))
                {
                    colorEnemies[j].x => float ex;
                    colorEnemies[j].y => float ey;
                    bullets[i].destroy();
                    if (BOMB_MODE_ACTIVE)
                    {
                        bombExplode(ex, ey);
                        spork ~ playBombExplosionSFX();
                    }
                    else
                    {
                        PITCH_CLASS_COLORS[colorEnemies[j].pitchClass] => vec3 c;
                        spawnExplosion(ex, ey, c);
                        colorEnemies[j].destroy();
                        <<< "Defeated colored enemy!" >>>;
                        SCORE + (150 * scoreMultiplier()) => SCORE;
                        refreshScoreText();
                    }
                    spork ~ playColorExplosion(colorEnemies[j].pitchClass);
                    break;
                }
            }
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < shieldPowerUps.size(); j++)
            {
                if (!shieldPowerUps[j].alive) continue;
                if (bulletHitsShield(bullets[i], shieldPowerUps[j]))
                {
                    bullets[i].destroy();
                    shieldPowerUps[j].destroy();
                    1 => SHIELD_ACTIVE;
                    now + SHIELD_DURATION => shieldEndTime;
                    shieldRing.sca(@(0.6, 0.6, 0.01));
                    shieldRing.pos(0, 0, 0);
                    spork ~ playShieldSFX();
                    <<< "Shield ACTIVATED!" >>>;
                    spork ~ playShieldPad(SHIELD_DURATION);
                    break;
                }
            }
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < healPowerUps.size(); j++)
            {
                if (!healPowerUps[j].alive) continue;
                if (bulletHitsHeal(bullets[i], healPowerUps[j]))
                {
                    bullets[i].destroy();
                    healPowerUps[j].destroy();
                    if (HP < MAX_HP)
                    {
                        HP++;
                        refreshHPText();
                        <<< "Healed! HP:", HP >>>;
                        spork ~ playHealSFX();
                    }
                    else
                    {
                        <<< "Heal collected at full HP (no effect)" >>>;
                    }
                    break;
                }
            }
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < doublePowerUps.size(); j++)
            {
                if (!doublePowerUps[j].alive) continue;
                if (bulletHitsDouble(bullets[i], doublePowerUps[j]))
                {
                    bullets[i].destroy();
                    doublePowerUps[j].destroy();
                    1 => DOUBLE_POINTS_ACTIVE;
                    now + DOUBLE_POINTS_DURATION => doubleEndTime;
                    SCORE_COLOR_DOUBLE => scoreText.color;
                    spork ~ playDoubleSFX();
                    <<< "Double points ACTIVATED!" >>>;
                    spork ~ playDoublePointsGliss();
                    break;
                }
            }
        }
        for (int i; i < bullets.size(); i++)
        {
            if (!bullets[i].alive) continue;
            for (int j; j < bombPowerUps.size(); j++)
            {
                if (!bombPowerUps[j].alive) continue;
                if (bulletHitsBomb(bullets[i], bombPowerUps[j]))
                {
                    bullets[i].destroy();
                    bombPowerUps[j].destroy();
                    1 => BOMB_MODE_ACTIVE;
                    now + BOMB_DURATION => bombEndTime;
                    spork ~ playBombSFX();
                    <<< "Bomb mode ACTIVATED!" >>>;
                    break;
                }
            }
        }
    }
    else if (!CLEAR_DONE)
    {
        for (int i; i < bullets.size(); i++)
            bullets[i].destroy();
        bullets.size(0);
        for (int j; j < enemies.size(); j++)
            enemies[j].destroy();
        enemies.size(0);
        for (int k; k < colorEnemies.size(); k++)
            colorEnemies[k].destroy();
        colorEnemies.size(0);
        for (int s; s < shieldPowerUps.size(); s++)
            shieldPowerUps[s].destroy();
        shieldPowerUps.size(0);
        for (int h; h < healPowerUps.size(); h++)
            healPowerUps[h].destroy();
        healPowerUps.size(0);
        for (int d; d < doublePowerUps.size(); d++)
            doublePowerUps[d].destroy();
        doublePowerUps.size(0);
        for (int b; b < bombPowerUps.size(); b++)
            bombPowerUps[b].destroy();
        bombPowerUps.size(0);
        1 => CLEAR_DONE;
        <<< "Cleared bullets, enemies, and power-ups after GAME OVER." >>>;
    }
    for (int p; p < particles.size(); p++)
    {
        if (particles[p].alive)
            particles[p].update(dt);
    }
    GG.nextFrame() => now;
    frame => now;
}
