#include "rg35xx_media_runtime.h"

#include "rg35xx_soundfont_source.h"
#include "rg35xx_tsf_worker.h"

static int g_media_runtime_ready;

int rg35xx_media_runtime_init(const uint8_t *soundfont, size_t size)
{
    if (g_media_runtime_ready) return 1;

    if (!rg35xx_soundfont_source_set(soundfont, size)) return 0;

    if (!rg35xx_tsf_worker_init(rg35xx_soundfont_source_data(),
                                rg35xx_soundfont_source_size())) {
        rg35xx_soundfont_source_clear();
        return 0;
    }

    g_media_runtime_ready = 1;
    return 1;
}

void rg35xx_media_runtime_shutdown(void)
{
    if (g_media_runtime_ready || rg35xx_tsf_worker_ready()) {
        rg35xx_tsf_worker_shutdown();
    }

    g_media_runtime_ready = 0;
    rg35xx_soundfont_source_clear();
}

int rg35xx_media_runtime_ready(void)
{
    return g_media_runtime_ready && rg35xx_soundfont_source_ready() &&
           rg35xx_tsf_worker_ready();
}
