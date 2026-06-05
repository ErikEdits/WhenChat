package com.mukse.whenchat.neoforge;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

/**
 * Pure helper for the timestamp prefix. Duplicated per-loader to keep each
 * subproject self-contained.
 */
public final class TimestampPrefix {

	private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

	private TimestampPrefix() {
	}

	public static String now() {
		return format(LocalTime.now());
	}

	public static String format(LocalTime time) {
		return "[" + time.format(FMT) + "] ";
	}
}
