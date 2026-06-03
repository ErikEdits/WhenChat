package com.mukse.chattime.mixin;

import net.minecraft.client.gui.hud.ChatHud;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@Mixin(ChatHud.class)
public class ChatHudMixin {

	private static final DateTimeFormatter CHATTIME$FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;Lnet/minecraft/network/message/MessageSignatureData;ILnet/minecraft/client/gui/hud/MessageIndicator;Z)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text chattime$prependTimestamp(Text original) {
		return chattime$wrap(original);
	}

	// Fallback target for builds where the above descriptor doesn't match.
	// Mixin will only apply whichever signature exists in the running MC version.
	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;Lnet/minecraft/network/message/MessageSignatureData;Lnet/minecraft/client/gui/hud/MessageIndicator;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text chattime$prependTimestampLegacy(Text original) {
		return chattime$wrap(original);
	}

	private static Text chattime$wrap(Text original) {
		if (original == null) return null;
		String ts = LocalTime.now().format(CHATTIME$FMT);
		MutableText prefix = Text.literal("[" + ts + "] ").formatted(Formatting.GRAY);
		return prefix.append(original);
	}
}
