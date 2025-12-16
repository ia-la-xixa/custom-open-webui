<script lang="ts">
	import { toast } from 'svelte-sonner';
	import { onMount, getContext, createEventDispatcher } from 'svelte';
	import TurndownService from 'turndown';
	import { gfm } from '@joplin/turndown-plugin-gfm';
	const i18n = getContext('i18n');
	const dispatch = createEventDispatcher();

	import {
		artifactCode,
		chatId,
		settings,
		showArtifacts,
		showControls,
		artifactContents
	} from '$lib/stores';
	import { copyToClipboard, createMessagesList } from '$lib/utils';

	import XMark from '../icons/XMark.svelte';
	import ArrowsPointingOut from '../icons/ArrowsPointingOut.svelte';
	import Tooltip from '../common/Tooltip.svelte';
	import SvgPanZoom from '../common/SVGPanZoom.svelte';
	import ArrowLeft from '../icons/ArrowLeft.svelte';
	import Download from '../icons/Download.svelte';

	export let overlay = false;

	let contents: Array<{ type: string; content: string }> = [];
	let selectedContentIdx = 0;

	let copied = false;
	let iframeElement: HTMLIFrameElement;
	let showDownloadMenu = false;

	function navigateContent(direction: 'prev' | 'next') {
		selectedContentIdx =
			direction === 'prev'
				? Math.max(selectedContentIdx - 1, 0)
				: Math.min(selectedContentIdx + 1, contents.length - 1);
	}

	const iframeLoadHandler = () => {
		iframeElement.contentWindow.addEventListener(
			'click',
			function (e) {
				const target = e.target.closest('a');
				if (target && target.href) {
					e.preventDefault();
					const url = new URL(target.href, iframeElement.baseURI);
					if (url.origin === window.location.origin) {
						iframeElement.contentWindow.history.pushState(
							null,
							'',
							url.pathname + url.search + url.hash
						);
					} else {
						console.info('External navigation blocked:', url.href);
					}
				}
			},
			true
		);

		// Cancel drag when hovering over iframe
		iframeElement.contentWindow.addEventListener('mouseenter', function (e) {
			e.preventDefault();
			iframeElement.contentWindow.addEventListener('dragstart', (event) => {
				event.preventDefault();
			});
		});
	};

	const showFullScreen = () => {
		if (iframeElement.requestFullscreen) {
			iframeElement.requestFullscreen();
		} else if (iframeElement.webkitRequestFullscreen) {
			iframeElement.webkitRequestFullscreen();
		} else if (iframeElement.msRequestFullscreen) {
			iframeElement.msRequestFullscreen();
		}
	};

	const convertHtmlToMarkdown = (html: string): string => {
		const turndownService = new TurndownService({
			headingStyle: 'atx',
			bulletListMarker: '-'
		});
		turndownService.use(gfm);

		// Ignorar tags de estilo y script
		turndownService.remove(['style', 'script', 'head']);

		// Regla: section-title → ## Encabezado
		turndownService.addRule('sectionTitle', {
			filter: (node) => node.classList?.contains('section-title'),
			replacement: (content, node) => {
				const titleSpan = (node as HTMLElement).querySelector('span:first-child');
				const title = titleSpan ? titleSpan.textContent?.trim() : content.trim();
				return `\n\n## ${title}\n\n`;
			}
		});

		// Regla: info-label → **Label:**
		turndownService.addRule('infoLabel', {
			filter: (node) => node.classList?.contains('info-label'),
			replacement: (content) => `**${content.trim()}:** `
		});

		// Regla: og-box → blockquote
		turndownService.addRule('ogBox', {
			filter: (node) => node.classList?.contains('og-box'),
			replacement: (content) => `\n> ${content.trim()}\n\n`
		});

		// Regla: ctx-row → párrafo con salto de línea
		turndownService.addRule('ctxRow', {
			filter: (node) => node.classList?.contains('ctx-row'),
			replacement: (content) => `\n${content.trim()}\n`
		});

		// Regla: badge → ignorar
		turndownService.addRule('badge', {
			filter: (node) => node.classList?.contains('badge'),
			replacement: () => ''
		});

		// Regla: oe-num → negrita
		turndownService.addRule('oeNum', {
			filter: (node) => node.classList?.contains('oe-num'),
			replacement: (content) => `**${content.trim()}** `
		});

		// Regla: op-oe-title → ### subtítulo
		turndownService.addRule('opOeTitle', {
			filter: (node) => node.classList?.contains('op-oe-title'),
			replacement: (content) => `\n### ${content.trim()}\n`
		});

		// Regla: empty-msg → itálica
		turndownService.addRule('emptyMsg', {
			filter: (node) => node.classList?.contains('empty-msg'),
			replacement: (content) => `*${content.trim()}*`
		});

		let markdown = turndownService.turndown(html);
		// Post-procesamiento: limpiar negritas escapadas
		markdown = markdown.replace(/\\\*\\\*/g, '**');
		markdown = markdown.replace(/\\\*/g, '*');
		return markdown;
	};

	const downloadAsMarkdown = (extension: '.md' | '.txt') => {
		const html = contents[selectedContentIdx].content;
		const markdown = convertHtmlToMarkdown(html);
		const mimeType = extension === '.md' ? 'text/markdown' : 'text/plain';
		const blob = new Blob([markdown], { type: mimeType });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `artifact-${$chatId}-${selectedContentIdx}${extension}`;
		document.body.appendChild(a);
		a.click();
		document.body.removeChild(a);
		URL.revokeObjectURL(url);
		showDownloadMenu = false;
	};

	onMount(() => {
		artifactCode.subscribe((value) => {
			if (contents) {
				const codeIdx = contents.findIndex((content) => content.content.includes(value));
				selectedContentIdx = codeIdx !== -1 ? codeIdx : 0;
			}
		});

		artifactContents.subscribe((value) => {
			contents = value;
			console.log('Artifact contents updated:', contents);

			if (contents.length === 0) {
				showControls.set(false);
				showArtifacts.set(false);
			}

			selectedContentIdx = contents ? contents.length - 1 : 0;
		});
	});
