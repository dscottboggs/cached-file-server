# Cached Static File Server
Given a directory, this application reads all file contents into memory and then serves them up over HTTP when requested.

#### Note:
This application reads all the files in the directory into memory, so if you're serving
a lot of large files, it will use a large amount of memory, possibly overflowing the heap.

## Installation
Download the static binary, or install crystal, download the source code, and run `crystal build src/run.cr`

## Usage
Usage advice is offered by the `--help` command-line option.

## Development
Improvements and advice are greatly welcome. Please open a pull request or issue with any way to make this application more effective and fast!

## Contributing

1. Fork it (<https://github.com/dscottboggs/cached_static_server/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [D. Scott Boggs](https://github.com/dscottboggs) - creator and maintainer
