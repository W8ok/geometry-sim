// main.c
#define SDL_MAIN_USE_CALLBACKS 1  // Use the callbacks instead of main()
#include <SDL3/SDL_main.h>

#include "types.h"
#include "rustcore.h"
#include "render.c"

SDL_AppResult Panic(const char* msg)
{
  const char* error = SDL_GetError();

  // If theres an error message, then print it
  if (error && error[0] != '\0')
    printf("Panic! %s: \t%s\n", msg, error);

  else
    printf("Panic! %s: \t(No Error Message)\n", msg);

  return SDL_APP_FAILURE;
}

SDL_AppResult SDL_AppIterate(void *appstate)
{
  AppState *app = (AppState *)appstate;

  main_render(app->rc);

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event)
{
  //AppState *app = (AppState *)appstate;
  (void)appstate;

  if (event->type == SDL_EVENT_QUIT)
    return SDL_APP_SUCCESS;

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv)
{
  (void)argc;
  (void)argv;
  
  AppState *app = (AppState *)SDL_calloc(1, sizeof(AppState));
  *appstate = app;

  if (!app)
    return Panic("AppState memory allocation failed");

  // SDL stuff
  if(!SDL_Init(SDL_INIT_VIDEO))
    return Panic("SDL_Init failed");

  // Get screen size
  SDL_DisplayID display = SDL_GetPrimaryDisplay();
  SDL_Rect display_bounds;
  SDL_GetDisplayBounds(display, &display_bounds);

  if (!SDL_SetAppMetadata("Geometry Sim", "v0.1", NULL)) // Not strictly needed but nice to have
    return Panic("Medadata creation failed");

  if (!SDL_CreateWindowAndRenderer("Geometry Sim", display_bounds.w, display_bounds.h, SDL_WINDOW_RESIZABLE | SDL_WINDOW_FULLSCREEN, &app->window, &app->renderer))
    return Panic("Window/Renderer creation failed");

  if (!SDL_SetRenderLogicalPresentation(app->renderer, display_bounds.w, display_bounds.h, SDL_LOGICAL_PRESENTATION_LETTERBOX))
    return Panic("Logical Presentation creation failed");

  // My own stuff (mmmm pointers :3c)
  if (!render_init(app))
    return Panic("render_init failed");

  const char* msg = rust_hello();
  printf("Rust says: %s\n", msg);

  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result)
{
  AppState *app = (AppState *)appstate;

  render_cleanup(app->rc);

  if (result == SDL_APP_FAILURE)
    printf("Oopsie, i died! :3\n");
  else
    printf("I somehow didn't die! :D\n");

  SDL_DestroyRenderer(app->renderer);
  SDL_DestroyWindow(app->window);
  SDL_free(app);
}
