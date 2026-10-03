#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "../../adapter/native/rg35xx_input.c"

static void fail(const char *name, uint32_t expected, uint32_t actual) {
    fprintf(stderr, "P2C_NATIVE_HOST_GATE_FAIL=%s expected=0x%08x actual=0x%08x\n", name, expected, actual);
    exit(1);
}

static void reset_model(void) {
    state_bits = 0;
    axis2 = -32767;
    axis5 = -32767;
    axis6 = 0;
    axis7 = 0;
    update_axis_bits();
}

static void expect_bits(const char *name, uint32_t expected) {
    if (state_bits != expected) fail(name, expected, state_bits);
}

static void emit_axis(uint8_t number, int16_t value) {
    struct js_event e;
    e.time = 0; e.value = value; e.type = JS_EVENT_AXIS; e.number = number;
    apply_event(&e);
}

static void emit_button(uint8_t number, int16_t value) {
    struct js_event e;
    e.time = 0; e.value = value; e.type = JS_EVENT_BUTTON; e.number = number;
    apply_event(&e);
}

int main(void) {
    static const struct { uint8_t button; unsigned bit; } buttons[] = {
        {0,4},{1,5},{2,6},{3,7},{5,8},{6,9},{8,10},{7,11}
    };
    size_t i;

    reset_model();
    expect_bits("baseline", 0);

    emit_axis(7, -32767); expect_bits("up_press", 1u<<0);
    emit_axis(7, 0); expect_bits("up_release", 0);
    emit_axis(7, 32767); expect_bits("down_press", 1u<<1);
    emit_axis(7, 0); expect_bits("down_release", 0);
    emit_axis(6, -32767); expect_bits("left_press", 1u<<2);
    emit_axis(6, 0); expect_bits("left_release", 0);
    emit_axis(6, 32767); expect_bits("right_press", 1u<<3);
    emit_axis(6, 0); expect_bits("right_release", 0);

    for (i = 0; i < sizeof(buttons)/sizeof(buttons[0]); i++) {
        emit_button(buttons[i].button, 1);
        expect_bits("button_press", 1u << buttons[i].bit);
        emit_button(buttons[i].button, 0);
        expect_bits("button_release", 0);
    }

    emit_axis(2, -32767); expect_bits("l2_baseline", 0);
    emit_axis(2, 32767); expect_bits("l2_press", 1u<<12);
    emit_axis(2, -32767); expect_bits("l2_release", 0);

    emit_axis(5, -32767); expect_bits("r2_baseline", 0);
    emit_axis(5, 32767); expect_bits("r2_press", 1u<<13);
    emit_axis(5, -32767); expect_bits("r2_release", 0);

    emit_axis(2, 32767); emit_axis(5, 32767); emit_axis(7, -32767); emit_button(0, 1);
    expect_bits("combined", (1u<<12)|(1u<<13)|(1u<<0)|(1u<<4));

    printf("P2C_NATIVE_EXISTING_12_CONTROL_GATE=PASS\n");
    printf("P2C_NATIVE_L2_AXIS2_GATE=PASS\n");
    printf("P2C_NATIVE_R2_AXIS5_GATE=PASS\n");
    printf("P2C_NATIVE_14_CONTROL_HOST_GATE=PASS\n");
    return 0;
}
