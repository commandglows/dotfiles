import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, type TUI } from "@earendil-works/pi-tui";

const k = (n: number) => `${Math.round(n / 1000)}k`;

function usage(ctx: ExtensionContext) {
	const u = ctx.getContextUsage();
	const max = u?.contextWindow ?? ctx.model?.contextWindow;
	return u && max ? `${k(u.tokens)}/${k(max)}` : "?/??k";
}

export default function (pi: ExtensionAPI) {
	let tui: TUI | undefined;
	const render = () => tui?.requestRender();

	pi.on("message_end", render);
	pi.on("model_select", render);
	pi.on("thinking_level_select", render);
	pi.on("session_shutdown", () => (tui = undefined));

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((t, theme) => {
			tui = t;
			return {
				invalidate() {},
				render(width: number): string[] {
					const left = `${ctx.model?.id ?? "no-model"} × ${pi.getThinkingLevel()}`;
					const right = usage(ctx);
					const gap = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
					return [truncateToWidth(theme.fg("dim", left + gap + right), width, "")];
				},
			};
		});
	});
}
