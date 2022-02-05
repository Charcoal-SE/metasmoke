# metasmoke

metasmoke is a web dashboard for [SmokeDetector](//github.com/Charcoal-SE/SmokeDetector), a bot that detects spam
on the [Stack Exchange network](//stackexchange.com/sites).

## API
If you're looking to develop using the metasmoke API, there's documentation available
[in the wiki](//github.com/Charcoal-SE/metasmoke/wiki/API-Documentation). You'll need an API key to access any
of the routes; ping a [metasmoke admin](//charcoal-se.org/people#admins) in
[Charcoal HQ](//chat.stackexchange.com/rooms/11540/charcoal-hq).

## WSL
While metasmoke isn't targeted to support WSL (it's just not fast enough for production use), it should work adequately
well for development purposes. The minimum Windows build version required is 16170, due to an
[lack of WSL support for mdns](https://github.com/Microsoft/WSL/issues/2245#issuecomment-310546134) in builds prior
to this.

## Docker
There is a simple `Dockerfile` here which is however not well tested.

If you want to include a database dump, create a directory `import`
and place the dump files there (one `*.rdb.gz` and one `*.sql.gz`).
This will noticeably slow down the build (plan 10-15 minutes,
depending also on disk speed and hardware).

If the `import` directory contains a file named `metasmoke@localhost`,
or if there is no `import` directory, the Docker image will create
a metasmoke user with that email address and a default password.

To create a local build, simply

    docker build -t metasmoke .

To run the image, you need to expose the ports properly.

    docker run --rm -it -p5000:5000 -p8080:8080 metasmoke

Once the image runs the initalizations, you should be able to connect to
http://localhost:5000/ and see metasmoke greet you.

Some of the options in this brief introduction are optional convenience.
If you understand what you are doing, the `-t metasmoke` is not crucial,
and the `--rm -it` options are just one common way of keeping things sane.

## License
Metasmoke is a pretty niche project, and we don't expect many people to make use of the entire thing as a whole.
However, if you want to use the code, go right ahead - metasmoke is licensed under [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/). A small attribution is
appreciated, but entirely non-compulsory.

## Reporting a potential security flaw
If you wish to report a potential security flaw, no matter how minor it may be, and are not certain it's a security flaw, **only** 
send the report to security@charcoal-se.org with your details about the issue you found, how you replicated it, and why you believe 
it is a security flaw.  **DO NOT** disclose specific security flaws, even potential ones, via public insecure mediums such as the 
public issues system or public chat systems.
