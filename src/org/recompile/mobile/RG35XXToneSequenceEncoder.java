package org.recompile.mobile;

import java.io.ByteArrayOutputStream;

import javax.microedition.media.control.ToneControl;

/**
 * JavaSound-free MIDP ToneControl -> Standard MIDI File (format 0) encoder.
 *
 * The encoder follows the MIDP 2.0 ToneControl sequence grammar and produces a
 * monotonic channel-0 MIDI track suitable for TinyMidiLoader/TinySoundFont.
 * It is a load/control path, not an audio render path.
 *
 * Tasklog: RGJ-RC1-010M.
 */
public final class RG35XXToneSequenceEncoder
{
    private static final int DEFAULT_TEMPO_MODIFIER = 30; /* 120 BPM */
    private static final int DEFAULT_RESOLUTION = 64;
    private static final int MAX_BLOCKS = 128;
    private static final int MAX_EXPANDED_EVENTS = 131072;

    private RG35XXToneSequenceEncoder() { }

    public static byte[] encode(byte[] sequence)
    {
        if(sequence == null) throw new IllegalArgumentException("null tone sequence");
        if(sequence.length < 4) throw invalid("sequence too short");

        int p = 0;
        if(sequence[p++] != ToneControl.VERSION || unsigned(sequence[p++]) != 1)
            throw invalid("VERSION 1 must be first");

        int tempoModifier = DEFAULT_TEMPO_MODIFIER;
        int resolution = DEFAULT_RESOLUTION;

        if(p < sequence.length && sequence[p] == ToneControl.TEMPO)
        {
            if(p + 1 >= sequence.length) throw invalid("truncated TEMPO");
            tempoModifier = unsigned(sequence[p + 1]);
            if(tempoModifier < 5 || tempoModifier > 127)
                throw invalid("invalid TEMPO");
            p += 2;
        }

        if(p < sequence.length && sequence[p] == ToneControl.RESOLUTION)
        {
            if(p + 1 >= sequence.length) throw invalid("truncated RESOLUTION");
            resolution = unsigned(sequence[p + 1]);
            if(resolution < 1 || resolution > 127)
                throw invalid("invalid RESOLUTION");
            p += 2;
        }

        int[] blockStart = new int[MAX_BLOCKS];
        int[] blockEnd = new int[MAX_BLOCKS];
        for(int i = 0; i < MAX_BLOCKS; i++)
        {
            blockStart[i] = -1;
            blockEnd[i] = -1;
        }

        while(p < sequence.length && sequence[p] == ToneControl.BLOCK_START)
        {
            if(p + 1 >= sequence.length) throw invalid("truncated BLOCK_START");
            int block = unsigned(sequence[p + 1]);
            if(block > 127 || blockStart[block] >= 0)
                throw invalid("invalid or duplicate block");

            int bodyStart = p + 2;
            int q = bodyStart;
            while(q < sequence.length && sequence[q] != ToneControl.BLOCK_END)
                q = validateEvent(sequence, q, sequence.length, blockStart);

            if(q + 1 >= sequence.length || sequence[q] != ToneControl.BLOCK_END)
                throw invalid("missing BLOCK_END");
            if(unsigned(sequence[q + 1]) != block)
                throw invalid("BLOCK_END id mismatch");
            if(q == bodyStart) throw invalid("empty block");

            blockStart[block] = bodyStart;
            blockEnd[block] = q;
            p = q + 2;
        }

        if(p >= sequence.length) throw invalid("missing sequence events");

        /* Validate the main event stream before producing output. */
        int q = p;
        while(q < sequence.length)
            q = validateEvent(sequence, q, sequence.length, blockStart);

        MidiTrack track = new MidiTrack(resolution, tempoModifier);
        renderRange(sequence, p, sequence.length, blockStart, blockEnd, track, 0);
        return track.finish();
    }

