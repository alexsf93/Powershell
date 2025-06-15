"""
============================================================
                     ARKANOID RETRO CRT
------------------------------------------------------------
Un remake sencillo de Arkanoid en Python usando Turtle,
con estética visual CRT (borde verde, bloques neón, power-ups
divertidos y niveles aleatorios y estructurados).
¡Rompe bloques, recoge power-ups y llega tan lejos como puedas!
------------------------------------------------------------
¿CÓMO JUGAR?
- Mueve la pala con ← y → (mantén pulsadas para ir más rápido)
- Rebota la bola para romper todos los bloques.
- Recoge los power-ups que caen (¡algunos ayudan y otros no!).
- Pasa de nivel al destruir todos los bloques.
- ¡La bola acelera poco a poco!
- Pulsa Q para salir en cualquier momento.

POWER-UPS:
- L: Pala larga          S: Bola lenta
- F: Bola rápida         N: Pala corta
- M: Multibola           X: Vida extra
- R: Controles invertidos
- B: Bola atraviesa bloques
- D: Pierdes una vida    ?: Efecto aleatorio

¡Ten cuidado con los power-ups malos!
============================================================
"""

import turtle
import random

# CRT/COLORES/BLOQUES
WIDTH, HEIGHT = 800, 600
BG_COLOR = "black"
CRT_GREEN = "#39FF14"
CRT_ORANGE = "#FF8C00"
CRT_YELLOW = "#FFE761"
CRT_CYAN = "#00FFF7"
CRT_MAGENTA = "#FF44EE"
BALL_COLOR = "#FFFF33"
PADDLE_COLOR = CRT_GREEN
BORDER_COLOR = CRT_GREEN
BLOCK_COLORS = [CRT_CYAN, CRT_MAGENTA, CRT_ORANGE, CRT_YELLOW, CRT_GREEN]
POWERUP_COLORS = {
    "L": "#4AFF47", "S": "#47E7FF", "F": "#FF2222",
    "N": "#6666FF", "M": "#FFF222", "X": "#FFFFFF",
    "R": "#FF88FF", "B": "#FF8800", "D": "#B00000", "?": "#00FFAA"
}
POWERUP_LABELS = {
    "L": "L", "S": "S", "F": "F", "N": "N", "M": "M", "X": "1UP",
    "R": "R", "B": "B", "D": "D", "?": "?"
}

BLOCK_ROWS = 6
BLOCK_COLS = 12
BLOCK_W = 56
BLOCK_H = 22
BLOCK_START_Y = HEIGHT//2 - 120

PADDLE_W, PADDLE_H = 100, 20
PADDLE_SPEED = 24
PADDLE_W_MAX = 180
PADDLE_W_MIN = 54

BALL_SIZE = 18
BALL_SPEED_INIT = 7
BALL_SPEED_MAX = 17
BALL_SPEED_MIN = 3

LIVES_INIT = 3
LIVES_MAX = 5

# ===============================
# INICIALIZACIÓN VENTANA CRT
# ===============================
wn = turtle.Screen()
wn.title("A R K A N O I D   RETRO CRT")
wn.bgcolor(BG_COLOR)
wn.setup(width=WIDTH, height=HEIGHT)
wn.tracer(0)

