#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <math.h>
#include <time.h>
#include <signal.h>
#include <sys/epoll.h>
#include <linux/input.h>

#define MAX_SLOTS 10

// Screen dimensions for ELAN touchscreen (3504 x 1968)
#define SCREEN_MAX_X 3504.0
#define SCREEN_MAX_Y 1968.0

#define EDGE_LEFT 160.0
#define EDGE_RIGHT (SCREEN_MAX_X - 160.0)

#define SWIPE_THRESHOLD 140.0
#define PINCH_THRESHOLD 120.0
#define SLIDER_STEP 70.0
#define SLIDER_INTERVAL_MS 65
#define TAP_MAX_MS 300
#define TAP_MAX_DRAG 50.0
#define COOLDOWN_MS 300

typedef struct {
    int tracking_id;
    double x;
    double y;
    double start_x;
    double start_y;
    double max_drag;
    int active;
} Slot;

static Slot slots[MAX_SLOTS];
static int current_slot = 0;
static int active_count = 0;
static int prev_count = 0;
static int max_fingers_seen = 0;
static int gesture_fired = 0;

static double four_finger_start_r = 0.0;
static struct timespec touch_start_time = {0, 0};
static struct timespec last_fire_time = {0, 0};
static struct timespec last_slider_time = {0, 0};

// Slider state for 1-finger edge moves
static int is_left_slider = 0;
static int is_right_slider = 0;
static double slider_last_y = 0.0;
static char brightness_dev[64] = "backlight:intel_backlight";

static long time_diff_ms(struct timespec *start, struct timespec *end) {
    return (end->tv_sec - start->tv_sec) * 1000 + (end->tv_nsec - start->tv_nsec) / 1000000;
}

static char *detect_touchscreen_path(void) {
    FILE *fp = popen("for d in /dev/input/event*; do "
                     "  udevadm info -q property -n \"$d\" 2>/dev/null | grep -q 'ID_INPUT_TOUCHSCREEN=1' && echo \"$d\" && break; "
                     "done", "r");
    if (!fp) return NULL;
    static char path[128];
    if (fgets(path, sizeof(path), fp) != NULL) {
        size_t len = strlen(path);
        if (len > 0 && path[len - 1] == '\n') path[len - 1] = '\0';
        pclose(fp);
        return path;
    }
    pclose(fp);
    return NULL;
}

static void detect_brightness_device(void) {
    FILE *fp = popen("dms brightness list 2>/dev/null | grep backlight | awk '{print $1}' | head -n1", "r");
    if (fp) {
        char buf[64];
        if (fgets(buf, sizeof(buf), fp) != NULL) {
            size_t len = strlen(buf);
            if (len > 0 && buf[len - 1] == '\n') buf[len - 1] = '\0';
            if (strlen(buf) > 0) {
                snprintf(brightness_dev, sizeof(brightness_dev), "%s", buf);
            }
        }
        pclose(fp);
    }
    printf("[niri-touchd] Using brightness device: %s\n", brightness_dev);
}

static void trigger_action(const char *cmd) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    if (last_fire_time.tv_sec != 0 && time_diff_ms(&last_fire_time, &now) < COOLDOWN_MS) {
        return;
    }
    last_fire_time = now;
    gesture_fired = 1;
    printf("[niri-touchd] Action triggered: %s\n", cmd);
    fflush(stdout);

    pid_t pid = fork();
    if (pid == 0) {
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        _exit(1);
    }
}

static void trigger_slider_step(const char *cmd) {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    if (last_slider_time.tv_sec != 0 && time_diff_ms(&last_slider_time, &now) < SLIDER_INTERVAL_MS) {
        return;
    }
    last_slider_time = now;
    printf("[niri-touchd] Slider step: %s\n", cmd);
    fflush(stdout);

    pid_t pid = fork();
    if (pid == 0) {
        execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
        _exit(1);
    }
}

