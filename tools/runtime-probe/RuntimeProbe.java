package org.recompile.rg35xx.runtimeprobe;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

/**
 * Device-side diagnostic for a JamVM + GNU Classpath candidate.
 * This intentionally does not alter CFW/java or any protected runtime path.
 */
public final class RuntimeProbe
{
	private static int failures;

	private static void marker(String name, String value)
	{
		System.out.println(name + "=" + value);
	}

	private static void check(String name, boolean ok)
	{
		marker(name, ok ? "PASS" : "FAIL");
		if (!ok) { failures++; }
	}

	private static void classCheck(String name)
	{
		try
		{
			Class.forName(name);
			check("CLASS_" + name.replace('.', '_'), true);
		}
		catch (Throwable e)
		{
			check("CLASS_" + name.replace('.', '_'), false);
			System.out.println("CLASS_ERROR=" + name + ":" + e.toString());
		}
	}

	private static boolean fileRoundTrip(File root)
	{
		File file = new File(root, "roundtrip.bin");
		byte[] expected = new byte[] { 0, 1, 2, 3, 85, 127, -1 };
		try
		{
			if (!root.exists() && !root.mkdirs()) { return false; }
			FileOutputStream out = new FileOutputStream(file);
			out.write(expected);
			out.close();
			FileInputStream in = new FileInputStream(file);
			byte[] actual = new byte[expected.length];
			int count = in.read(actual);
			in.close();
			boolean same = count == expected.length;
			for (int i = 0; i < expected.length && same; i++) { same = expected[i] == actual[i]; }
			file.delete();
			return same;
		}
		catch (Throwable e)
		{
			System.out.println("FILE_ERROR=" + e.toString());
			return false;
		}
	}

	private static boolean threadRoundTrip()
	{
		final boolean[] ran = new boolean[] { false };
		Thread t = new Thread(new Runnable()
		{
			public void run() { ran[0] = true; }
		});
		try
		{
			t.start();
			t.join(2000);
			return ran[0] && !t.isAlive();
		}
		catch (Throwable e)
		{
			System.out.println("THREAD_ERROR=" + e.toString());
			return false;
		}
	}

	public static void main(String[] args)
	{
		marker("RUNTIME_PROBE_START", "YES");
		marker("RUNTIME_PROTECTED_PATH_MUTATION", "NO");
		marker("JAVA_VERSION", System.getProperty("java.version", "unknown"));
		marker("JAVA_VM", System.getProperty("java.vm.name", "unknown"));
		marker("OS_ARCH", System.getProperty("os.arch", "unknown"));
		check("PROPERTY_GATE", System.getProperty("java.version") != null);
		File root = new File(args.length > 0 ? args[0] : "runtime-probe-data");
		check("FILE_IO_GATE", fileRoundTrip(root));
		check("THREAD_GATE", threadRoundTrip());
		classCheck("org.recompile.mobile.Mobile");
		classCheck("org.recompile.rg35xx.RG35XXLauncher");
		marker("RUNTIME_PROBE_RESULT", failures == 0 ? "PASS" : "FAIL");
		if (failures != 0) { System.exit(2); }
	}
}
