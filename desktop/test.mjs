import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { runInNewContext } from 'node:vm'

function renderer() {
  const element = { innerHTML: '' }
  const classes = new Set()
  const context = {
    window: {},
    document: {
      title: '', getElementById: () => element,
      body: { classList: { toggle(key, enabled) { enabled ? classes.add(key) : classes.delete(key) } } },
    },
  }
  runInNewContext(readFileSync(new URL('../clawd-pool.js', import.meta.url), 'utf8'), context)
  runInNewContext(readFileSync(new URL('./pet.js', import.meta.url), 'utf8'), context)
  return { ...context, element, classes }
}

test('each look renders a complete four-frame SVG', () => {
  const { window, element, document } = renderer()
  const list = window.pet.list()
  assert.ok(list.length >= 31, 'retain all upstream looks, including special variants')
  assert.equal(new Set(list.map(item => item.id)).size, list.length)
  for (const item of list) {
    assert.equal(window.pet.select(item.id), item.id)
    assert.match(element.innerHTML, /^<svg /)
    assert.match(element.innerHTML, /<\/svg>$/)
    for (let frame = 0; frame < 4; frame++) assert.ok(element.innerHTML.includes(`class="k${frame}"`))
    assert.ok(document.title.includes(item.title.split(' · ')[0]))
    assert.doesNotMatch(element.innerHTML, /NaN|undefined/)
  }
})

test('click cycling wraps after the final look', () => {
  const { window } = renderer()
  const list = window.pet.list()
  window.pet.select(list.at(-1).id)
  assert.equal(window.pet.next(), list[0].id)
})

test('unknown saved look falls back safely and pausing can resume', () => {
  const { window, classes } = renderer()
  assert.equal(window.pet.select('missing-id'), window.pet.list()[0].id)
  window.pet.pause(true)
  assert.ok(classes.has('paused'))
  window.pet.pause(false)
  assert.ok(!classes.has('paused'))
})

test('renderer blocks network connections and contains no external asset URLs', () => {
  const html = readFileSync(new URL('./pet.html', import.meta.url), 'utf8')
  assert.ok(html.includes("connect-src 'none'"))
  assert.doesNotMatch(html, /(?:src|href)=["']https?:/)
})