    /** Encode Manager.playTone() without using javax.sound.midi. */
    public static byte[] encodeSingleTone(int note, int durationMs, int volume)
    {
        if(note < 0 || note > 127) throw invalid("invalid note");
        if(durationMs <= 0) throw invalid("invalid duration");
        if(volume < 0) volume = 0;
        if(volume > 100) volume = 100;

        /* 1000 PPQ + 1,000,000 us/quarter gives exactly one millisecond/tick. */
        MidiTrack track = new MidiTrack(1000, 0);
        track.writeTempoUsPerQuarter(1000000);
        track.setVolume(volume);
        track.noteForTicks(note, durationMs);
        return track.finishWithoutDefaultTempo();
    }

    private static int validateEvent(byte[] sequence, int p, int limit, int[] blockStart)
    {
        if(p >= limit) throw invalid("truncated event");
        int op = sequence[p];

        if(op == ToneControl.PLAY_BLOCK)
        {
            if(p + 1 >= limit) throw invalid("truncated PLAY_BLOCK");
            int block = unsigned(sequence[p + 1]);
            if(block > 127 || blockStart[block] < 0)
                throw invalid("PLAY_BLOCK must reference a previous block");
            return p + 2;
        }

        if(op == ToneControl.SET_VOLUME)
        {
            if(p + 1 >= limit) throw invalid("truncated SET_VOLUME");
            int volume = unsigned(sequence[p + 1]);
            if(volume > 100) throw invalid("invalid volume");
            return p + 2;
        }

        if(op == ToneControl.REPEAT)
        {
            if(p + 3 >= limit) throw invalid("truncated REPEAT");
            int multiplier = unsigned(sequence[p + 1]);
            if(multiplier < 2 || multiplier > 127)
                throw invalid("invalid repeat multiplier");
            validateTone(sequence[p + 2], unsigned(sequence[p + 3]));
            return p + 4;
        }

        if(op == ToneControl.BLOCK_START || op == ToneControl.BLOCK_END ||
           op == ToneControl.VERSION || op == ToneControl.TEMPO ||
           op == ToneControl.RESOLUTION)
            throw invalid("attribute/block tag in event stream");

        if(p + 1 >= limit) throw invalid("truncated tone event");
        validateTone(sequence[p], unsigned(sequence[p + 1]));
        return p + 2;
    }

    private static void validateTone(byte noteByte, int duration)
    {
        int note = noteByte;
        if(note != ToneControl.SILENCE && (note < 0 || note > 127))
            throw invalid("invalid note");
        if(duration < 1 || duration > 127)
            throw invalid("invalid duration");
    }

    private static void renderRange(byte[] sequence, int start, int end,
                                    int[] blockStart, int[] blockEnd,
                                    MidiTrack track, int depth)
    {
        if(depth > MAX_BLOCKS) throw invalid("block expansion too deep");

        int p = start;
        while(p < end)
        {
            int op = sequence[p];

            if(op == ToneControl.PLAY_BLOCK)
            {
                int block = unsigned(sequence[p + 1]);
                track.countEvent();
                renderRange(sequence, blockStart[block], blockEnd[block],
                            blockStart, blockEnd, track, depth + 1);
                p += 2;
            }
            else if(op == ToneControl.SET_VOLUME)
            {
                track.countEvent();
                track.setVolume(unsigned(sequence[p + 1]));
                p += 2;
            }
            else if(op == ToneControl.REPEAT)
            {
                int multiplier = unsigned(sequence[p + 1]);
                int note = sequence[p + 2];
                int duration = unsigned(sequence[p + 3]);
                for(int i = 0; i < multiplier; i++)
                {
                    track.countEvent();
                    track.tone(note, duration);
                }
                p += 4;
            }
            else
            {
                int note = sequence[p];
                int duration = unsigned(sequence[p + 1]);
                track.countEvent();
                track.tone(note, duration);
                p += 2;
            }
        }
    }

    private static int unsigned(byte b) { return b & 0xFF; }

    private static IllegalArgumentException invalid(String message)
    {
        return new IllegalArgumentException("invalid ToneControl sequence: " + message);
    }

    private static final class MidiTrack
    {
        private final ByteArrayOutputStream data = new ByteArrayOutputStream(512);
        private final int division;
        private long currentTick;
        private long lastEventTick;
        private int expandedEvents;
        private boolean finished;
        private boolean defaultTempoWritten;

