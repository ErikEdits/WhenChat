package com.mukse.whenchat.mixin;

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

	private static final DateTimeFormatter WHENCHAT$FMT = DateTimeFormatter.ofPattern("HH:mm:ss");

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;Lnet/minecraft/network/message/MessageSignatureData;ILnet/minecraft/client/gui/hud/MessageIndicator;Z)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text whenchat$prependTimestamp(Text original) {
		return whenchat$wrap(original);
	}

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/text/Text;Lnet/minecraft/network/message/MessageSignatureData;Lnet/minecraft/client/gui/hud/MessageIndicator;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Text whenchat$prependTimestampLegacy(Text original) {
		return whenchat$wrap(original);
	}

	private static Text whenchat$wrap(Text original) {
		if (original == null) return null;
		String ts = LocalTime.now().format(WHENCHAT$FMT);
		MutableText prefix = Text.literal("[" + ts + "] ").formatted(Formatting.GRAY);
		return prefix.append(original);
	}
}
