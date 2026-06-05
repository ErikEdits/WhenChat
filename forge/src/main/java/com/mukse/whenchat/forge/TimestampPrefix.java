package com.mukse.whenchat.forge;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

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
