// types.h
#pragma once

#include <SDL3/SDL.h>
#include <stdio.h>

typedef struct {
  SDL_Window* window;
  SDL_Renderer* renderer;
} RenderContext;

typedef struct {
  SDL_Window* window;
  SDL_Renderer* renderer;

  RenderContext* rc;
} AppState;
