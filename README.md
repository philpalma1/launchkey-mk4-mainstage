#  MainStage MIDI controller mapping for the Novation Launchkey MK4

This is a WIP adapted from mkuron's MK3 config using Claude. This currently supports the 61 key version.

## Installation

Just put the contents of this repository into _~/Music/Audio Music Apps/MainStage Devices_, connect your Launchkey MK4 via USB, and launch MainStage.

## Development

MainStage logs some Lua output to Console.app after running `defaults write com.apple.mainstage3 LUA_DEBUG -bool true`. Don't forget to set it to `false` again afterwards so it doesn't unnecessarily slow down your live performance. MainStage also has a mildly interesting debug menu (`defaults write com.apple.mainstage3 debugMenu -bool true`).

## Disclaimer

This is not officially supported by Apple or Novation. Use at your own risk.
