package org.recompile.mobile;

import java.io.ByteArrayOutputStream;
import java.io.EOFException;
import java.io.IOException;
import java.io.InputStream;

/**
 * RG35XX WAV parser/normalizer for the native PCM16 mixer.
 *
 * Deliberately uses java.io only: no JavaSound, host mixer probing, or desktop
 * resampling. The native mixer receives source sample-rate/channels and owns
 * output-rate conversion.
 *
 * Supported RIFF/WAVE payloads:
 *  - PCM 8-bit unsigned / PCM 16-bit signed little-endian
 *  - Microsoft IMA ADPCM (format 0x11), mono/stereo block layout
 *  - A-law (format 6)
 *  - mu-law (format 7)
 *
 * Tasklog: RGJ-RC1-010B.
 */
public final class RG35XXWavDecoder
{
    private static final int FORMAT_PCM = 0x0001;
    private static final int FORMAT_ALAW = 0x0006;
    private static final int FORMAT_ULAW = 0x0007;
    private static final int FORMAT_IMA_ADPCM = 0x0011;

    private static final int[] IMA_INDEX = {
        -1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8
    };

    private static final int[] IMA_STEP = {
        7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,
        50,55,60,66,73,80,88,97,107,118,130,143,157,173,190,209,
        230,253,279,307,337,371,408,449,494,544,598,658,724,796,
        876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,
        2749,3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,
        8630,9493,10442,11487,12635,13899,15289,16818,18500,20350,
        22385,24623,27086,29794,32767
    };

    public static final class Decoded
    {
        public final byte[] pcm16;
        public final int sampleRate;
        public final int channels;

        private Decoded(byte[] pcm16, int sampleRate, int channels)
        {
            this.pcm16 = pcm16;
            this.sampleRate = sampleRate;
            this.channels = channels;
        }
    }

    private RG35XXWavDecoder() {}

    public static Decoded decode(InputStream input) throws IOException
    {
        if(input == null) throw new NullPointerException("input");
        return decode(readAll(input));
    }

    public static Decoded decode(byte[] wav) throws IOException
    {
        if(wav == null) throw new NullPointerException("wav");
        if(wav.length < 12 || !fourCC(wav, 0, "RIFF") || !fourCC(wav, 8, "WAVE"))
            throw new IOException("not RIFF/WAVE");

        int format = -1;
        int channels = 0;
        int sampleRate = 0;
        int blockAlign = 0;
        int bits = 0;
        int dataOffset = -1;
        int dataLength = 0;

        int p = 12;
        while(p <= wav.length - 8)
        {
            int chunkSize = le32(wav, p + 4);
            if(chunkSize < 0) throw new IOException("invalid WAV chunk size");
            int body = p + 8;
            if(body > wav.length || chunkSize > wav.length - body)
                throw new IOException("truncated WAV chunk");

            if(fourCC(wav, p, "fmt "))
            {
                if(chunkSize < 16) throw new IOException("short WAV fmt chunk");
                format = le16(wav, body);
                channels = le16(wav, body + 2);
                sampleRate = le32(wav, body + 4);
                blockAlign = le16(wav, body + 12);
                bits = le16(wav, body + 14);
            }
            else if(fourCC(wav, p, "data") && dataOffset < 0)
            {
                dataOffset = body;
                dataLength = chunkSize;
            }

            long next = (long)body + (long)chunkSize + (long)(chunkSize & 1);
            if(next > wav.length) {
                if(body + chunkSize == wav.length) p = wav.length;
                else throw new IOException("truncated WAV padding");
            } else p = (int)next;
        }

        if(format < 0 || dataOffset < 0) throw new IOException("missing WAV fmt/data chunk");
        if(channels < 1 || channels > 2) throw new IOException("unsupported WAV channels: " + channels);
        if(sampleRate <= 0) throw new IOException("invalid WAV sample rate");

        byte[] pcm;
        if(format == FORMAT_PCM)
            pcm = decodePcm(wav, dataOffset, dataLength, channels, bits, blockAlign);
        else if(format == FORMAT_IMA_ADPCM)
            pcm = decodeIma(wav, dataOffset, dataLength, channels, blockAlign);
        else if(format == FORMAT_ALAW || format == FORMAT_ULAW)
            pcm = decodeLaw(wav, dataOffset, dataLength, format == FORMAT_ALAW);
        else
            throw new IOException("unsupported WAV format: " + format);

        return new Decoded(pcm, sampleRate, channels);
    }

    private static byte[] decodePcm(byte[] src, int off, int len, int channels, int bits, int blockAlign) throws IOException
    {
        if(bits == 16)
        {
            if(blockAlign != 0 && blockAlign < channels * 2) throw new IOException("invalid PCM blockAlign");
            int usable = len & ~1;
            byte[] out = new byte[usable];
            System.arraycopy(src, off, out, 0, usable);
            return out;
        }
        if(bits == 8)
        {
            byte[] out = new byte[len * 2];
            int o = 0;
            for(int i = 0; i < len; i++)
            {
                int sample = ((src[off + i] & 0xff) - 128) << 8;
                out[o++] = (byte)sample;
                out[o++] = (byte)(sample >> 8);
            }
            return out;
        }
        throw new IOException("unsupported PCM bits: " + bits);
    }

