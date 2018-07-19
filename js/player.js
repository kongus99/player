class Player {
  constructor(domId, clipId, watcher) {
    this.domId = domId;
    this.clipId = clipId;
    this.watcher = watcher;
    this.current = new YT.Player(this.domId, {
      height: '1',
      width: '1',
      videoId: this.clipId,
      events: {
        'onReady': (event) => {
          event.target.playVideo();
        },
        'onStateChange': this.watcher(this)
      }
    });
  }

  play(clipId) {
    if (clipId) {
      if (clipId === this.clipId) {
        this.toggle();
      } else {
        this.clipId = clipId;
        this.stop();
        this.current.loadVideoById(clipId, 0, "large");
      }
    } else this.pause();

  }
  stop() {
    this.current.stopVideo();
  }
  toggle() {
    if (this.current.getPlayerState() === 1)
      this.current.pauseVideo();
    else this.current.playVideo();
  }
  pause() {
    this.current.pauseVideo();
  }
  destroy() {
    this.current.destroy();
  }
  subscribe(app) {
    let subscriber = (that) => (message) => {
      that.play(message);
    };
    app.ports.elmToPlayer.subscribe(subscriber(this));
  }
}


