![TonePlayer](http://www.limit-point.com/assets/images/TonePlayer.jpg)
# TonePlayer
## Play and save frequency tones

The associated Xcode project implements an iOS and macOS [SwiftUI] app that employs [AVAudioEngine] to play pure audio tones for various waveform types and frequencies by sampling mathematical functions. Frequency tones can be saved to [WAV] files of various durations, using [AVFoundation] to write audio sample buffers. 

<!-- Learn more about plotting audio samples from our [in-depth blog post](https://www.limit-point.com/blog/2023/tone-player). -->

Frequencies are selected smoothly and continuously from a slider, entered directly with keyboard into a text field, or selected from a table of note buttons labelled A0 to B8, in the standard piano keyboard and grouped in octave 0 to octave 8.

Frequencies are in the range 20 Hz to a maximum determined by the current sample rate, that is usually 22050 Hz. Increment frequencies with stepper control increments of 1000.0, 100.0, 10.0, 1.0, 0.1, 0.01, 0.001, or use the `x ½` and `x 2` buttons to halve and double.

Waveform types are:

- Sine
- Square
- Square Fourier
- Triangle
- Triangle Fourier
- Sawtooth
- Sawtooth Fourier

The `Fourier` alternatives are smooth truncated Fourier series approximations to their counterparts with the same prefix, creating tones of a milder type.

[SwiftUI]: https://developer.apple.com/tutorials/swiftui
[WAV]: https://en.wikipedia.org/wiki/WAV
[AVFoundation]: https://developer.apple.com/documentation/avfoundation
[AVAudioEngine]: https://developer.apple.com/documentation/avfaudio/avaudioengine
