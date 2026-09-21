#!/usr/bin/env python3
import pathlib, sys

if len(sys.argv) != 3:
    raise SystemExit('usage: b4_apply_dragon_media_trace_r1.py <Manager.java> <PlatformPlayer.java>')

mp = pathlib.Path(sys.argv[1])
pp = pathlib.Path(sys.argv[2])
M = mp.read_text(encoding='utf-8')
P = pp.read_text(encoding='utf-8')
orig = (M, P)

def once(s, old, new, label):
    n = s.count(old)
    if n != 1:
        raise SystemExit('B4 DRAGON MEDIA TRACE R1 FAIL %s count=%d' % (label, n))
    return s.replace(old, new, 1)

# Manager: trace media requests only. No media initialization or playback semantics change.
M = once(M,
'''public class Manager
{
''',
'''public class Manager
{
	private static int rg35xxB4MediaTraceSeq = 0;
	private static synchronized void rg35xxB4MediaTrace(String stage, String detail)
	{
		rg35xxB4MediaTraceSeq++;
		if(rg35xxB4MediaTraceSeq <= 96 || (rg35xxB4MediaTraceSeq % 256) == 0)
		{
			System.err.println("RG35XX-B4-MEDIA-TRACE stage=" + stage + " seq=" + rg35xxB4MediaTraceSeq + " detail=" + detail + " thread=" + Thread.currentThread().getName());
		}
	}
''', 'Manager trace helper')

M = once(M,
'''	public static synchronized Player createPlayer(InputStream stream, String type) throws IOException, MediaException
	{
		if (stream == null) { throw new IllegalArgumentException("Cannot create a player since the received stream is null"); }
''',
'''	public static synchronized Player createPlayer(InputStream stream, String type) throws IOException, MediaException
	{
		rg35xxB4MediaTrace("MANAGER_CREATE_STREAM_BEGIN", "type=" + String.valueOf(type));
		if (stream == null) { throw new IllegalArgumentException("Cannot create a player since the received stream is null"); }
''', 'Manager stream begin')

M = once(M,
'''		return new JavaxPlatformPlayer(stream, type);
	}
''',
'''		Player rg35xxB4Player = new JavaxPlatformPlayer(stream, type);
		rg35xxB4MediaTrace("MANAGER_CREATE_STREAM_DONE", "type=" + String.valueOf(type) + ":state=" + rg35xxB4Player.getState());
		return rg35xxB4Player;
	}
''', 'Manager stream done')

M = once(M,
'''	public static Player createPlayer(String locator) throws MediaException
	{
		if(locator == null) { throw new IllegalArgumentException("Cannot create a player with a null locator"); }
''',
'''	public static Player createPlayer(String locator) throws MediaException
	{
		rg35xxB4MediaTrace("MANAGER_CREATE_LOCATOR_BEGIN", "locator=" + String.valueOf(locator));
		if(locator == null) { throw new IllegalArgumentException("Cannot create a player with a null locator"); }
''', 'Manager locator begin')

old = '''		if(!locator.equals(Manager.TONE_DEVICE_LOCATOR) && !locator.equals(Manager.MIDI_DEVICE_LOCATOR)) { return new JavaxPlatformPlayer(stream, ""); } // Empty type, let PlatformPlayer handle it
		else { return new JavaxPlatformPlayer(locator); } // If it's a dedicated locator, PlatformPlayer can handle it directly
	}
'''
new = '''		Player rg35xxB4Player;
		if(!locator.equals(Manager.TONE_DEVICE_LOCATOR) && !locator.equals(Manager.MIDI_DEVICE_LOCATOR)) { rg35xxB4Player = new JavaxPlatformPlayer(stream, ""); } // Empty type, let PlatformPlayer handle it
		else { rg35xxB4Player = new JavaxPlatformPlayer(locator); } // If it's a dedicated locator, PlatformPlayer can handle it directly
		rg35xxB4MediaTrace("MANAGER_CREATE_LOCATOR_DONE", "locator=" + String.valueOf(locator) + ":state=" + rg35xxB4Player.getState());
		return rg35xxB4Player;
	}
'''
M = once(M, old, new, 'Manager locator done')

# PlatformPlayer: sparse lifecycle trace around state transitions and backend acquisition.
P = once(P,
'''public class PlatformPlayer implements Player
{
''',
'''public class PlatformPlayer implements Player
{
	private static int rg35xxB4MediaTraceSeq = 0;
	private static synchronized void rg35xxB4MediaTrace(String stage, String detail)
	{
		rg35xxB4MediaTraceSeq++;
		if(rg35xxB4MediaTraceSeq <= 160 || (rg35xxB4MediaTraceSeq % 256) == 0)
		{
			System.err.println("RG35XX-B4-MEDIA-TRACE stage=" + stage + " seq=" + rg35xxB4MediaTraceSeq + " detail=" + detail + " thread=" + Thread.currentThread().getName());
		}
	}
''', 'PlatformPlayer trace helper')

