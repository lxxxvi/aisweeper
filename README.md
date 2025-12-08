# AI sweeper

[Minesweeper](https://en.wikipedia.org/wiki/Minesweeper_(video_game)) implementation written in [Crystal lang](https://crystal-lang.org/) using [Kemal](https://kemalcr.com/).

It's not supposed to be clean or perfect, it's my playground to learn Crystal and its features.

## Development

```sh
scripts/dev
```

Then open up http://localhost:3000/ in a browser.

## Tests

```sh
scripts/test
```

### Production

```sh
scripts/build

KEMAL_ENV=production ./bin/aisweeper
```
