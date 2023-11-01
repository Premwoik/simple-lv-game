import { Application, Sprite, Container, Texture, Rectangle } from 'pixi.js'
import { base64ToInt32Array } from './base64.js'

const boardPath = '/board/chunk.tmj'
const texturePath = '/textures/erick-etchebeur-transparent.webp'

const canvasHook = {
  app: new Application({ background: '#1099bb', antialias: true }),
  async mounted () {
    this.el.appendChild(this.app.view)
    this.el.tabIndex = -1
    this.el.focus()

    const texture = await Texture.fromURL(texturePath).then((texture) => { return texture })
    const board = await loadBoard(boardPath)
    const players = {}

    const boardContainer = createContainer('board')
    this.app.stage.addChild(boardContainer)

    const stepableContainer = createContainer('stepable')
    this.app.stage.addChild(stepableContainer)

    const playersContainer = createContainer('players')
    this.app.stage.addChild(playersContainer)

    const treesContainer2 = createContainer('trees2')
    this.app.stage.addChild(treesContainer2)

    const treesContainer = createContainer('trees')
    this.app.stage.addChild(treesContainer)

    const wallsContainer = createContainer('walls')
    this.app.stage.addChild(wallsContainer)

    renderLayer(boardContainer, texture, board.layers.find((l) => l.name === 'ground'))
    renderLayer(stepableContainer, texture, board.layers.find((l) => l.name === 'stepable'))
    renderLayer(treesContainer2, texture, board.layers.find((l) => l.name === 'flore2'))
    renderLayer(treesContainer, texture, board.layers.find((l) => l.name === 'flore'))
    renderLayer(wallsContainer, texture, board.layers.find((l) => l.name === 'walls'))

    this.handleEvent('update-player-position', (data) => {
      const sprite = players[data.name]

      if (sprite) {
        sprite.x = data.x
        sprite.y = data.y
      } else {
        const texture = 'https://pixijs.com/assets/bunny.png'
        players[data.name] = drawSprite(playersContainer, texture, data)
      }
    })

    this.handleEvent('delete-player', (data) => {
      const sprite = players[data.name]
      if (sprite) {
        playersContainer.removeChild(sprite)
        delete players[data.name]
      }
    })
  }
}

const loadBoard = (pathStr) => {
  return fetch(pathStr).then((response) => { return response.json() })
}

const createContainer = (name) => {
  const container = new Container()
  container.name = name
  return container
}

const renderLayer = (container, tileset, layer) => {
  const boardInt32Array = base64ToInt32Array(layer.data)
  let index = 0
  for (let y = 0; y < 20; y++) {
    for (let x = 0; x < 25; x++) {
      const textureIndex = boardInt32Array[index]
      drawTile(container, tileset, textureIndex, { x, y })
      index++
    }
  }
}

// (container, tileset, integer, context) => void
const drawTile = (container, tileset, textureIndex, tileContext) => {
  if (textureIndex > 0) {
    const texture = getTextureFromTileset(tileset, textureIndex)
    drawSprite(container, texture, tileContext)
  }
}

// (container, texture, context) => sprite
const drawSprite = (container, texture, { x, y }) => {
  const sprite = Sprite.from(texture)
  sprite.x = x * 32
  sprite.y = y * 32
  container.addChild(sprite)
  return sprite
}

// (texture, integer) => texture
const getTextureFromTileset = (tileset, position) => {
  const texture = tileset.clone()
  texture.frame = calculateTextureFrame(position)
  return texture
}

// (integer) => shape
const calculateTextureFrame = (position) => {
  const size = 32
  const width = 14
  const y = Math.floor(position / width)
  const x = position % width - 1
  return new Rectangle(x * size, y * size, size, size)
}

export default { Hook: canvasHook }
