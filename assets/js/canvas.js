import { Application, Sprite, Assets } from 'pixi.js';

const canvasHook = {
  app: new Application({background: '#1099bb', antialias: true}),
  mounted() {
    this.el.appendChild(this.app.view);
    this.el.tabIndex = -1
    this.el.focus()

    const canvas_center = {x: this.app.renderer.width / 2, y: this.app.renderer.height / 2}
    let players = {}

    this.handleEvent("update-player-position", (data) => {
      const sprite = players[data.name]

      if(sprite) {
        sprite.x = canvas_center.x + data.x
        sprite.y = canvas_center.y + data.y
      } else {
        const sprite = Sprite.from('https://pixijs.com/assets/bunny.png');
        sprite.x = canvas_center.x + data.x
        sprite.y = canvas_center.y + data.y
        players[data.name] = sprite;
        this.app.stage.addChild(sprite);
      }
    })

    this.handleEvent("delete-player", (data) => {
      const sprite = players[data.name]
      if(sprite) {
        this.app.stage.removeChild(sprite)
        delete players[data.name]
      }
    })
  }
}

export default { Hook: canvasHook }
