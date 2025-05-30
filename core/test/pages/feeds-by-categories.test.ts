import { loadValue } from '@logux/client'
import { deepStrictEqual, equal } from 'node:assert'
import { afterEach, beforeEach, test } from 'node:test'

import {
  addCategory,
  addFeed,
  getFeed,
  testFeed,
  waitLoading
} from '../../index.ts'
import { cleanClientTest, enableClientTest, openPage } from '../utils.ts'

beforeEach(() => {
  enableClientTest()
})

afterEach(async () => {
  await cleanClientTest()
})

test('groups feeds by categories', async () => {
  let page = openPage({
    params: {},
    route: 'feedsByCategories'
  })

  equal(page.loading.get(), true)
  await waitLoading(page.loading)
  deepStrictEqual(page.groups.get(), [])

  let idA = await addCategory({ title: 'A' })
  let feed1 = await addFeed(testFeed({ categoryId: idA, title: '1' }))
  let feed2 = await addFeed(testFeed({ categoryId: idA, title: '2' }))
  deepStrictEqual(page.groups.get(), [
    [
      { id: idA, isLoading: false, title: 'A' },
      [await loadValue(getFeed(feed1)), await loadValue(getFeed(feed2))]
    ]
  ])

  let idC = await addCategory({ title: 'C' })
  let idB = await addCategory({ title: 'B' })
  let feed3 = await addFeed(testFeed({ categoryId: idB, title: '1' }))
  let feed4 = await addFeed(testFeed({ categoryId: 'general', title: '1' }))
  let feed5 = await addFeed(testFeed({ categoryId: 'unknown', title: '1' }))

  deepStrictEqual(page.groups.get(), [
    [{ id: 'general', title: 'General' }, [await loadValue(getFeed(feed4))]],
    [
      { id: idA, isLoading: false, title: 'A' },
      [await loadValue(getFeed(feed1)), await loadValue(getFeed(feed2))]
    ],
    [
      { id: idB, isLoading: false, title: 'B' },
      [await loadValue(getFeed(feed3))]
    ],
    [{ id: idC, isLoading: false, title: 'C' }, []],
    [
      { id: 'broken', title: 'Broken category' },
      [await loadValue(getFeed(feed5))]
    ]
  ])

  openPage({
    params: {},
    route: 'welcome'
  })
})
