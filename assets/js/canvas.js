import { Application, Sprite, Assets } from 'pixi.js';

const canvasHook = {
  app: new Application(),
  mounted() {
    this.el.appendChild(this.app.view);
    this.el.tabIndex = -1
    this.el.focus()

    const bunny = Sprite.from('https://pixijs.com/assets/bunny.png');

    let players = {}

    const canvas_center = {x: this.app.renderer.width / 2, y: this.app.renderer.height / 2}

    // Setup the position of the bunny
    bunny.x = canvas_center.x;
    bunny.y = canvas_center.y;

    // Add the bunny to the scene we are building
    this.app.stage.addChild(bunny);

    // This creates a texture from a 'bunny.png' image
    this.handleEvent("player-position", (data) => {
      bunny.x = canvas_center.x + data.x
      bunny.y = canvas_center.y + data.y
    })

    this.handleEvent("close-players-position", (data) => {
      if(Object.hasOwn(players, data.name)) {
        const sprite = players[data.name]
        sprite.x = canvas_center.x + data.x
        sprite.y = canvas_center.y + data.y
      } else {
        const sprite = Sprite.from('https://pixijs.com/assets/bunny.png');
        sprite.x = canvas_center.x;
        sprite.y = canvas_center.y;
        players[data.name] = sprite;
        this.app.stage.addChild(sprite);
      }
    })
  }
}

export default { Hook: canvasHook }
