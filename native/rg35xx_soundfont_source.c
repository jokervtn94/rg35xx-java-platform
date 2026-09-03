#include "rg35xx_soundfont_source.h"

static const uint8_t *g_soundfont_data;
static size_t g_soundfont_size;

int rg35xx_soundfont_source_set(const uint8_t *data, size_t size)
{
    if (!data || size == 0) return 0;
    g_soundfont_data = data;
    g_soundfont_size = size;
    return 1;
}

void rg35xx_soundfont_source_clear(void)
{
    g_soundfont_data = 0;
    g_soundfont_size = 0;
}

int rg35xx_soundfont_source_ready(void)
{
    return g_soundfont_data != 0 && g_soundfont_size != 0;
}

const uint8_t *rg35xx_soundfont_source_data(void)
{
    return g_soundfont_data;
}

size_t rg35xx_soundfont_source_size(void)
{
    return g_soundfont_size;
}
