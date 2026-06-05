package com.mukse.whenchat.neoforge;

import net.neoforged.api.distmarker.Dist;
import net.neoforged.fml.common.Mod;

/**
 * Mod entrypoint for NeoForge. The actual work is done by the mixin in
 * {@link com.mukse.whenchat.neoforge.mixin.ChatComponentMixin}.
 */
@Mod(value = "whenchat", dist = Dist.CLIENT)
public final class WhenChatNeoForge {
	public WhenChatNeoForge() {
	}
}
