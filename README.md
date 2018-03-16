# metasmoke

Metasmoke is a web dashboard for [SmokeDetector](//github.com/Charcoal-SE/SmokeDetector), a bot that detects spam on the [Stack Exchange network](//stackexchange.com/sites).

### API
If you're looking to develop using the metasmoke API, there's documentation available [in the wiki](//github.com/Charcoal-SE/metasmoke/wiki/API-Documentation). You'll need an API key to access any of the routes; ping a [metasmoke admin](//charcoal-se.org/people#admins) in [Charcoal HQ](//chat.stackexchange.com/rooms/11540/charcoal-hq).

### Docker
There is a simple `Dockerfile` here which is however not properly tested yet.

To create a local build, simply

    docker build -t metasmoke .

To run the image, you need to expose the ports properly.

    docker run --rm -it -p5000:5000 -p8080:8080 metasmoke

Once the image runs the initalizations, you should be able to connect to
http://localhost:5000/ and see Metasmoke greet you.

Some of the options in this brief introduction are optional convenience.
If you understand what you are doing, the `-t metasmoke` is not crucial,
and the `--rm -it` options are just one common way of keeping things sane.

### License
Metasmoke is a pretty niche project, and we don't expect many people to make use of the entire thing as a whole. However, if you want to use the code, go right ahead - metasmoke is licensed under CC0. A small attribution is appreciated, but entirely non-compulsory.

### Reference

 - [Code coverage](https://circleci.com/api/v1/project/Charcoal-SE/metasmoke/latest/artifacts/0/home/ubuntu/metasmoke/coverage/index.html)
