// render.c

void main_render(RenderContext* rc)
{
  SDL_SetRenderDrawColor(rc->renderer, 50, 50, 50, 255);
  SDL_RenderClear(rc->renderer);
  SDL_RenderPresent(rc->renderer);
}

bool render_init(AppState* app)
{
  app->rc = SDL_malloc(sizeof(RenderContext));
  if (!app->rc || !app->renderer)
      return false;
  
  app->rc->renderer = app->renderer;

  return true;
}

void render_cleanup(RenderContext* rc)
{
  if (!rc)
    return;

  SDL_free(rc);
}