</script>

<div
	class=" w-full h-full relative flex flex-col bg-white dark:bg-gray-850"
	id="artifacts-container"
>
	<div class="w-full h-full flex flex-col flex-1 relative">
		{#if contents.length > 0}
			<div
				class="pointer-events-auto z-20 flex justify-end items-center p-2.5 font-primar text-gray-900 dark:text-white"
			>
				<div class="relative">
					<Tooltip content={$i18n.t('Download')}>
						<button
							class="bg-none border-none text-xs bg-gray-50 hover:bg-gray-100 dark:bg-gray-850 dark:hover:bg-gray-800 transition rounded-md p-1.5 flex items-center gap-1"
							on:click={() => (showDownloadMenu = !showDownloadMenu)}
						>
							<Download className="size-4" />
							<svg
								xmlns="http://www.w3.org/2000/svg"
								fill="none"
								viewBox="0 0 24 24"
								stroke="currentColor"
								stroke-width="2"
								class="size-3"
							>
								<path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
							</svg>
						</button>
					</Tooltip>

					{#if showDownloadMenu}
						<!-- svelte-ignore a11y_click_events_have_key_events -->
						<!-- svelte-ignore a11y_no_static_element_interactions -->
						<div
							class="absolute right-0 top-full mt-1 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-md shadow-lg z-50 min-w-[120px]"
							on:mouseleave={() => (showDownloadMenu = false)}
						>
							<button
								class="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 rounded-t-md transition"
								on:click={() => downloadAsMarkdown('.md')}
							>
								{$i18n.t('Markdown')} (.md)
							</button>
							<button
								class="w-full text-left px-3 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 rounded-b-md transition"
								on:click={() => downloadAsMarkdown('.txt')}
							>
								{$i18n.t('Text')} (.txt)
							</button>
						</div>
					{/if}
				</div>
			</div>
		{/if}

		{#if overlay}
			<div class=" absolute top-0 left-0 right-0 bottom-0 z-10"></div>
		{/if}

		<div class="flex-1 w-full h-full">
			<div class=" h-full flex flex-col">
				{#if contents.length > 0}
					<div class="max-w-full w-full h-full">
						{#if contents[selectedContentIdx].type === 'iframe'}
							<iframe
								bind:this={iframeElement}
								title="Content"
								srcdoc={contents[selectedContentIdx].content}
								class="w-full border-0 h-full rounded-none"
								sandbox="allow-scripts allow-downloads{($settings?.iframeSandboxAllowForms ?? false)
									? ' allow-forms'
									: ''}{($settings?.iframeSandboxAllowSameOrigin ?? false)
									? ' allow-same-origin'
									: ''}"
								on:load={iframeLoadHandler}
							></iframe>
						{:else if contents[selectedContentIdx].type === 'svg'}
							<SvgPanZoom
								className=" w-full h-full max-h-full overflow-hidden"
								svg={contents[selectedContentIdx].content}
							/>
						{/if}
					</div>
				{:else}
					<div class="m-auto font-medium text-xs text-gray-900 dark:text-white">
						{$i18n.t('No HTML, CSS, or JavaScript content found.')}
					</div>
				{/if}
			</div>
		</div>
	</div>
</div>
