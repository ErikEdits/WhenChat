package com.mukse.whenchat.neoforge.mixin;

import com.mukse.whenchat.neoforge.TimestampPrefix;
import net.minecraft.ChatFormatting;
import net.minecraft.client.gui.components.ChatComponent;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MutableComponent;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyVariable;

import java.util.regex.Pattern;

@Mixin(ChatComponent.class)
public class ChatComponentMixin {

	private static final Pattern WHENCHAT$ALREADY_PREFIXED = Pattern.compile("^\\[\\d{2}:\\d{2}:\\d{2}] .*");

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/network/chat/Component;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Component whenchat$prependTimestampSingleArg(Component original) {
		return whenchat$wrap(original);
	}

	@ModifyVariable(
		method = "addMessage(Lnet/minecraft/network/chat/Component;Lnet/minecraft/network/chat/MessageSignature;Lnet/minecraft/client/GuiMessageTag;)V",
		at = @At("HEAD"),
		argsOnly = true,
		require = 0
	)
	private Component whenchat$prependTimestampThreeArg(Component original) {
		return whenchat$wrap(original);
	}

	private static Component whenchat$wrap(Component original) {
		if (original == null) return null;
		String existing = original.getString();
		if (existing != null && WHENCHAT$ALREADY_PREFIXED.matcher(existing).matches()) {
			return original;
		}
		MutableComponent prefix = Component.literal(TimestampPrefix.now()).withStyle(ChatFormatting.GRAY);
		return prefix.append(original);
	}
}
