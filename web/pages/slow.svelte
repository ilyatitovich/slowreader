<script lang="ts">
  import {
    openedSlowPost,
    slowPage,
    slowPosts,
    slowMessages as t,
    totalSlowPages,
    totalSlowPosts
  } from '@slowreader/core'

  import { getURL } from '../stores/router.ts'
  import Loader from '../ui/loader.svelte'
  import PaginationBar from '../ui/pagination-bar.svelte'
  import PostCard from '../ui/post-card.svelte'
  import TwoStepsPage from '../ui/two-steps-page.svelte'
</script>

<TwoStepsPage title={$t.pageTitle}>
  {#snippet one()}
    {#if $slowPosts.isLoading}
      <Loader />
    {:else if $slowPosts.list.length === 0}
      {$t.noPosts}
    {:else}
      <ul role="list">
        {#each $slowPosts.list as post (post.id)}
          <li class="slow_post">
            <PostCard
              open={getURL({
                params: {
                  feed: post.feedId,
                  page: $slowPage,
                  post: post.id
                },
                route: 'slow'
              })}
              {post}
            />
          </li>
        {/each}
      </ul>
      {#if $slowPosts.isLoading}
        <Loader />
      {/if}
      {#if $totalSlowPages > 1}
        <PaginationBar
          currentPage={$slowPage}
          label={`${$totalSlowPosts} ${$t.posts}`}
          totalPages={$totalSlowPages}
        />
      {/if}
    {/if}
  {/snippet}
  {#snippet two()}
    {#if $openedSlowPost}
      {#if $openedSlowPost.isLoading}
        <Loader />
      {:else}
        <PostCard full post={$openedSlowPost} />
      {/if}
    {/if}
  {/snippet}
</TwoStepsPage>

<style>
  :global {
    .slow_post {
      margin-top: var(--padding-l);
    }
  }
</style>
