import { Application, Sprite, Container, Texture, Rectangle, Graphics, Text, TextStyle } from 'pixi.js'
import { base64ToInt32Array } from './base64.js'

const boardPath = '/board/chunk.tmj'
const texturePath = '/textures/erick-etchebeur-transparent.webp'
const tibiaTexturePath = '/textures/7.4_Spritesheet.png'

// const _gameWindow = { height: 640, width: 800, resolution: 1.5 }
const gameWindow = { height: 11 * 32, width: 15 * 32, resolution: 2 }

const canvasHook = {
  app: new Application({ ...gameWindow, antialias: true }),
  playersContainer: null,
  async mounted () {
    this.el.appendChild(this.app.view)
    this.el.tabIndex = -1
    this.el.focus()

    const texture = await Texture.fromURL(texturePath).then((texture) => { return texture })
    const tibiaTexture = await Texture.fromURL(tibiaTexturePath).then((texture) => { return texture })
    const board = await loadBoard(boardPath)
    const players = {}

    setTimeout(() => { this.pushEvent('canvas-loaded', {}) })

    const boardContainer = createContainer('board')
    this.app.stage.addChild(boardContainer)

    // const stepableContainer = createContainer('stepable')
    // this.app.stage.addChild(stepableContainer)

    const playersContainer = createContainer('players')
    this.app.stage.addChild(playersContainer)
    this.playersContainer = playersContainer

    const treesContainer2 = createContainer('trees2')
    this.app.stage.addChild(treesContainer2)

    const treesContainer = createContainer('trees')
    this.app.stage.addChild(treesContainer)

    // const wallsContainer = createContainer('walls')
    // this.app.stage.addChild(wallsContainer)

    renderLayer(boardContainer, texture, board.layers.find((l) => l.name === 'ground'))
    // renderLayer(stepableContainer, texture, board.layers.find((l) => l.name === 'stepable'))
    renderLayer(treesContainer2, texture, board.layers.find((l) => l.name === 'flore2'))
    renderLayer(treesContainer, texture, board.layers.find((l) => l.name === 'flore'))
    // renderLayer(wallsContainer, texture, board.layers.find((l) => l.name === 'walls'))

    this.handleEvent('update-character', (data) => {
      const sprite = players[data.id]
      //console.log(data.texture, data.orientation)

      if (sprite) {
        sprite.x = data.x
        sprite.y = data.y
        if(data.texture){
          sprite.texture = getTextureFromTibiaTileset(tibiaTexture, data.texture)
        }
      } else {
        const sprite = Sprite.from(getTextureFromTibiaTileset(tibiaTexture, data.texture))
        sprite.eventMode = 'static'
        sprite.cursor = 'pointer'
        sprite.on('pointerdown', () => { this.pushEvent('click-character', { id: data.id }) })
        sprite.x = data.x
        sprite.y = data.y
        console.log(data)
        const graphics = new Graphics()
        graphics.beginFill(0x009E60)
        graphics.drawRect(6, -5, 20, 2)
        graphics.lineStyle({width: 2, color: 'black'})

        const container = new Container()

        const style = new TextStyle({
          fill: 0x009E60,
          fontSize: 7,
          letterSpacing: 0.5,
          lineJoin: 'round',
          strokeThickness: 1.5,
          fontWeight: 'bold',
          align: 'center'

        })
        const text = new Text(data.name, style)
        text.x = -(~~(data.name.length / 2))
        text.y = -17
        container.addChild(graphics)
        container.addChild(text)
        sprite.addChild(container)

        if (data.type === 'player') {
          console.log('player')
          this.app.stage.addChild(sprite)
        } else {
          playersContainer.addChild(sprite)
        }

        players[data.id] = sprite
      }

      if (data.type === 'player') {
        this.app.stage.pivot.x = data.x - 7 * 32
        this.app.stage.pivot.y = data.y - 5 * 32
      }
    })

    this.handleEvent('delete-character', (data) => {
      const sprite = players[data.id]
      if (sprite) {
        playersContainer.removeChild(sprite)
        delete players[data.id]
      }
    })
  },
  reconnected () {
    this.playersContainer.removeChildren()
    setTimeout(() => { this.pushEvent('canvas-loaded', {}) })
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
    const sprite = Sprite.from(texture)
    sprite.x = tileContext.x * 32
    sprite.y = tileContext.y * 32
    container.addChild(sprite)
  }
}

// (texture, integer) => texture
const getTextureFromTileset = (tileset, position) => {
  const texture = tileset.clone()
  texture.frame = calculateTextureFrame(position)
  return texture
}

const getTextureFromTibiaTileset = (tileset, position) => {
  const texture = tileset.clone()
  texture.frame = calculateTibiaTextureFrame(position)
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

const calculateTibiaTextureFrame = (position) => {
  const size = 32
  const width = 83
  const y = Math.floor(position / width)
  const x = position % width
  return new Rectangle(x * size, y * size, size, size)
}

export default { Hook: canvasHook }
