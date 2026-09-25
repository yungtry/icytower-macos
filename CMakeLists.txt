cmake_minimum_required(VERSION 3.20)
project(IcyTower LANGUAGES C OBJC)

set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
set(CMAKE_C_STANDARD 99)

include_directories(
    macos/include
    src
)

set(GAME_SOURCES
    src/background.c
    src/character.c
    src/config.c
    src/controls.c
    src/credits.c
    src/events.c
    src/exit.c
    src/eye_candy.c
    src/flatpak.c
    src/floor.c
    src/fonts.c
    src/fullscreen.c
    src/game.c
    src/gameover.c
    src/gameplay.c
    src/gfx.c
    src/hashmap.c
    src/instructions.c
    src/keyboard.c
    src/keymap.c
    src/level.c
    src/menu.c
    src/music.c
    src/music_volume.c
    src/random.c
    src/rebind.c
    src/reward.c
    src/resources.c
    src/scene.c
    src/screenshake.c
    src/sfx.c
    src/shared_state.c
    src/sound.c
    src/sound_volume.c
    src/stars.c
    src/synchronization.c
    src/triple_buffer.c
    src/unlock.c
)

set(MACOS_SOURCES
    macos/src/main.m
    macos/src/AppDelegate.m
    macos/src/ITGameView.m
    macos/src/ITMetalRenderer.m
    macos/src/ITAudioEngine.m
    macos/src/it_allegro_shim.m
    macos/src/Shaders.metal
)

add_executable(IcyTower MACOSX_BUNDLE
    ${GAME_SOURCES}
    ${MACOS_SOURCES}
)

set_target_properties(IcyTower PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/macos/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "Icy Tower"
    MACOSX_BUNDLE_GUI_IDENTIFIER "io.github.royeldar.icytower"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.3.1"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.3.1"
)

find_library(METAL_LIB Metal REQUIRED)
find_library(METALTKIT_LIB MetalKit REQUIRED)
find_library(COCOA_LIB Cocoa REQUIRED)
find_library(AVFOUNDATION_LIB AVFoundation REQUIRED)

target_link_libraries(IcyTower PRIVATE
    ${METAL_LIB}
    ${METALTKIT_LIB}
    ${COCOA_LIB}
    ${AVFOUNDATION_LIB}
    m
)

add_custom_command(TARGET IcyTower POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/src/misc/gfx"
        "$<TARGET_BUNDLE_CONTENT_DIR:IcyTower>/Resources/gfx"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/src/misc/sfx"
        "$<TARGET_BUNDLE_CONTENT_DIR:IcyTower>/Resources/sfx"
    COMMENT "Copying game assets to application bundle Resources"
)
