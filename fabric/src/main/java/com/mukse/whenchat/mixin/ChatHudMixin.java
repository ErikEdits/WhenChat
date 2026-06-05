package com.mukse.whenchat.mixin;

import com.mukse.whenchat.TimestampPrefix;
import net.minecraft.client.gui.hud.ChatHud;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

import java.util.regex.Pattern;

@Mixin(ChatHud.class)
public class ChatHudMixin {

	/**
	 * Matches any text that already begins with our timestamp marker. Used as
	 * a guard so that when one public addMessage overload delegates to the
	 * other (as 1.21.x does for {@code addMessage(Text)} -> {@code addMessage(Text, ..., ...)}),
	 * we do not double-prepend the timestamp.
	 */
	private static final Pattern WHENCHAT$ALREADY_PREFIXED = Pattern.compile("^\\[\\d{2}:\\d{2}:\\d{2}] .*");

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text whenchat$prependTimestampSingleArg(Text original) {
		return whenchat$wrap(original);
	}

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;Lnet/minecraft/network/message/MessageSignatureData;Lnet/minecraft/client/gui/hud/MessageIndicator;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text whenchat$prependTimestampThreeArg(Text original) {
		return whenchat$wrap(original);
	}

	private static Text whenchat$wrap(Text original) {
		if (original == null) return null;
		String existing = original.getString();
		if (existing != null && WHENCHAT$ALREADY_PREFIXED.matcher(existing).matches()) {
			return original;
		}
		MutableText prefix = Text.literal(TimestampPrefix.now()).formatted(Formatting.GRAY);
		return prefix.append(original);
	}
}
