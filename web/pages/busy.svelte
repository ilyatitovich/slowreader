<script lang="ts">
  import { commonMessages as t } from '@slowreader/core'
</script>

<div class="busy">{$t.loading}</div>

<style>
  :global {
    .busy {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }
  }
</style>
