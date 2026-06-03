package com.mukse.whenchat;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

/**
 * Pure helper for building the timestamp prefix that {@code ChatHudMixin}
 * stitches onto every incoming chat message.
 *
 * <p>Extracted from the mixin so it can be unit-tested without bringing the
 * Minecraft / Mixin runtime into the test classpath.
 */
public final class TimestampPrefix {

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

	private TimestampPrefix() {
	}

	/**
	 * Returns the formatted prefix for the current local time, including the
	 * trailing space that separates it from the message body, e.g. {@code "[14:23:05] "}.
	 */
	public static String now() {
		return format(LocalTime.now());
	}

	/**
	 * Returns the formatted prefix for the given time, including the trailing
	 * space, e.g. {@code "[14:23:05] "}.
	 */
	public static String format(LocalTime time) {
		return "[" + time.format(FMT) + "] ";
	}
}
