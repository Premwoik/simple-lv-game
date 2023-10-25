import { Application, Sprite, Container, Texture, Rectangle } from 'pixi.js'

const boardPath = '/board/chunk.tmj'
const texturePath = '/textures/erick-etchebeur-transparent.webp'

const canvasHook = {
  app: new Application({ background: '#1099bb', antialias: true }),
  async mounted () {
    this.el.appendChild(this.app.view)
    this.el.tabIndex = -1
    this.el.focus()

    const texture = await Texture.fromURL(texturePath).then((texture) => { return texture })

    const canvasCenter = { x: this.app.renderer.width / 2, y: this.app.renderer.height / 2 }
    const board = await loadBoard(boardPath)
    const players = {}

    const boardContainer = createContainer('board')
    this.app.stage.addChild(boardContainer)

    const playersContainer = createContainer('players')
    this.app.stage.addChild(playersContainer)

    const treesContainer = createContainer('trees')
    this.app.stage.addChild(treesContainer)

    renderBoard(boardContainer, texture, board.layers[0])
    renderBoard(treesContainer, texture, board.layers[1])

    this.handleEvent('update-player-position', (data) => {
      const sprite = players[data.name]

      if (sprite) {
        sprite.x = canvasCenter.x + data.x
        sprite.y = canvasCenter.y + data.y
      } else {
        const sprite = Sprite.from('https://pixijs.com/assets/bunny.png')
        sprite.x = canvasCenter.x + data.x
        sprite.y = canvasCenter.y + data.y
        players[data.name] = sprite
        playersContainer.addChild(sprite)
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

const renderBoard = (container, texture, layer) => {
  const decodedBinaryString = atob(layer.data)
  const byteArray = new Uint8Array(decodedBinaryString.length)

  for (let i = 0; i < decodedBinaryString.length; i++) {
    byteArray[i] = decodedBinaryString.charCodeAt(i)
  }

  // 2. Convert the bytes into Int32 values
  const int32Array = new Int32Array(byteArray.buffer)
  let index = 0
  for (let y = 0; y < 20; y++) {
    for (let x = 0; x < 25; x++) {
      const position = int32Array[index]
      if (position > 0) {
        const cordX = x * 32
        const cordY = y * 32
        const ntexture = texture.clone()
        ntexture.frame = textureFrame(position)

        const sprite = Sprite.from(ntexture)
        sprite.x = cordX
        sprite.y = cordY
        container.addChild(sprite)
      }
      index++
    }
  }
}

const textureFrame = (position) => {
  const size = 32
  const width = 14
  const y = Math.floor(position / width)
  const x = position % width - 1
  console.log(y, x)
  return new Rectangle(x * size, y * size, size, size)
}

export default { Hook: canvasHook }
