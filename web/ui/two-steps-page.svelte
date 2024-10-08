<script lang="ts">
  import { mdiClose } from '@mdi/js'
  import { backRoute, backToFirstStep } from '@slowreader/core'
  import { onMount, type Snippet } from 'svelte'

  import { getURL } from '../stores/router.ts'
  import Button from './button.svelte'

  let { one, title, two }: { one: Snippet; title: string; two: Snippet } =
    $props()

  let prevTitle = document.title

  let first: HTMLDivElement
  let second: HTMLDivElement

  export function scrollFirstToTop(): void {
    first.scrollTo({
      behavior: 'smooth',
      top: 0
    })
  }

  export function scrollSecondToTop(): void {
    second.scrollTo({
      behavior: 'smooth',
      top: 0
    })
  }

  function handleEscapeKey(event: KeyboardEvent): void {
    if (backRoute.get() && event.key === 'Escape') {
      let { role, tagName } = document.activeElement!
      if (role === 'menuitem' || tagName === 'BODY') {
        event.stopPropagation()
      }
      backToFirstStep()
    }
  }

  onMount(() => {
    document.title = title + ' › ' + prevTitle
    window.addEventListener('keydown', handleEscapeKey, true)
    return () => {
      document.title = prevTitle
      window.removeEventListener('keydown', handleEscapeKey, true)
    }
  })
</script>

<main id="page" class="two-steps-page">
  <div
    bind:this={first}
    class={`two-steps-page_step ${$backRoute ? 'is-hidden' : ''}`}
  >
    {@render one()}
  </div>
  <div
    bind:this={second}
    class={`two-steps-page_step ${!$backRoute ? 'is-hidden' : ''}`}
  >
    {#if $backRoute}
      <aside class="two-steps-page_close-button">
        <Button hiddenLabel="Close" href={getURL($backRoute)} icon={mdiClose} />
      </aside>
    {/if}
    {@render two()}
  </div>
</main>

<style>
  :global {
    .two-steps-page {
      box-sizing: border-box;
      display: flex;
      gap: var(--padding-l);
      justify-content: space-around;
      width: calc(100% - var(--padding-l));

      @media (width <= 1024px) {
        margin: 0 auto;
      }
    }

    .two-steps-page_step {
      box-sizing: border-box;
      width: 50%;
      max-width: 600px;
      height: 100vh;
      padding: var(--padding-m) var(--padding-l);
      overflow-x: auto;

      @media (width <= 1024px) {
        width: 100%;
        padding-bottom: var(--navbar-height);
      }

      &.is-hidden {
        @media (width <= 1024px) {
          display: none;
        }
      }
    }

    .two-steps-page_close-button {
      display: flex;
      justify-content: flex-end;
      padding-bottom: var(--padding-m);

      @media (width <= 1024px) {
        display: none;
      }
    }
  }
</style>
