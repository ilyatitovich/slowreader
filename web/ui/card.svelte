<script lang="ts">
  import type { Snippet } from 'svelte'

  let { children }: { children: Snippet } = $props()
</script>

<section class="card">
  {@render children()}
</section>

<style>
  :global {
    :root {
      --card-text-fix: -3px;
    }

    .card {
      padding: var(--padding-l) var(--padding-l);
      background-color: var(--card-color);
      border-top: 1px solid var(--top-edge-color);
      border-bottom: 1px solid var(--bottom-edge-color);
      border-radius: var(--radius);
      box-shadow: var(--card-shadow);
    }
  }
</style>