# --- BORDE CRT ---
border_pen = turtle.Turtle()
border_pen.hideturtle()
border_pen.pensize(6)
border_pen.color(BORDER_COLOR)
border_pen.penup()
border_pen.goto(-WIDTH//2 + 10, HEIGHT//2 - 10)
border_pen.pendown()
for _ in range(2):
    border_pen.forward(WIDTH-20)
    border_pen.right(90)
    border_pen.forward(HEIGHT-20)
    border_pen.right(90)
border_pen.penup()

scan_pen = turtle.Turtle()
scan_pen.hideturtle()
scan_pen.pensize(1)
scan_pen.color("#1a3c1a")
scan_pen.penup()
for y in range(-HEIGHT//2+20, HEIGHT//2-20, 6):
    scan_pen.goto(-WIDTH//2+15, y)
    scan_pen.pendown()
    scan_pen.forward(WIDTH-30)
    scan_pen.penup()

# --- MARCADOR Y MENSAJES ---
score = 0
lives = LIVES_INIT
level = 1

score_pen = turtle.Turtle()
score_pen.hideturtle()
score_pen.penup()
score_pen.color(CRT_GREEN)

msg_pen = turtle.Turtle()
msg_pen.hideturtle()
msg_pen.penup()
msg_pen.color(CRT_GREEN)

def update_score():
    score_pen.clear()
    score_pen.goto(-WIDTH//2 + 80, HEIGHT//2 - 60)
    score_pen.write(f"VIDAS: {lives}", align="left", font=("Courier", 22, "bold"))
    score_pen.goto(WIDTH//2 - 80, HEIGHT//2 - 60)
    score_pen.write(f"PUNTOS: {score}", align="right", font=("Courier", 22, "bold"))
    score_pen.goto(0, HEIGHT//2 - 60)
    score_pen.write(f"NIVEL: {level}", align="center", font=("Courier", 22, "bold"))

def show_message(msg, color=CRT_GREEN):
    msg_pen.clear()
    msg_pen.color(color)
    msg_pen.goto(0, 0)
    msg_pen.write(msg, align="center", font=("Courier", 34, "bold"))

def clear_message():
    msg_pen.clear()

# --- PALA ---
paddle = turtle.Turtle()
paddle.shape("square")
paddle.color(PADDLE_COLOR)
paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=PADDLE_W/20)
paddle.penup()
paddle.goto(0, -HEIGHT//2 + 50)
paddle.cur_width = PADDLE_W

paddle_dx = 0
controls_reversed = False

def move_left():
    global paddle_dx
    paddle_dx = -PADDLE_SPEED if not controls_reversed else PADDLE_SPEED

def move_right():
    global paddle_dx
    paddle_dx = PADDLE_SPEED if not controls_reversed else -PADDLE_SPEED

def stop_paddle():
    global paddle_dx
    paddle_dx = 0

def exit_game():
    wn.bye()

wn.listen()
wn.onkeypress(move_left, "Left")
wn.onkeyrelease(stop_paddle, "Left")
wn.onkeypress(move_right, "Right")
wn.onkeyrelease(stop_paddle, "Right")
wn.onkeypress(exit_game, "q")

# --- BOLA ---
ball = turtle.Turtle()
ball.shape("circle")
ball.color(BALL_COLOR)
ball.shapesize(stretch_wid=BALL_SIZE/20, stretch_len=BALL_SIZE/20)
ball.penup()
ball.goto(0, -HEIGHT//2 + 100)
ball.dx = BALL_SPEED_INIT * random.choice([-1, 1])
ball.dy = BALL_SPEED_INIT
ball.speed_value = BALL_SPEED_INIT
ball.breakthru = False

multi_ball = None

# --- BLOQUES ---
blocks = []

def pyramid_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        row = [0] * cols
        for c in range(r, cols - r):
            row[c] = 1
        pattern.append(row)
    return pattern

def inverse_pyramid_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        row = [1] * cols
        for c in range(r):
            row[c] = 0
            row[cols - 1 - c] = 0
        pattern.append(row)
    return pattern

def frame_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        row = []
        for c in range(cols):
            if r in [0, rows-1] or c in [0, cols-1]:
                row.append(1)
            else:
                row.append(0)
        pattern.append(row)
    return pattern

def checker_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        row = []
        for c in range(cols):
            if (r + c) % 2 == 0:
                row.append(1)
            else:
                row.append(0)
        pattern.append(row)
    return pattern

def saw_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        row = []
        for c in range(cols):
            if (c + r*2) % 3 == 0:
                row.append(1)
            else:
                row.append(0)
        pattern.append(row)
    return pattern

def full_pattern():
    rows, cols = BLOCK_ROWS, BLOCK_COLS
    pattern = []
    for r in range(rows):
        pattern.append([1]*cols)
    return pattern

PATTERN_LIST = [pyramid_pattern, inverse_pyramid_pattern, frame_pattern, checker_pattern, saw_pattern, full_pattern]

def setup_blocks(randomize=True):
    global blocks
    blocks = []
    # Elige un patrón
    if randomize:
        pattern = random.choice(PATTERN_LIST)()
    else:
        pattern = full_pattern()
    rows = len(pattern)
    cols = len(pattern[0])
    start_x = -cols//2 * BLOCK_W + BLOCK_W//2
    y = BLOCK_START_Y
    for r, row in enumerate(pattern):
        color = BLOCK_COLORS[r % len(BLOCK_COLORS)]
        for c, present in enumerate(row):
            if not present: continue
            block = turtle.Turtle()
            block.shape("square")
            block.color(color)
            block.shapesize(stretch_wid=BLOCK_H/20, stretch_len=BLOCK_W/20)
            block.penup()
            x = start_x + c*BLOCK_W
            block.goto(x, y)
            block.has_powerup = random.random() < 0.36
            block.powerup_type = random.choices(
                list(POWERUP_COLORS.keys()),
                weights=[9,9,5,5,5,3,2,2,2,3], k=1)[0] if block.has_powerup else None
            blocks.append(block)
        y -= BLOCK_H + 4

setup_blocks(randomize=False)

# --- POWERUPS ---
powerups = []
active_powerup = None
powerup_timer = None
active_effects = {}

def spawn_powerup(x, y, ptype):
    powerup = turtle.Turtle()
    powerup.shape("circle")
    powerup.shapesize(stretch_wid=1.1, stretch_len=1.1)
    powerup.color(POWERUP_COLORS[ptype])
    powerup.penup()
    powerup.goto(x, y)
    powerup.ptype = ptype
    powerup.label = POWERUP_LABELS[ptype]
    powerup.active = True
    # Etiqueta
    txt = turtle.Turtle()
    txt.hideturtle()
    txt.penup()
    txt.goto(x, y-5)
    txt.color("black")
    txt.write(powerup.label, align="center", font=("Arial", 13, "bold"))
    powerup.label_turtle = txt
    powerups.append(powerup)

def activate_powerup(ptype):
    global active_powerup, powerup_timer, lives, controls_reversed, multi_ball
    # Si es instantáneo
    if ptype == "X":
        if lives < LIVES_MAX:
            lives += 1
            show_message("¡1UP!", "#FFFFFF")
            update_score()
        else:
            show_message("¡Al máximo!", "#BBBBBB")
        wn.update()
        wn.ontimer(clear_message, 1100)
        return
    if ptype == "D":
        show_message("¡Power Down!", "#B00000")
        wn.update()
        wn.ontimer(lambda: [clear_message(), lose_life()], 800)
        return

    # Efecto temporal
    if ptype in active_effects:
        return  # No se acumula
    active_effects[ptype] = True

    def end_effect():
        if ptype == "L":
            paddle.cur_width = PADDLE_W
            paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=PADDLE_W/20)
        elif ptype == "N":
            paddle.cur_width = PADDLE_W
            paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=PADDLE_W/20)
        elif ptype == "S":
            ball.speed_value = BALL_SPEED_INIT
        elif ptype == "F":
            ball.speed_value = BALL_SPEED_INIT
        elif ptype == "R":
            global controls_reversed
            controls_reversed = False
        elif ptype == "B":
            ball.breakthru = False
            if multi_ball:
                multi_ball.breakthru = False
        elif ptype == "M":
            remove_multi_ball()
        active_effects.pop(ptype, None)
        clear_message()
        wn.update()

    if ptype == "L":
        paddle.cur_width = min(PADDLE_W_MAX, paddle.cur_width+60)
        paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=paddle.cur_width/20)
        show_message("¡PALA XL!", CRT_CYAN)
    elif ptype == "N":
        paddle.cur_width = max(PADDLE_W_MIN, paddle.cur_width-40)
        paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=paddle.cur_width/20)
        show_message("¡PALA MINI!", CRT_MAGENTA)
    elif ptype == "S":
        ball.speed_value = max(BALL_SPEED_MIN, ball.speed_value-3)
        show_message("¡BOLA LENTA!", CRT_YELLOW)
    elif ptype == "F":
        ball.speed_value = min(BALL_SPEED_MAX, ball.speed_value+4)
        show_message("¡BOLA RÁPIDA!", "#FF2222")
    elif ptype == "R":
        controls_reversed = True
        show_message("¡CONTROLES INVERTIDOS!", "#FF88FF")
    elif ptype == "B":
        ball.breakthru = True
        if multi_ball:
            multi_ball.breakthru = True
        show_message("¡BOLA ATRAVIESA!", "#FF8800")
    elif ptype == "M":
        spawn_multi_ball()
        show_message("¡MULTIBOLA!", CRT_YELLOW)
    elif ptype == "?":
        wn.ontimer(lambda: activate_powerup(random.choice(
            ["L","S","F","N","M","X","R","B"])), 300)
        return

    wn.update()
    powerup_timer = wn.ontimer(end_effect, 7000)  # 7 segundos

def spawn_multi_ball():
    global multi_ball
    if multi_ball: return
    multi_ball = turtle.Turtle()
    multi_ball.shape("circle")
    multi_ball.color("#FFD000")
    multi_ball.shapesize(stretch_wid=BALL_SIZE/20, stretch_len=BALL_SIZE/20)
    multi_ball.penup()
    multi_ball.goto(ball.xcor(), ball.ycor())
    multi_ball.dx = -ball.dx
    multi_ball.dy = ball.dy
    multi_ball.speed_value = ball.speed_value
    multi_ball.breakthru = ball.breakthru

def remove_multi_ball():
    global multi_ball
    if multi_ball:
        multi_ball.hideturtle()
        multi_ball = None

# --- LÓGICA DEL JUEGO ---
ball_speed_counter = 0

def reset_ball_paddle(resume_game=True):
    global multi_ball, controls_reversed
    controls_reversed = False
    paddle.cur_width = PADDLE_W
    paddle.shapesize(stretch_wid=PADDLE_H/20, stretch_len=PADDLE_W/20)
    ball.breakthru = False
    remove_multi_ball()
    paddle.goto(0, -HEIGHT//2 + 50)
    ball.goto(0, -HEIGHT//2 + 100)
    ball.dx = ball.speed_value * random.choice([-1, 1])
    ball.dy = abs(ball.speed_value)
    wn.update()
    if resume_game:
        wn.ontimer(game_loop, 20)

def lose_life():
    global lives
    lives -= 1
    update_score()
    if lives > 0:
        show_message("¡Perdiste una vida!", CRT_ORANGE)
        wn.update()
        wn.ontimer(lambda: [clear_message(), reset_ball_paddle(True)], 1500)
    else:
        show_message("¡GAME OVER!", CRT_MAGENTA)
        wn.update()
        wn.ontimer(lambda: wn.bye(), 3000)

def check_win():
    if not blocks:
        show_message("¡NIVEL SUPERADO!", CRT_CYAN)
        wn.update()
        wn.ontimer(next_level, 2000)
        return True
    return False

def next_level():
    global level
    level += 1
    setup_blocks(randomize=True)
    reset_ball_paddle(resume_game=True)
    update_score()
    clear_message()
    wn.update()

def move_ball_instance(b):
    b.setx(b.xcor() + b.dx)
    b.sety(b.ycor() + b.dy)
    # Rebote lateral
    if b.xcor() > WIDTH//2 - BALL_SIZE//2 - 14:
        b.setx(WIDTH//2 - BALL_SIZE//2 - 14)
        b.dx *= -1
    if b.xcor() < -WIDTH//2 + BALL_SIZE//2 + 14:
        b.setx(-WIDTH//2 + BALL_SIZE//2 + 14)
        b.dx *= -1
    # Rebote arriba
    if b.ycor() > HEIGHT//2 - BALL_SIZE//2 - 20:
        b.sety(HEIGHT//2 - BALL_SIZE//2 - 20)
        b.dy *= -1

def ball_paddle_collision(b):
    if (b.ycor() < paddle.ycor() + PADDLE_H//2 + BALL_SIZE//2 and
        b.ycor() > paddle.ycor() and
        abs(b.xcor() - paddle.xcor()) < paddle.cur_width//2 + BALL_SIZE//2):
        b.sety(paddle.ycor() + PADDLE_H//2 + BALL_SIZE//2)
        b.dy = abs(b.dy)
        offset = (b.xcor() - paddle.xcor()) / (paddle.cur_width//2)
        b.dx = b.speed_value * offset if abs(offset) > 0.12 else b.dx

def ball_block_collision(b):
    global score
    for block in blocks[:]:
        if block.distance(b) < (BLOCK_W//2 + BALL_SIZE//2 - 6):
            if not (hasattr(b, "breakthru") and b.breakthru):
                b.dy *= -1
            block.goto(2000, 2000)
            if hasattr(block, "has_powerup") and block.has_powerup and block.powerup_type:
                spawn_powerup(block.xcor(), block.ycor(), block.powerup_type)
            blocks.remove(block)
            score += 10
            update_score()
            if check_win():
                return True
            break
    return False

def game_loop():
    global score, ball_speed_counter, multi_ball

    # --- Movimiento de la pala ---
    new_x = paddle.xcor() + paddle_dx
    max_x = WIDTH//2 - paddle.cur_width//2 - 18
    if new_x < -max_x:
        new_x = -max_x
    if new_x > max_x:
        new_x = max_x
    paddle.setx(new_x)

    # --- Bola principal ---
    move_ball_instance(ball)
    ball_paddle_collision(ball)
    if ball_block_collision(ball): return

    # --- Multibola ---
    if multi_ball:
        move_ball_instance(multi_ball)
        ball_paddle_collision(multi_ball)
        # Si sale de pantalla inferior
        if multi_ball.ycor() < -HEIGHT//2 + 18:
            remove_multi_ball()
        else:
            if ball_block_collision(multi_ball): return

    # --- Velocidad progresiva ---
    ball_speed_counter += 1
    if ball_speed_counter % (60 * 10) == 0 and abs(ball.dx) < BALL_SPEED_MAX:
        signx = 1 if ball.dx >= 0 else -1
        signy = 1 if ball.dy >= 0 else -1
        ball.dx += signx*0.8
        ball.dy += signy*0.7
        ball.speed_value = min(BALL_SPEED_MAX, ball.speed_value + 1)
        show_message("¡La bola acelera!", CRT_YELLOW)
        wn.update()
        wn.ontimer(clear_message, 1100)

    # --- Bola cae (fin) ---
    if ball.ycor() < -HEIGHT//2 + 18:
        reset_ball_paddle(resume_game=False)
        lose_life()
        return

    # --- Powerups en movimiento y recogida ---
    for powerup in powerups[:]:
        if not powerup.active: continue
        powerup.sety(powerup.ycor() - 7)
        powerup.label_turtle.goto(powerup.xcor(), powerup.ycor()-5)
        # Recogido
        if (abs(powerup.xcor()-paddle.xcor()) < paddle.cur_width//2+15 and
            abs(powerup.ycor()-paddle.ycor()) < PADDLE_H//2+15):
            activate_powerup(powerup.ptype)
            powerup.active = False
            powerup.hideturtle()
            powerup.label_turtle.clear()
            powerups.remove(powerup)
        # Fuera de pantalla
        elif powerup.ycor() < -HEIGHT//2:
            powerup.active = False
            powerup.hideturtle()
            powerup.label_turtle.clear()
            powerups.remove(powerup)

    wn.update()
    wn.ontimer(game_loop, 15)

# --- MENSAJE DE BIENVENIDA CRT ---
welcome_pen = turtle.Turtle()
welcome_pen.hideturtle()
welcome_pen.penup()
welcome_pen.color(CRT_CYAN)
welcome_pen.goto(0, HEIGHT//2 - 140)
welcome_pen.write(
    "A R K A N O I D   CRT\n\n← y → para mover\nQ para salir\nRecoge los power-ups!\n\nPulsa ESPACIO para empezar",
    align="center", font=("Courier", 24, "bold"))

def start_game_from_welcome():
    welcome_pen.clear()
    clear_message()
    update_score()
    game_loop()

def launch_on_key(*_):
    wn.onkeypress(None, "space")
    start_game_from_welcome()

wn.onkeypress(launch_on_key, "space")
wn.listen()
wn.update()
wn.mainloop()