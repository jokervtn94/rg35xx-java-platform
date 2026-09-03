#include "rg35xx_media_event_queue.h"
#include <pthread.h>
#include <string.h>

static pthread_mutex_t g_event_mutex = PTHREAD_MUTEX_INITIALIZER;
static struct rg35xx_media_event_record g_events[RG35XX_MEDIA_EVENT_QUEUE_CAPACITY];
static unsigned int g_head;
static unsigned int g_tail;
static unsigned int g_count;

void rg35xx_media_event_queue_reset(void)
{
    pthread_mutex_lock(&g_event_mutex);
    g_head = 0;
    g_tail = 0;
    g_count = 0;
    memset(g_events, 0, sizeof(g_events));
    pthread_mutex_unlock(&g_event_mutex);
}

void rg35xx_media_event_queue_push(uint8_t event_type,
                                   uint32_t player_id,
                                   uint64_t media_time_us)
{
    pthread_mutex_lock(&g_event_mutex);

    if(g_count == RG35XX_MEDIA_EVENT_QUEUE_CAPACITY)
    {
        /* Keep the newest completion state and discard the oldest stale event. */
        g_head = (g_head + 1U) % RG35XX_MEDIA_EVENT_QUEUE_CAPACITY;
        g_count--;
    }

    g_events[g_tail].event_type = event_type;
    g_events[g_tail].player_id = player_id;
    g_events[g_tail].media_time_us = media_time_us;
    g_tail = (g_tail + 1U) % RG35XX_MEDIA_EVENT_QUEUE_CAPACITY;
    g_count++;

    pthread_mutex_unlock(&g_event_mutex);
}

int rg35xx_media_event_queue_pop(struct rg35xx_media_event_record *out)
{
    int have_event = 0;
    if(!out) return 0;

    pthread_mutex_lock(&g_event_mutex);
    if(g_count)
    {
        *out = g_events[g_head];
        memset(&g_events[g_head], 0, sizeof(g_events[g_head]));
        g_head = (g_head + 1U) % RG35XX_MEDIA_EVENT_QUEUE_CAPACITY;
        g_count--;
        have_event = 1;
    }
    pthread_mutex_unlock(&g_event_mutex);

    return have_event;
}
