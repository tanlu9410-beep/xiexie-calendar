(() => {
  'use strict'
  const { POOL, svg } = window.ClawdPool
  let index = 0
  function select(id) {
    const found = POOL.findIndex(item => item.id === id)
    index = found >= 0 ? found : 0
    const item = POOL[index]
    document.getElementById('pet').innerHTML = svg(item, { anim: true })
    document.title = `蟹蟹桌宠 · ${item.job} · ${item.name}`
    return item.id
  }
  window.pet = {
    select,
    next() { return select(POOL[(index + 1) % POOL.length].id) },
    pause(value) { document.body.classList.toggle('paused', Boolean(value)) },
    list() { return POOL.map(({ id, job, name }) => ({ id, title: `${job} · ${name}` })) },
  }
  select(POOL[0].id)
})()