P = once(P,
'''	public void start()
	{
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot call start() on a CLOSED player."); }

		if(getState() == Player.UNREALIZED) { realize(); }

		if(getState() == Player.REALIZED) { prefetch(); }

		if(getState() == Player.PREFETCHED) { player.start(); }
	}
''',
'''	public void start()
	{
		rg35xxB4MediaTrace("PLAYER_START_BEGIN", "type=" + contentType + ":state=" + getState());
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot call start() on a CLOSED player."); }

		if(getState() == Player.UNREALIZED) { realize(); }
		rg35xxB4MediaTrace("PLAYER_START_AFTER_REALIZE", "type=" + contentType + ":state=" + getState());

		if(getState() == Player.REALIZED) { prefetch(); }
		rg35xxB4MediaTrace("PLAYER_START_AFTER_PREFETCH", "type=" + contentType + ":state=" + getState());

		if(getState() == Player.PREFETCHED)
		{
			rg35xxB4MediaTrace("PLAYER_BACKEND_START_BEGIN", "type=" + contentType + ":backend=" + player.getClass().getName());
			player.start();
			rg35xxB4MediaTrace("PLAYER_BACKEND_START_DONE", "type=" + contentType + ":state=" + getState());
		}
		else
		{
			rg35xxB4MediaTrace("PLAYER_START_BLOCKED_STATE", "type=" + contentType + ":state=" + getState());
		}
	}
''', 'PlatformPlayer outer start')

P = once(P,
'''	public void prefetch()
	{
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot prefetch player, as it is in the CLOSED state."); }

		if(getState() == Player.UNREALIZED) { realize(); }

		if(getState() == Player.REALIZED) { player.prefetch(); }
	}
''',
'''	public void prefetch()
	{
		rg35xxB4MediaTrace("PLAYER_PREFETCH_BEGIN", "type=" + contentType + ":state=" + getState());
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot prefetch player, as it is in the CLOSED state."); }

		if(getState() == Player.UNREALIZED) { realize(); }

		if(getState() == Player.REALIZED) { player.prefetch(); }
		rg35xxB4MediaTrace("PLAYER_PREFETCH_DONE", "type=" + contentType + ":state=" + getState());
	}
''', 'PlatformPlayer outer prefetch')

P = once(P,
'''	public void realize()
	{
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot realize player, as it is in the CLOSED state"); }

		if(getState() == Player.UNREALIZED) { player.realize(); }
	}
''',
'''	public void realize()
	{
		rg35xxB4MediaTrace("PLAYER_REALIZE_BEGIN", "type=" + contentType + ":state=" + getState());
		if(getState() == Player.CLOSED) { throw new IllegalStateException("Cannot realize player, as it is in the CLOSED state"); }

		if(getState() == Player.UNREALIZED) { player.realize(); }
		rg35xxB4MediaTrace("PLAYER_REALIZE_DONE", "type=" + contentType + ":state=" + getState());
	}
''', 'PlatformPlayer outer realize')

P = once(P,
'''	public void notifyListeners(String event, Object eventData)
	{
		// Paused events will never happen for these three
''',
'''	public void notifyListeners(String event, Object eventData)
	{
		rg35xxB4MediaTrace("PLAYER_EVENT", "type=" + contentType + ":event=" + String.valueOf(event) + ":state=" + getState());
		// Paused events will never happen for these three
''', 'notify listeners')

# MIDI backend: this is the highest-value path because B4 skips eager prepareMediaEngine().
P = once(P,
'''		public void prefetch()
		{
			try
			{
				midi = MidiSystem.getSequencer(false);
''',
'''		public void prefetch()
		{
			rg35xxB4MediaTrace("MIDI_PREFETCH_BEGIN", "exclusive0=" + (Manager.exclusiveSynths[0] == null ? "null" : "ready"));
			try
			{
				rg35xxB4MediaTrace("MIDI_GETSEQUENCER_BEGIN", "exclusive0=" + (Manager.exclusiveSynths[0] == null ? "null" : "ready"));
				midi = MidiSystem.getSequencer(false);
				rg35xxB4MediaTrace("MIDI_GETSEQUENCER_DONE", "midi=" + (midi == null ? "null" : "ready"));
''', 'midi prefetch')

