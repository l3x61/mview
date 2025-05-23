# mview
A media viewer for Linux under development.

## Dependencies
### Bundled
- [zig-gamedev](https://github.com/zig-gamedev)
    - [system_sdk](https://github.com/zig-gamedev/system_sdk)
    - [zglfw](https://github.com/zig-gamedev/zglfw)
        - [GLFW](https://github.com/glfw/glfw)
    - [zgui](https://github.com/zig-gamedev/zgui)
        - [imgui](https://github.com/ocornut/imgui)
    - [zopengl](https://github.com/zig-gamedev/zopengl)
- [JetBrains Mono Font](https://www.jetbrains.com/lp/mono/)
### External
- [MagickWand 7](https://imagemagick.org/script/magick-wand.php)

## ToDo
- [X] viewer pan & zoom
- [ ] viewer file info
- [ ] viewer fit to screen, fit to width, fit to height, etc
- [ ] viewer controls tooltip
- [ ] config file
- [ ] find a good name
### Maybe
- [ ] viewer rotate
- [ ] add MIME type detector [libmagic](https://github.com/file/file)
- [ ] add CJK font [Noto CJK](https://github.com/notofonts/noto-cjk)
- [ ] bundle MagickWand


---

## Notes
- https://github.com/ImageMagick/MagickCache#readme