int main(int argc, char **argv) {
    signal(SIGCHLD, SIG_IGN);

    char *dev_path = NULL;
    if (argc > 1) {
        dev_path = argv[1];
    } else {
        dev_path = detect_touchscreen_path();
    }

    if (!dev_path || strlen(dev_path) == 0) {
        fprintf(stderr, "[niri-touchd] Error: Touchscreen device not found via udev.\n");
        return 1;
    }

    detect_brightness_device();

    printf("[niri-touchd] Connecting to touchscreen: %s\n", dev_path);
    int fd = open(dev_path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        fprintf(stderr, "[niri-touchd] Failed to open %s: %s\n", dev_path, strerror(errno));
        return 1;
    }

    char name[128] = "Unknown";
    ioctl(fd, EVIOCGNAME(sizeof(name)), name);
    printf("[niri-touchd] Device Name: %s\n", name);
    printf("[niri-touchd] Engine ready: 3-finger view, 4-finger window move, 4-finger pinch overview, 4-finger tap close, DMS brightness & volume sliders.\n");
    fflush(stdout);

    for (int i = 0; i < MAX_SLOTS; i++) {
        slots[i].tracking_id = -1;
        slots[i].active = 0;
        slots[i].max_drag = 0;
    }

    int epfd = epoll_create1(0);
    struct epoll_event ev;
    ev.events = EPOLLIN;
    ev.data.fd = fd;
    epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);

    struct input_event evs[64];

    while (1) {
        int nfds = epoll_wait(epfd, &ev, 1, -1);
        if (nfds < 0) {
            if (errno == EINTR) continue;
            break;
        }

        ssize_t n = read(fd, evs, sizeof(evs));
        if (n <= 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) continue;
            fprintf(stderr, "[niri-touchd] Device read error, attempting reconnect...\n");
            close(fd);
            sleep(2);
            fd = open(dev_path, O_RDONLY | O_NONBLOCK);
            if (fd >= 0) {
                ev.data.fd = fd;
                epoll_ctl(epfd, EPOLL_CTL_MOD, fd, &ev);
            }
            continue;
        }

        int count = n / sizeof(struct input_event);
        for (int i = 0; i < count; i++) {
            struct input_event *e = &evs[i];

            if (e->type == EV_ABS) {
                if (e->code == ABS_MT_SLOT) {
                    if (e->value >= 0 && e->value < MAX_SLOTS) {
                        current_slot = e->value;
                    }
                } else if (e->code == ABS_MT_TRACKING_ID) {
                    if (e->value >= 0) {
                        slots[current_slot].tracking_id = e->value;
                        slots[current_slot].active = 1;
                        slots[current_slot].start_x = slots[current_slot].x;
                        slots[current_slot].start_y = slots[current_slot].y;
                        slots[current_slot].max_drag = 0.0;
                    } else {
                        slots[current_slot].tracking_id = -1;
                        slots[current_slot].active = 0;
                    }
                } else if (e->code == ABS_MT_POSITION_X) {
                    slots[current_slot].x = e->value;
                    double drag = hypot(slots[current_slot].x - slots[current_slot].start_x,
                                        slots[current_slot].y - slots[current_slot].start_y);
                    if (drag > slots[current_slot].max_drag) {
                        slots[current_slot].max_drag = drag;
                    }
                } else if (e->code == ABS_MT_POSITION_Y) {
                    slots[current_slot].y = e->value;
                    double drag = hypot(slots[current_slot].x - slots[current_slot].start_x,
                                        slots[current_slot].y - slots[current_slot].start_y);
                    if (drag > slots[current_slot].max_drag) {
                        slots[current_slot].max_drag = drag;
                    }
                }
            } else if (e->type == EV_SYN && e->code == SYN_REPORT) {
                active_count = 0;
                for (int s = 0; s < MAX_SLOTS; s++) {
                    if (slots[s].active) active_count++;
                }

                struct timespec now;
                clock_gettime(CLOCK_MONOTONIC, &now);

                if (prev_count == 0 && active_count > 0) {
                    touch_start_time = now;
                    max_fingers_seen = active_count;
                    gesture_fired = 0;
                    four_finger_start_r = 0.0;
                    is_left_slider = 0;
                    is_right_slider = 0;

                    if (active_count == 1) {
                        int s0 = -1;
                        for (int s = 0; s < MAX_SLOTS; s++) {
                            if (slots[s].active) { s0 = s; break; }
                        }
                        if (s0 >= 0) {
                            if (slots[s0].x < EDGE_LEFT) {
                                is_left_slider = 1;
                                slider_last_y = slots[s0].y;
                            } else if (slots[s0].x > EDGE_RIGHT) {
                                is_right_slider = 1;
                                slider_last_y = slots[s0].y;
                            }
                        }
                    }
                }

                if (active_count > max_fingers_seen) {
                    max_fingers_seen = active_count;
                }

                if (active_count != prev_count) {
                    if (active_count == 3 && prev_count < 3) {
                        for (int s = 0; s < MAX_SLOTS; s++) {
                            if (slots[s].active) {
                                slots[s].start_x = slots[s].x;
                                slots[s].start_y = slots[s].y;
                                slots[s].max_drag = 0;
                            }
                        }
                    } else if (active_count == 4 && prev_count < 4) {
                        double cx = 0, cy = 0;
                        for (int s = 0; s < MAX_SLOTS; s++) {
                            if (slots[s].active) {
                                cx += slots[s].x;
                                cy += slots[s].y;
                                slots[s].start_x = slots[s].x;
                                slots[s].start_y = slots[s].y;
                                slots[s].max_drag = 0;
                            }
                        }
                        cx /= 4.0; cy /= 4.0;
                        four_finger_start_r = 0.0;
                        for (int s = 0; s < MAX_SLOTS; s++) {
                            if (slots[s].active) {
                                four_finger_start_r += hypot(slots[s].x - cx, slots[s].y - cy);
                            }
                        }
                        four_finger_start_r /= 4.0;
                    }

                    if (active_count == 0) {
                        long duration = time_diff_ms(&touch_start_time, &now);

                        double max_drag_overall = 0.0;
                        for (int s = 0; s < MAX_SLOTS; s++) {
                            if (slots[s].max_drag > max_drag_overall) {
                                max_drag_overall = slots[s].max_drag;
                            }
                        }

                        // Tap with 4 fingers -> Close focused window
                        if (!gesture_fired && duration < TAP_MAX_MS && max_drag_overall < TAP_MAX_DRAG) {
                            if (max_fingers_seen == 4) {
                                trigger_action("niri msg action close-window");
                            }
                        }

                        gesture_fired = 0;
                        four_finger_start_r = 0.0;
                        is_left_slider = 0;
                        is_right_slider = 0;
                        max_fingers_seen = 0;
                    }

                    prev_count = active_count;
                }

                // -------------------------------------------------------------
                // 1 FINGER: LATERAL SLIDERS (DMS Volume & Brightness)
                // -------------------------------------------------------------
                if (active_count == 1) {
                    int s0 = -1;
                    for (int s = 0; s < MAX_SLOTS; s++) {
                        if (slots[s].active) { s0 = s; break; }
                    }

                    if (s0 >= 0) {
                        double dx = slots[s0].x - slots[s0].start_x;
                        double dy = slots[s0].y - slots[s0].start_y;

                        // Right edge slider -> Volume via DMS IPC
                        if (is_right_slider && fabs(dy) > fabs(dx)) {
                            double step_dy = slots[s0].y - slider_last_y;
                            if (step_dy <= -SLIDER_STEP) {
                                trigger_slider_step("dms ipc call audio increment 5");
                                slider_last_y = slots[s0].y;
                                gesture_fired = 1;
                            } else if (step_dy >= SLIDER_STEP) {
                                trigger_slider_step("dms ipc call audio decrement 5");
                                slider_last_y = slots[s0].y;
                                gesture_fired = 1;
                            }
                        }
                        // Left edge slider -> Brightness via DMS IPC (with OSD sync)
                        else if (is_left_slider && fabs(dy) > fabs(dx)) {
                            double step_dy = slots[s0].y - slider_last_y;
                            if (step_dy <= -SLIDER_STEP) {
                                char cmd[128];
                                snprintf(cmd, sizeof(cmd), "dms ipc call brightness increment 5 %s", brightness_dev);
                                trigger_slider_step(cmd);
                                slider_last_y = slots[s0].y;
                                gesture_fired = 1;
                            } else if (step_dy >= SLIDER_STEP) {
                                char cmd[128];
                                snprintf(cmd, sizeof(cmd), "dms ipc call brightness decrement 5 %s", brightness_dev);
                                trigger_slider_step(cmd);
                                slider_last_y = slots[s0].y;
                                gesture_fired = 1;
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // 3 FINGERS: MOVE VIEW FOCUS (Workspaces & Columns)
                // -------------------------------------------------------------
                else if (active_count == 3 && !gesture_fired) {
                    double avg_dx = 0, avg_dy = 0;
                    for (int s = 0; s < MAX_SLOTS; s++) {
                        if (slots[s].active) {
                            avg_dx += (slots[s].x - slots[s].start_x);
                            avg_dy += (slots[s].y - slots[s].start_y);
                        }
                    }
                    avg_dx /= 3.0;
                    avg_dy /= 3.0;

                    // Vertical: Workspace focus
                    if (fabs(avg_dy) > SWIPE_THRESHOLD && fabs(avg_dy) > 1.25 * fabs(avg_dx)) {
                        if (avg_dy < 0) {
                            trigger_action("niri msg action focus-workspace-down");
                        } else {
                            trigger_action("niri msg action focus-workspace-up");
                        }
                    }
                    // Horizontal: Column focus
                    else if (fabs(avg_dx) > SWIPE_THRESHOLD && fabs(avg_dx) > 1.25 * fabs(avg_dy)) {
                        if (avg_dx < 0) {
                            trigger_action("niri msg action focus-column-right");
                        } else {
                            trigger_action("niri msg action focus-column-left");
                        }
                    }
                }

                // -------------------------------------------------------------
                // 4 FINGERS: MOVE ACTIVE WINDOW (Swipe) OR TOGGLE OVERVIEW (Pinch)
                // -------------------------------------------------------------
                else if (active_count == 4 && !gesture_fired) {
                    double cx = 0, cy = 0;
                    double avg_dx = 0, avg_dy = 0;
                    for (int s = 0; s < MAX_SLOTS; s++) {
                        if (slots[s].active) {
                            cx += slots[s].x;
                            cy += slots[s].y;
                            avg_dx += (slots[s].x - slots[s].start_x);
                            avg_dy += (slots[s].y - slots[s].start_y);
                        }
                    }
                    cx /= 4.0; cy /= 4.0;
                    avg_dx /= 4.0; avg_dy /= 4.0;

                    double curr_r = 0.0;
                    for (int s = 0; s < MAX_SLOTS; s++) {
                        if (slots[s].active) {
                            curr_r += hypot(slots[s].x - cx, slots[s].y - cy);
                        }
                    }
                    curr_r /= 4.0;

                    double delta_r = four_finger_start_r - curr_r;

                    // Pinch-In -> Overview
                    if (delta_r > PINCH_THRESHOLD && hypot(avg_dx, avg_dy) < 80.0) {
                        trigger_action("niri msg action toggle-overview");
                    }
                    // 4-finger Swipe -> Move active window / column (Inverted: Up -> Workspace Up, Down -> Workspace Down)
                    else if (fabs(avg_dy) > SWIPE_THRESHOLD && fabs(avg_dy) > 1.25 * fabs(avg_dx)) {
                        if (avg_dy < 0) {
                            trigger_action("niri msg action move-column-to-workspace-up");
                        } else {
                            trigger_action("niri msg action move-column-to-workspace-down");
                        }
                    }
                    else if (fabs(avg_dx) > SWIPE_THRESHOLD && fabs(avg_dx) > 1.25 * fabs(avg_dy)) {
                        if (avg_dx < 0) {
                            trigger_action("niri msg action move-column-left");
                        } else {
                            trigger_action("niri msg action move-column-right");
                        }
                    }
                }
            }
        }
    }

    close(fd);
    close(epfd);
    return 0;
}