P = once(P,
'''				prepareMidiSubsystem();
				state = Player.PREFETCHED;
			}
			catch(Exception e)
			{
				Mobile.log(Mobile.LOG_ERROR, PlatformPlayer.class.getPackage().getName() + "." + PlatformPlayer.class.getSimpleName() + ": " + "Could not prefetch midi stream:" + e.getMessage());
				state = Player.REALIZED;
			}
		}
''',
'''				rg35xxB4MediaTrace("MIDI_PREPARE_SUBSYSTEM_BEGIN", "exclusive0=" + (Manager.exclusiveSynths[0] == null ? "null" : "ready"));
				prepareMidiSubsystem();
				rg35xxB4MediaTrace("MIDI_PREPARE_SUBSYSTEM_DONE", "synth=" + (synthesizer == null ? "null" : "ready"));
				state = Player.PREFETCHED;
				rg35xxB4MediaTrace("MIDI_PREFETCH_DONE", "state=" + state);
			}
			catch(Exception e)
			{
				rg35xxB4MediaTrace("MIDI_PREFETCH_FAIL", e.getClass().getName() + ":" + String.valueOf(e.getMessage()));
				Mobile.log(Mobile.LOG_ERROR, PlatformPlayer.class.getPackage().getName() + "." + PlatformPlayer.class.getSimpleName() + ": " + "Could not prefetch midi stream:" + e.getMessage());
				state = Player.REALIZED;
			}
		}
''', 'midi subsystem trace')

# WAV backend: log whether AudioSystem.getClip() is the blocking/failing boundary.
P = once(P,
'''		public void prefetch()
		{
			try
			{
				if(wavClip == null)
				{
					wavClip = AudioSystem.getClip();
''',
'''		public void prefetch()
		{
			rg35xxB4MediaTrace("WAV_PREFETCH_BEGIN", "clip=" + (wavClip == null ? "null" : "ready"));
			try
			{
				if(wavClip == null)
				{
					rg35xxB4MediaTrace("WAV_GETCLIP_BEGIN", "state=" + state);
					wavClip = AudioSystem.getClip();
					rg35xxB4MediaTrace("WAV_GETCLIP_DONE", "clip=" + (wavClip == null ? "null" : "ready"));
''', 'wav prefetch start')

P = once(P,
'''				state = Player.PREFETCHED;
			}
			catch (Exception e)
			{
				Mobile.log(Mobile.LOG_ERROR, PlatformPlayer.class.getPackage().getName() + "." + PlatformPlayer.class.getSimpleName() + ": " + "Couldn't prefetch wav stream: " + e.getMessage());
				e.printStackTrace();
			}
		}
''',
'''				state = Player.PREFETCHED;
				rg35xxB4MediaTrace("WAV_PREFETCH_DONE", "state=" + state);
			}
			catch (Exception e)
			{
				rg35xxB4MediaTrace("WAV_PREFETCH_FAIL", e.getClass().getName() + ":" + String.valueOf(e.getMessage()));
				Mobile.log(Mobile.LOG_ERROR, PlatformPlayer.class.getPackage().getName() + "." + PlatformPlayer.class.getSimpleName() + ": " + "Couldn't prefetch wav stream: " + e.getMessage());
				e.printStackTrace();
			}
		}
''', 'wav prefetch done')

for token in (
    'RG35XX-B4-MEDIA-TRACE',
    'MANAGER_CREATE_STREAM_BEGIN',
    'PLAYER_START_BEGIN',
    'PLAYER_START_BLOCKED_STATE',
    'MIDI_GETSEQUENCER_BEGIN',
    'MIDI_PREFETCH_FAIL',
    'WAV_GETCLIP_BEGIN',
    'WAV_PREFETCH_FAIL',
    'PLAYER_EVENT',
):
    if token not in M and token not in P:
        raise SystemExit('B4 DRAGON MEDIA TRACE R1 FAIL missing marker: ' + token)

if (M, P) == orig:
    raise SystemExit('B4 DRAGON MEDIA TRACE R1 FAIL no mutation')

mp.write_text(M, encoding='utf-8', newline='\n')
pp.write_text(P, encoding='utf-8', newline='\n')

print('B4_DRAGON_MEDIA_TRACE_R1_PATCH=PASS')
print('PRIMARY_VARIABLE=BOUNDED_MEDIA_LIFECYCLE_OBSERVABILITY_ONLY')
print('MEDIA_BEHAVIOR_CHANGE=NONE')
print('RMS_CHANGE=NONE')
print('CORE_CHANGE=NONE')
