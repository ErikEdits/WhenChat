package com.mukse.whenchat;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import java.time.LocalTime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TimestampPrefixTest {

	@Test
	void formatsRegularTime() {
		assertEquals("[14:23:05] ", TimestampPrefix.format(LocalTime.of(14, 23, 5)));
	}

	@Test
	void padsSingleDigitsWithLeadingZero() {
		assertEquals("[01:02:03] ", TimestampPrefix.format(LocalTime.of(1, 2, 3)));
	}

	@Test
	void formatsMidnight() {
		assertEquals("[00:00:00] ", TimestampPrefix.format(LocalTime.MIDNIGHT));
	}

	@Test
	void formatsEndOfDay() {
		assertEquals("[23:59:59] ", TimestampPrefix.format(LocalTime.of(23, 59, 59)));
	}

	@Test
	void formatsNoon() {
		assertEquals("[12:00:00] ", TimestampPrefix.format(LocalTime.NOON));
	}

	@ParameterizedTest
	@CsvSource({
		"0,  0,  0,  '[00:00:00] '",
		"9,  5,  1,  '[09:05:01] '",
		"10, 10, 10, '[10:10:10] '",
		"15, 30, 45, '[15:30:45] '",
		"23, 59, 59, '[23:59:59] '"
	})
	void formatsAcrossDay(int h, int m, int s, String expected) {
		assertEquals(expected, TimestampPrefix.format(LocalTime.of(h, m, s)));
	}

	@Test
	void prefixHasOpeningBracket() {
		String result = TimestampPrefix.format(LocalTime.of(12, 0, 0));
		assertTrue(result.startsWith("["), "expected leading '[' in: " + result);
	}

	@Test
	void prefixEndsWithBracketSpace() {
		String result = TimestampPrefix.format(LocalTime.of(12, 0, 0));
		assertTrue(result.endsWith("] "), "expected trailing '] ' in: " + result);
	}

	@Test
	void prefixIsAlways11CharactersLong() {
		// "[HH:mm:ss] " = 1 + 2 + 1 + 2 + 1 + 2 + 1 + 1 = 11
		assertEquals(11, TimestampPrefix.format(LocalTime.of(0, 0, 0)).length());
		assertEquals(11, TimestampPrefix.format(LocalTime.of(23, 59, 59)).length());
		assertEquals(11, TimestampPrefix.format(LocalTime.of(9, 9, 9)).length());
	}

	@Test
	void nowReturnsNonNullCurrentFormattedTime() {
		String result = TimestampPrefix.now();
		assertNotNull(result);
		assertEquals(11, result.length());
		assertTrue(result.matches("\\[\\d{2}:\\d{2}:\\d{2}] "),
			"expected [HH:mm:ss] format, got: " + result);
	}
}
