import { Application, Sprite, Assets } from 'pixi.js';

const canvasHook = {
  app: new Application(),
  mounted() {
    this.el.appendChild(this.app.view);
    this.el.tabIndex = -1
    this.el.focus()

    const bunny = Sprite.from('https://pixijs.com/assets/bunny.png');

    // Setup the position of the bunny
    bunny.x = this.app.renderer.width / 2;
    bunny.y = this.app.renderer.height / 2;

    // Rotate around the center
    bunny.anchor.x = 0.5;
    bunny.anchor.y = 0.5;

    // Add the bunny to the scene we are building
    this.app.stage.addChild(bunny);



    // This creates a texture from a 'bunny.png' image
    this.handleEvent("move-up", (event) => {
      bunny.y -= 10;
    })
    this.handleEvent("move-down", (event) => {
      bunny.y += 10;
    })
    this.handleEvent("move-left", (event) => {
      bunny.x -= 10;
    })
    this.handleEvent("move-right", (event) => {
      bunny.x += 10;
    })
  }
}

export default { Hook: canvasHook }
