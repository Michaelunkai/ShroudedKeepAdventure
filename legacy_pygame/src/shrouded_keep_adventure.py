import argparse
import math
import os
import random
import sys

os.environ.setdefault("PYGAME_HIDE_SUPPORT_PROMPT", "1")

import pygame


WIDTH, HEIGHT = 1120, 680
PLAYER_SPEED = 270
MOON = (236, 78, 255)
BLUE = (24, 83, 219)
INK = (3, 5, 17)
STONE = (12, 16, 31)
TEXT = (232, 236, 255)


class Game:
    def __init__(self, smoke=False):
        pygame.init()
        flags = pygame.HIDDEN if smoke else 0
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT), flags)
        pygame.display.set_caption("Shrouded Keep Adventure")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont("segoeui", 24)
        self.big = pygame.font.SysFont("segoeui", 54, bold=True)
        self.small = pygame.font.SysFont("segoeui", 18)
        self.player = pygame.Rect(72, 548, 34, 42)
        self.scene = 0
        self.state = "title"
        self.seals = 0
        self.health = 5
        self.message = "The Shrouded Keep waits beyond the blue ravine."
        self.message_timer = 0
        self.time = 0.0
        self.stars = [(random.randrange(WIDTH), random.randrange(330), random.randrange(1, 4)) for _ in range(170)]
        self.scenes = [
            {
                "name": "Ravine of Blue Fog",
                "goal": "Cross the broken bridge and take the first seal.",
                "seal": pygame.Rect(482, 476, 28, 28),
                "gate": pygame.Rect(1054, 430, 44, 130),
                "walls": [pygame.Rect(0, 0, 52, HEIGHT), pygame.Rect(0, 590, WIDTH, 90), pygame.Rect(210, 458, 250, 36), pygame.Rect(625, 420, 270, 42)],
                "foes": [pygame.Rect(690, 535, 34, 38)],
            },
            {
                "name": "Outer Walls",
                "goal": "Find the second seal in the ruined battlement.",
                "seal": pygame.Rect(838, 314, 28, 28),
                "gate": pygame.Rect(1054, 214, 44, 160),
                "walls": [pygame.Rect(0, 0, 70, HEIGHT), pygame.Rect(0, 612, WIDTH, 68), pygame.Rect(150, 185, 128, 360), pygame.Rect(406, 110, 86, 430), pygame.Rect(622, 252, 350, 54)],
                "foes": [pygame.Rect(525, 530, 34, 38), pygame.Rect(782, 395, 34, 38)],
            },
            {
                "name": "Starfall Courtyard",
                "goal": "Wake the third seal under the violet sky.",
                "seal": pygame.Rect(514, 210, 28, 28),
                "gate": pygame.Rect(1054, 112, 44, 190),
                "walls": [pygame.Rect(0, 0, 58, HEIGHT), pygame.Rect(0, 610, WIDTH, 70), pygame.Rect(200, 138, 520, 42), pygame.Rect(230, 362, 390, 50), pygame.Rect(792, 232, 92, 330)],
                "foes": [pygame.Rect(332, 530, 34, 38), pygame.Rect(670, 478, 34, 38), pygame.Rect(914, 368, 34, 38)],
            },
            {
                "name": "Moon Tower Door",
                "goal": "Use the three seals to open the keep.",
                "seal": None,
                "gate": pygame.Rect(1012, 250, 72, 218),
                "walls": [pygame.Rect(0, 0, 64, HEIGHT), pygame.Rect(0, 612, WIDTH, 68), pygame.Rect(160, 442, 680, 50), pygame.Rect(290, 192, 72, 250), pygame.Rect(708, 170, 72, 272)],
                "foes": [pygame.Rect(514, 540, 42, 48)],
            },
            {
                "name": "The Shrouded Keep",
                "goal": "Reach the moon gate and end the curse.",
                "seal": None,
                "gate": pygame.Rect(902, 96, 88, 132),
                "walls": [pygame.Rect(0, 0, 64, HEIGHT), pygame.Rect(0, 612, WIDTH, 68), pygame.Rect(182, 110, 46, 470), pygame.Rect(402, 240, 340, 52), pygame.Rect(826, 0, 56, 472)],
                "foes": [pygame.Rect(574, 515, 58, 62)],
            },
        ]

    def reset(self):
        self.player.topleft = (72, 548)
        self.scene = 0
        self.state = "title"
        self.seals = 0
        self.health = 5
        self.message = "The Shrouded Keep waits beyond the blue ravine."

    def draw_gradient(self):
        for y in range(HEIGHT):
            t = y / HEIGHT
            r = int(6 + 56 * (1 - abs(t - 0.32)))
            g = int(5 + 12 * (1 - t))
            b = int(20 + 82 * (1 - abs(t - 0.38)))
            pygame.draw.line(self.screen, (r, g, b), (0, y), (WIDTH, y))
        for x, y, s in self.stars:
            glow = 70 + int(90 * math.sin(self.time * 1.7 + x))
            pygame.draw.circle(self.screen, (180, 205, 255, max(80, glow)), (x, y), s)
        pygame.draw.circle(self.screen, (251, 93, 236), (313, 152), 34)
        pygame.draw.circle(self.screen, (95, 40, 128), (302, 144), 11)

    def draw_keep(self):
        pygame.draw.polygon(self.screen, (5, 7, 18), [(640, 355), (690, 130), (745, 355)])
        pygame.draw.rect(self.screen, (5, 7, 18), (670, 180, 86, 230))
        pygame.draw.rect(self.screen, (5, 7, 18), (802, 150, 82, 280))
        pygame.draw.rect(self.screen, (5, 7, 18), (168, 366, 880, 150))
        for tx in (180, 265, 350, 805, 920):
            pygame.draw.rect(self.screen, (6, 8, 20), (tx, 316, 54, 124))
            pygame.draw.polygon(self.screen, (6, 8, 20), [(tx, 316), (tx + 27, 278), (tx + 54, 316)])
        for i in range(18):
            pygame.draw.line(self.screen, (24, 48, 91), (170 + i * 52, 392), (204 + i * 52, 404), 2)
        pygame.draw.arc(self.screen, (24, 48, 91), (225, 444, 116, 118), math.pi, math.tau, 5)

    def draw_world(self):
        scene = self.scenes[self.scene]
        self.draw_gradient()
        self.draw_keep()
        fog_y = 550 + int(math.sin(self.time * 1.4) * 8)
        for i in range(8):
            pygame.draw.ellipse(self.screen, (9, 68, 172), (i * 150 - 70, fog_y + i % 2 * 18, 240, 52), 2)
        for wall in scene["walls"]:
            pygame.draw.rect(self.screen, STONE, wall, border_radius=4)
            pygame.draw.rect(self.screen, (25, 54, 108), wall, 2, border_radius=4)
        gate_color = (77, 39, 107) if self.scene < 3 or self.seals >= 3 else (34, 20, 46)
        pygame.draw.rect(self.screen, gate_color, scene["gate"], border_radius=6)
        pygame.draw.rect(self.screen, MOON, scene["gate"], 2, border_radius=6)
        if scene["seal"]:
            pulse = 9 + int(4 * math.sin(self.time * 5))
            pygame.draw.circle(self.screen, MOON, scene["seal"].center, pulse)
            pygame.draw.circle(self.screen, (255, 235, 255), scene["seal"].center, 5)
        for foe in scene["foes"]:
            pygame.draw.rect(self.screen, (30, 5, 55), foe, border_radius=9)
            pygame.draw.rect(self.screen, (126, 33, 190), foe, 2, border_radius=9)
        pygame.draw.rect(self.screen, (43, 118, 255), self.player, border_radius=7)
        pygame.draw.rect(self.screen, (210, 230, 255), self.player.inflate(-16, -18))
        self.draw_ui(scene)

    def draw_ui(self, scene):
        pygame.draw.rect(self.screen, (2, 4, 14), (0, 0, WIDTH, 82))
        self.blit(scene["name"], 24, 16, self.font, TEXT)
        self.blit(scene["goal"], 24, 48, self.small, (181, 200, 238))
        self.blit(f"Seals {self.seals}/3   Health {self.health}/5", 842, 22, self.font, TEXT)
        if self.message_timer > 0 or self.state != "play":
            pygame.draw.rect(self.screen, (4, 7, 20), (90, 590, 940, 58), border_radius=8)
            pygame.draw.rect(self.screen, (65, 92, 180), (90, 590, 940, 58), 2, border_radius=8)
            self.blit(self.message, 116, 608, self.font, TEXT)

    def blit(self, text, x, y, font, color):
        self.screen.blit(font.render(text, True, color), (x, y))

    def title(self):
        self.draw_gradient()
        self.draw_keep()
        self.blit("SHROUDED KEEP", 320, 220, self.big, TEXT)
        self.blit("A moonlit single-player adventure", 376, 286, self.font, (190, 203, 255))
        self.blit("Press Space or Enter to begin", 402, 344, self.font, (242, 197, 255))

    def ending(self):
        self.draw_gradient()
        self.draw_keep()
        self.blit("THE KEEP IS UNBOUND", 252, 230, self.big, TEXT)
        self.blit("The violet moon fades. The ravine remembers your name.", 285, 304, self.font, (220, 229, 255))
        self.blit("Press R to begin again or Esc to quit", 372, 362, self.font, (242, 197, 255))

    def move_player(self, dt, keys):
        dx = (keys[pygame.K_RIGHT] or keys[pygame.K_d]) - (keys[pygame.K_LEFT] or keys[pygame.K_a])
        dy = (keys[pygame.K_DOWN] or keys[pygame.K_s]) - (keys[pygame.K_UP] or keys[pygame.K_w])
        if dx and dy:
            dx *= 0.707
            dy *= 0.707
        old = self.player.copy()
        self.player.x += int(dx * PLAYER_SPEED * dt)
        self.collide(old, axis="x")
        old = self.player.copy()
        self.player.y += int(dy * PLAYER_SPEED * dt)
        self.collide(old, axis="y")
        self.player.clamp_ip(pygame.Rect(0, 82, WIDTH, HEIGHT - 82))

    def collide(self, old, axis):
        for wall in self.scenes[self.scene]["walls"]:
            if self.player.colliderect(wall):
                if axis == "x":
                    self.player.x = old.x
                else:
                    self.player.y = old.y

    def interact(self):
        scene = self.scenes[self.scene]
        if scene["seal"] and self.player.inflate(34, 34).colliderect(scene["seal"]):
            self.seals += 1
            scene["seal"] = None
            self.say("A moon seal burns cold in your hand.")
            return
        for foe in list(scene["foes"]):
            if self.player.inflate(48, 48).colliderect(foe):
                scene["foes"].remove(foe)
                self.say("Your blade scatters the shadow.")
                return
        if self.player.colliderect(scene["gate"]):
            if self.scene == 3 and self.seals < 3:
                self.say("The tower door needs three moon seals.")
            elif self.scene == 4:
                self.state = "end"
            else:
                self.scene += 1
                self.player.topleft = (74, 538)
                self.say(f"You enter {self.scenes[self.scene]['name']}.")
            return
        self.say("Only wind answers.")

    def say(self, text):
        self.message = text
        self.message_timer = 3.0

    def update_foes(self, dt):
        for foe in self.scenes[self.scene]["foes"]:
            distance = math.hypot(self.player.centerx - foe.centerx, self.player.centery - foe.centery)
            if distance < 210 and distance > 1:
                foe.x += int((self.player.centerx - foe.centerx) / distance * 72 * dt)
                foe.y += int((self.player.centery - foe.centery) / distance * 72 * dt)
            if self.player.colliderect(foe):
                self.health -= 1
                self.player.x = max(70, self.player.x - 72)
                self.say("The shadow bites. Strike it with Space.")
                if self.health <= 0:
                    self.reset()
                    self.say("The keep returns you to the ravine.")

    def run(self, smoke=False):
        frames = 0
        running = True
        while running:
            dt = self.clock.tick(60) / 1000.0
            self.time += dt
            frames += 1
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                    if self.state == "title" and event.key in (pygame.K_SPACE, pygame.K_RETURN):
                        self.state = "play"
                    elif self.state == "play" and event.key in (pygame.K_SPACE, pygame.K_RETURN):
                        self.interact()
                    elif self.state == "end" and event.key == pygame.K_r:
                        self.reset()
            if smoke and frames == 2:
                self.state = "play"
            if self.state == "play":
                self.move_player(dt, pygame.key.get_pressed())
                self.update_foes(dt)
                self.message_timer = max(0, self.message_timer - dt)
                self.draw_world()
            elif self.state == "end":
                self.ending()
            else:
                self.title()
            pygame.display.flip()
            if smoke and frames > 90:
                print("SMOKE_OK")
                running = False
        pygame.quit()


def main():
    parser = argparse.ArgumentParser(description="Run Shrouded Keep Adventure.")
    parser.add_argument("--smoke-test", action="store_true", help="Launch hidden, render briefly, and exit.")
    args = parser.parse_args()
    Game(smoke=args.smoke_test).run(smoke=args.smoke_test)


if __name__ == "__main__":
    main()
