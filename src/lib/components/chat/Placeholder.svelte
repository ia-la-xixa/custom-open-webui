<script lang="ts">
	import { marked } from 'marked';

	import { createEventDispatcher, getContext } from 'svelte';
	import { fade } from 'svelte/transition';

	const dispatch = createEventDispatcher();

	import { getChatList } from '$lib/apis/chats';

	import { WEBUI_API_BASE_URL } from '$lib/constants';
	import {
		models as _models,
		chats,
		config,
		currentChatPage,
		selectedFolder,
		temporaryChatEnabled,
		user
	} from '$lib/stores';
	import { sanitizeResponseContent } from '$lib/utils';

	import Tooltip from '$lib/components/common/Tooltip.svelte';
	import EyeSlash from '$lib/components/icons/EyeSlash.svelte';
	import MessageInput from './MessageInput.svelte';
	import FolderPlaceholder from './Placeholder/FolderPlaceholder.svelte';
	import FolderTitle from './Placeholder/FolderTitle.svelte';
	import Suggestions from './Suggestions.svelte';

	const i18n = getContext('i18n');

	export let createMessagePair: Function;
	export let stopResponse: Function;

	export let autoScroll = false;

	export let atSelectedModel: Model | undefined;
	export let selectedModels: [''];

	export let history;

	export let prompt = '';
	export let files = [];
	export let messageInput = null;

	export let selectedToolIds = [];
	export let selectedFilterIds = [];

	export let showCommands = false;

	export let imageGenerationEnabled = false;
	export let codeInterpreterEnabled = false;
	export let webSearchEnabled = false;

	export let onSelect = (e) => {};
	export let onChange = (e) => {};

	export let toolServers = [];

	let models = [];
	let selectedModelIdx = 0;

	$: models = selectedModels.map((id) => $_models.find((m) => m.id === id)).filter((m) => m);

	$: if (models.length > 0) {
		selectedModelIdx = models.length - 1;
	} else {
		selectedModelIdx = -1;
	}
</script>

