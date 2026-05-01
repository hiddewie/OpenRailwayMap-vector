# OpenHistorical font

This font is a combination of open source fonts, since no single font provided all the glyphs needed for the variety of the world's languages AND ALSO had the smooth look we wanted.

Our goal:
* Open Sans, smooth and clean... but does not support Arabic, Hebrew, and other character sets
* Unifont, provides glyphs for a whole lot of languages including RTL Hebrew and Arabic... but does not have that smooth, clean look
* Combine the glyphs from Unifont into Open Sans to get the best of both where we have it.

## Combining Process

I used Font Lab, though FontForge may also be able to do this.

Open FontLab, use File / Open Fonts and open the font files.
* Unifont
* Open Sans Regular

Go into the Unifont window.
* Use ctrl-A to select all glyphs *but then* de-select the first several which do not have useful glyphs. You'll see them: basically everything before "!".
* Hit ctrl-C to copy these glyphs.

Go into the Open Sans window.
* Use ctrl-V to paste those Unifont glyphs into this Open Sans font.
* You'll receive a warning about conflicting glyphs. Select append & keep unchanged.
* This will take some time.

Edit the Font Info, and set the font name and family to "OpenHistorical"

Export the font with File / Export to TTF.
* This will take some time.
* It may save as the name of the font you used as the base e.g. *Open Sans Regular.ttf* so rename it to *Historical.ttf*

Use fontnik to build the PBF version for use with vector tile maps:

```
npm install fontnik

cd map-styles/fonts
~/node_modules/fontnik/bin/build-glyphs ./OpenHistorical/OpenHistorical.ttf ./OpenHistorical
```

I then repeated the process with Open Sans Bold and Open Sans Italic, creating *OpenHistorical Bold.ttf* and *OpenHistoricalItalic.ttf* and then using fontnik on them.
