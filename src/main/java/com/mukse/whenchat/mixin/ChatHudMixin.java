package com.mukse.whenchat.mixin;

import com.mukse.whenchat.TimestampPrefix;
import net.minecraft.client.gui.hud.ChatHud;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

@Mixin(ChatHud.class)
public class ChatHudMixin {

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
		MutableText prefix = Text.literal(TimestampPrefix.now()).formatted(Formatting.GRAY);
		return prefix.append(original);
	}
}