<div class="m-auto w-full max-w-6xl px-2 @2xl:px-20 translate-y-6 py-24 text-center">
	{#if $temporaryChatEnabled}
		<Tooltip
			content={$i18n.t("This chat won't appear in history and your messages will not be saved.")}
			className="w-full flex justify-center mb-0.5"
			placement="top"
		>
			<div class="flex items-center gap-2 text-gray-500 text-base my-2 w-fit">
				<EyeSlash strokeWidth="2.5" className="size-4" />{$i18n.t('Temporary Chat')}
			</div>
		</Tooltip>
	{/if}

	<div
		class="w-full text-3xl text-gray-800 dark:text-gray-100 text-center flex items-center gap-4 font-primary"
	>
		<div class="w-full flex flex-col justify-center items-center">
			{#if $selectedFolder}
				<FolderTitle
					folder={$selectedFolder}
					onUpdate={async (folder) => {
						await chats.set(await getChatList(localStorage.token, $currentChatPage));
						currentChatPage.set(1);
					}}
					onDelete={async () => {
						await chats.set(await getChatList(localStorage.token, $currentChatPage));
						currentChatPage.set(1);

						selectedFolder.set(null);
					}}
				/>
			{:else}
				<div class="flex flex-col justify-center items-center w-full">
					<div class="flex justify-center items-center gap-6 mb-3 max-w-2xl" in:fade={{ duration: 100 }}>
						{#each models as model, modelIdx}
							<!-- Logo 1 (Primary) -->
							{#if models[modelIdx]?.info?.meta?.profile_image_url}
								<img
									src={`${WEBUI_API_BASE_URL}/models/model/profile/image?id=${model?.id}&lang=${$i18n.language}`}
									class="h-12 @sm:h-16 w-auto object-contain flex-shrink"
									alt=""
									aria-hidden="true"
									draggable="false"
								/>
							{/if}
							<!-- Logo 2 -->
							{#if models[modelIdx]?.info?.meta?.logo_2_url}
								<img
									src={`${WEBUI_API_BASE_URL}/models/model/profile/logo/2?id=${model?.id}&lang=${$i18n.language}`}
									class="h-12 @sm:h-16 w-auto object-contain flex-shrink"
									alt=""
									aria-hidden="true"
									draggable="false"
								/>
							{/if}
							<!-- Logo 3 -->
							{#if models[modelIdx]?.info?.meta?.logo_3_url}
								<img
									src={`${WEBUI_API_BASE_URL}/models/model/profile/logo/3?id=${model?.id}&lang=${$i18n.language}`}
									class="h-12 @sm:h-16 w-auto object-contain flex-shrink"
									alt=""
									aria-hidden="true"
									draggable="false"
								/>
							{/if}
							<!-- Logo 4 -->
							{#if models[modelIdx]?.info?.meta?.logo_4_url}
								<img
									src={`${WEBUI_API_BASE_URL}/models/model/profile/logo/4?id=${model?.id}&lang=${$i18n.language}`}
									class="h-12 @sm:h-16 w-auto object-contain flex-shrink"
									alt=""
									aria-hidden="true"
									draggable="false"
								/>
							{/if}
						{/each}
					</div>

					<div
						class="text-3xl @sm:text-3xl line-clamp-2 flex items-center justify-center px-5"
						in:fade={{ duration: 100 }}
					>
						{#if models.length > 0 && selectedModelIdx >= 0 && models[selectedModelIdx]?.name}
							<Tooltip
								content={models[selectedModelIdx]?.name}
								placement="top"
								className=" flex items-center "
							>
								<span class="line-clamp-2">
									{models[selectedModelIdx]?.name}
								</span>
							</Tooltip>
						{:else}
							{$i18n.t('Hello, {{name}}', { name: $user?.name })}
						{/if}
					</div>
				</div>

				{#if models.length > 0 && selectedModelIdx >= 0 && models[selectedModelIdx]?.info?.meta?.description}
					<div class="flex mt-3 mb-4">
						<div in:fade={{ duration: 100, delay: 50 }}>
							<div
								class="px-2 text-base font-normal text-gray-600 dark:text-gray-300 max-w-2xl leading-relaxed markdown"
							>
								{@html marked.parse(
									sanitizeResponseContent(
										models[selectedModelIdx]?.info?.meta?.description ?? ''
									).replaceAll('\n', '<br>')
								)}
							</div>
						</div>
					</div>
				{/if}
			{/if}

			<div class="text-base font-normal @md:max-w-3xl w-full py-3 {atSelectedModel ? 'mt-2' : ''}">
				<MessageInput
					bind:this={messageInput}
					{history}
					{selectedModels}
					bind:files
					bind:prompt
					bind:autoScroll
					bind:selectedToolIds
					bind:selectedFilterIds
					bind:imageGenerationEnabled
					bind:codeInterpreterEnabled
					bind:webSearchEnabled
					bind:atSelectedModel
					bind:showCommands
					{toolServers}
					{stopResponse}
					{createMessagePair}
					placeholder={$i18n.t('How can I help you today?')}
					{onChange}
					on:upload={(e) => {
						dispatch('upload', e.detail);
					}}
					on:submit={(e) => {
						dispatch('submit', e.detail);
					}}
				/>
			</div>
		</div>
	</div>

	{#if $selectedFolder}
		<div
			class="mx-auto px-4 md:max-w-3xl md:px-6 font-primary min-h-62"
			in:fade={{ duration: 200, delay: 200 }}
		>
			<FolderPlaceholder folder={$selectedFolder} />
		</div>
	{:else}
		<div class="mx-auto max-w-2xl font-primary mt-2" in:fade={{ duration: 200, delay: 200 }}>
			<div class="mx-5">
				<Suggestions
					suggestionPrompts={atSelectedModel?.info?.meta?.suggestion_prompts ??
						models[selectedModelIdx]?.info?.meta?.suggestion_prompts ??
						$config?.default_prompt_suggestions ??
						[]}
					inputValue={prompt}
					{onSelect}
				/>
			</div>
		</div>
	{/if}
</div>