        MidiTrack(int division, int tempoModifier)
        {
            if(division < 1 || division > 32767) throw invalid("invalid MIDI division");
            this.division = division;
            if(tempoModifier > 0)
            {
                int bpm = tempoModifier * 4;
                writeTempoUsPerQuarter(60000000 / bpm);
                defaultTempoWritten = true;
            }
        }

        void countEvent()
        {
            expandedEvents++;
            if(expandedEvents > MAX_EXPANDED_EVENTS)
                throw invalid("expanded event limit exceeded");
        }

        void writeTempoUsPerQuarter(int us)
        {
            if(us < 1 || us > 0xFFFFFF) throw invalid("invalid MIDI tempo");
            writeDelta(0);
            data.write(0xFF);
            data.write(0x51);
            data.write(0x03);
            data.write((us >>> 16) & 0xFF);
            data.write((us >>> 8) & 0xFF);
            data.write(us & 0xFF);
        }

        void setVolume(int volume)
        {
            if(volume < 0 || volume > 100) throw invalid("invalid volume");
            writeAtCurrentTick();
            data.write(0xB0);
            data.write(7);
            data.write((volume * 127 + 50) / 100);
        }

        void tone(int note, int durationUnits)
        {
            int ticks = durationUnits * 4;
            if(note == ToneControl.SILENCE)
            {
                currentTick += ticks;
                return;
            }
            noteForTicks(note, ticks);
        }

        void noteForTicks(int note, long ticks)
        {
            if(note < 0 || note > 127 || ticks <= 0)
                throw invalid("invalid MIDI note");
            writeAtCurrentTick();
            data.write(0x90);
            data.write(note);
            data.write(127);

            currentTick += ticks;
            writeAtCurrentTick();
            data.write(0x80);
            data.write(note);
            data.write(0);
        }

        private void writeAtCurrentTick()
        {
            long delta = currentTick - lastEventTick;
            if(delta < 0 || delta > 0x0FFFFFFFL)
                throw invalid("MIDI delta out of range");
            writeDelta(delta);
            lastEventTick = currentTick;
        }

        private void writeDelta(long value)
        {
            int buffer = (int)(value & 0x7F);
            while((value >>= 7) != 0)
            {
                buffer <<= 8;
                buffer |= ((int)value & 0x7F) | 0x80;
            }
            while(true)
            {
                data.write(buffer & 0xFF);
                if((buffer & 0x80) != 0) buffer >>>= 8;
                else break;
            }
        }

        byte[] finish()
        {
            if(!defaultTempoWritten) throw invalid("tempo not initialized");
            return finishInternal();
        }

        byte[] finishWithoutDefaultTempo()
        {
            return finishInternal();
        }

        private byte[] finishInternal()
        {
            if(finished) throw new IllegalStateException("MIDI track already finished");
            writeAtCurrentTick();
            data.write(0xFF);
            data.write(0x2F);
            data.write(0x00);
            finished = true;

            byte[] track = data.toByteArray();
            ByteArrayOutputStream out = new ByteArrayOutputStream(track.length + 22);

            writeAscii(out, "MThd");
            writeInt(out, 6);
            writeShort(out, 0); /* format 0 */
            writeShort(out, 1); /* one track */
            writeShort(out, division);

            writeAscii(out, "MTrk");
            writeInt(out, track.length);
            out.write(track, 0, track.length);
            return out.toByteArray();
        }

        private static void writeAscii(ByteArrayOutputStream out, String s)
        {
            for(int i = 0; i < s.length(); i++) out.write((byte)s.charAt(i));
        }

        private static void writeShort(ByteArrayOutputStream out, int value)
        {
            out.write((value >>> 8) & 0xFF);
            out.write(value & 0xFF);
        }

        private static void writeInt(ByteArrayOutputStream out, int value)
        {
            out.write((value >>> 24) & 0xFF);
            out.write((value >>> 16) & 0xFF);
            out.write((value >>> 8) & 0xFF);
            out.write(value & 0xFF);
        }
    }
}
