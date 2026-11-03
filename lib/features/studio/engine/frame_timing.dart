// Browsers play GIF frames shorter than 20 ms at 100 ms, and many GIFs are
// authored with that behaviour in mind.
const Duration minGifFrameDuration = Duration(milliseconds: 20);
const Duration fallbackGifFrameDuration = Duration(milliseconds: 100);

Duration normalizeFrameDuration(Duration duration) =>
    duration < minGifFrameDuration ? fallbackGifFrameDuration : duration;