    private static byte[] decodeLaw(byte[] src, int off, int len, boolean aLaw)
    {
        byte[] out = new byte[len * 2];
        int o = 0;
        for(int i = 0; i < len; i++)
        {
            int s = aLaw ? decodeALaw(src[off + i] & 0xff) : decodeULaw(src[off + i] & 0xff);
            out[o++] = (byte)s;
            out[o++] = (byte)(s >> 8);
        }
        return out;
    }

    private static int decodeALaw(int a)
    {
        a ^= 0x55;
        int t = (a & 0x0f) << 4;
        int seg = (a & 0x70) >> 4;
        if(seg == 0) t += 8;
        else if(seg == 1) t += 0x108;
        else { t += 0x108; t <<= seg - 1; }
        return (a & 0x80) != 0 ? t : -t;
    }

    private static int decodeULaw(int u)
    {
        u = (~u) & 0xff;
        int t = ((u & 0x0f) << 3) + 0x84;
        t <<= (u & 0x70) >> 4;
        t -= 0x84;
        return (u & 0x80) != 0 ? -t : t;
    }

    private static byte[] decodeIma(byte[] src, int off, int len, int channels, int blockAlign) throws IOException
    {
        int header = channels * 4;
        if(blockAlign <= header) throw new IOException("invalid IMA blockAlign");
        ByteArrayOutputStream out = new ByteArrayOutputStream(len * 4);
        int end = off + len;
        int block = off;
        int[] predictor = new int[2];
        int[] index = new int[2];

        while(block < end)
        {
            int blockEnd = block + blockAlign;
            if(blockEnd > end) blockEnd = end;
            if(blockEnd - block < header) break;

            int p = block;
            for(int ch = 0; ch < channels; ch++)
            {
                predictor[ch] = signed16(src, p);
                index[ch] = src[p + 2] & 0xff;
                if(index[ch] > 88) index[ch] = 88;
                p += 4;
            }
            for(int ch = 0; ch < channels; ch++) writeSample(out, predictor[ch]);

            if(channels == 1)
            {
                while(p < blockEnd)
                {
                    int b = src[p++] & 0xff;
                    predictor[0] = imaNibble(predictor[0], index, 0, b & 0x0f);
                    writeSample(out, predictor[0]);
                    predictor[0] = imaNibble(predictor[0], index, 0, (b >> 4) & 0x0f);
                    writeSample(out, predictor[0]);
                }
            }
            else
            {
                while(p < blockEnd)
                {
                    byte[][] group = new byte[2][4];
                    int[] count = new int[2];
                    for(int ch = 0; ch < 2; ch++)
                        while(count[ch] < 4 && p < blockEnd) group[ch][count[ch]++] = src[p++];

                    int frames = Math.max(count[0], count[1]) * 2;
                    for(int frame = 0; frame < frames; frame++)
                    {
                        for(int ch = 0; ch < 2; ch++)
                        {
                            int bi = frame >> 1;
                            if(bi >= count[ch]) continue;
                            int b = group[ch][bi] & 0xff;
                            int nib = (frame & 1) == 0 ? (b & 0x0f) : ((b >> 4) & 0x0f);
                            predictor[ch] = imaNibble(predictor[ch], index, ch, nib);
                            writeSample(out, predictor[ch]);
                        }
                    }
                }
            }
            block += blockAlign;
        }
        return out.toByteArray();
    }

    private static int imaNibble(int predictor, int[] index, int ch, int nibble)
    {
        int step = IMA_STEP[index[ch]];
        int diff = step >> 3;
        if((nibble & 1) != 0) diff += step >> 2;
        if((nibble & 2) != 0) diff += step >> 1;
        if((nibble & 4) != 0) diff += step;
        if((nibble & 8) != 0) predictor -= diff; else predictor += diff;
        if(predictor > 32767) predictor = 32767;
        else if(predictor < -32768) predictor = -32768;
        index[ch] += IMA_INDEX[nibble & 0x0f];
        if(index[ch] < 0) index[ch] = 0;
        else if(index[ch] > 88) index[ch] = 88;
        return predictor;
    }

    private static void writeSample(ByteArrayOutputStream out, int sample)
    {
        out.write(sample & 0xff);
        out.write((sample >> 8) & 0xff);
    }

    private static boolean fourCC(byte[] b, int p, String s)
    {
        if(p < 0 || p > b.length - 4) return false;
        return b[p] == (byte)s.charAt(0) && b[p+1] == (byte)s.charAt(1)
            && b[p+2] == (byte)s.charAt(2) && b[p+3] == (byte)s.charAt(3);
    }

    private static int le16(byte[] b, int p) throws IOException
    {
        if(p < 0 || p > b.length - 2) throw new EOFException();
        return (b[p] & 0xff) | ((b[p+1] & 0xff) << 8);
    }

    private static int signed16(byte[] b, int p) throws IOException
    {
        return (short)le16(b, p);
    }

    private static int le32(byte[] b, int p) throws IOException
    {
        if(p < 0 || p > b.length - 4) throw new EOFException();
        long v = (long)(b[p] & 0xff) | ((long)(b[p+1] & 0xff) << 8)
            | ((long)(b[p+2] & 0xff) << 16) | ((long)(b[p+3] & 0xff) << 24);
        if(v > 0x7fffffffL) return -1;
        return (int)v;
    }

    private static byte[] readAll(InputStream in) throws IOException
    {
        ByteArrayOutputStream out = new ByteArrayOutputStream(4096);
        byte[] buf = new byte[4096];
        int n;
        while((n = in.read(buf)) != -1) out.write(buf, 0, n);
        return out.toByteArray();
    }
}
