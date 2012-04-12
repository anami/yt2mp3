# yt2mp3

This program is a command line utility to search, download and convert YouTube videos to MP3 audio files.
You need to be specific with what you search for, it will then list six (6) results - from which you select one.
It will then attempt to download and convert the selected video to MP3.

To quit - Enter nothing and press ENTER on the search prompt..

** This is a quick and dirty script **


## Dependencies

Apart from the gems in the Bundler gemfile - yt2mp3 needs ffmpeg installed or close by (in the current directory).
For Mac users - it's up to you how you install this..  Homebrew works for me! :-)

[FFMPEG](http://ffmpeg.org)

[Homebrew](http://mxcl.github.com/homebrew/)

[MacPorts](http://www.macports.org/)


## Usage

    In Linux/Mac environments
    > chmod +x yt2mp3.rb
    > ./yt2mp3.rb

    In Windows environments
    > ruby yt2mp3.rb

## Windows

yt2mp3 can be converted to a standalone executable.  
To do this, you will need the Ocra (One Click Ruby Application) builder gem.

    > gem install ocra
    > ocra yt2mp3.rb
    > .. after a while ..
    > yt2mp3.exe

## Caveats

I have not had the chance to fully test this - I've had instances where the Ruby file doesn't like being in Windows.
It complains about the weird characters in line 217. It is to do with the line ending character.
Try amending that line to make it work..  Sorry!


