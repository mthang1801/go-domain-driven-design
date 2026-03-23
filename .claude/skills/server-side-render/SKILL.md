---
name: server-side-render
description: Patterns for implementing Server-Side Rendering (SSR) pages and serving static assets using the internal assets-base module. This is used via NestJS backend if React/Next.js frontend is not applicable.
---

# Frontend SSR Patterns (NestJS + Handlebars)

This skill documents how to create Server-Side Rendered (SSR) client views within the NestJS backend, utilizing the `assets-base` module. This pattern has been applied to modules such as `formula-engine`, `transform-editor`, `dynamic-api-editor`, and `redis-manager`.

## 🎯 Goal

Embed a web client (HTML, CSS, JS) directly into a NestJS module domain, allowing the application to serve UI tools without a separate frontend project, using Handlebars (`.hbs`).

> **⚠️ IMPORTANT FUTURE CONSIDERATION**: While NestJS SSR with `.hbs` is available, this project's **primary frontend stack** relies on React/Next.js (`vercel-react-best-practices`). Use this SSR pattern ONLY when tightly coupling the view to the backend is absolutely necessary.

## 📁 Required Folder Structure

Inside your NestJS module (e.g., `libs/src/common/modules/my-editor`), create an `assets` folder with the following structure:

```text
my-editor/
├── assets/
│   ├── views/
│   │   └── my-editor.hbs             # View template
│   └── public/
│       └── my-editor/                # Must match 'publicPath' config
│           ├── js/
│           │   └── app.js            # Client-side Logic
│           └── css/
│               └── styles.css        # Client-side Styles
├── my-editor.module.ts
├── my-editor.controller.ts
└── my-editor.constants.ts
```

> **Note:** During module initialization, `BaseAssetsModule` automatically copies `assets/views/*` to the project root `assets/views/` and `assets/public/my-editor/*` to project root `assets/my-editor/`.

## 🚀 Implementation Guide

### 1. Extend `BaseAssetsModule`

In your module definition context, extend `BaseAssetsModule` located in `libs/src/common/modules/assets-base` and provide the configuration.

```typescript
import { Global, Module } from '@nestjs/common';
import { AssetsModuleConfig, BaseAssetsModule } from '../assets-base';
import { MyEditorController } from './my-editor.controller';

@Module({
    controllers: [MyEditorController],
})
@Global()
export class LibMyEditorModule extends BaseAssetsModule {
    protected getConfig(): AssetsModuleConfig {
        return {
            moduleName: 'my-editor', // Internal name for logging/deduplication
            publicPath: 'my-editor', // The URL path prefix for static assets
        };
    }

    protected getModuleDir(): string {
        return __dirname;
    }
}
```

### 2. Extend `AssetsBaseController`

Your controller must extend `AssetsBaseController` to utilize the `buildEditorViewData` method, which injects `apiBaseUrl` and `basePath` properties that are usually required by the client-side JavaScript.

```typescript
import { Controller, Get, Inject, Render, Req } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { AssetsBaseController } from '../assets-base/assets-base.controller';
// Define these constants in your module context
import { MY_EDITOR_ENDPOINT, getMyEditorApiBaseUrl } from './my-editor.constants';

@Controller('my-editor')
export class MyEditorController extends AssetsBaseController {
    constructor(@Inject(ConfigService) configService: ConfigService) {
        super(configService, MyEditorController.name);
    }

    @Get()
    @Render('my-editor') // references views/my-editor.hbs
    public editor(@Req() req: Request) {
        return this.buildEditorViewData(req, MY_EDITOR_ENDPOINT, getMyEditorApiBaseUrl);
    }
}
```

### 3. Create the Handlebars View (`my-editor.hbs`)

Ensure your static assets are referenced via the `publicPath` definition inside the view template, and inject the generated data.

```html
<!DOCTYPE html>
<html>
    <head>
        <title>My Editor</title>
        <!-- Adjust URL mapping logically based on publicPath -->
        <link rel="stylesheet" href="{{basePath}}/my-editor/css/styles.css" />

        <!-- Pass dynamic variables injected by controller to window object -->
        <script>
            window.EDITOR_CONFIG = {
                apiBaseUrl: '{{apiBaseUrl}}',
                basePath: '{{basePath}}',
                endpoint: '{{endpoint}}',
            };
        </script>
    </head>
    <body>
        <div id="app">Hello World from SSR!</div>

        <!-- Include client side JS -->
        <script src="{{basePath}}/my-editor/js/app.js"></script>
    </body>
</html>
```

## 🧠 Main Application Configuration (`main.ts`)

For the underlying mechanism to function properly, the main `NestExpressApplication` relies on `BaseAssetsModule.setupAssets(app)` typically instantiated in `src/main.ts` (or handled automatically if extending `BaseAssetsModule` setups correctly).

```typescript
import { NestExpressApplication } from '@nestjs/platform-express';
import { BaseAssetsModule } from './libs/src/common/modules/assets-base';

async function bootstrap() {
    const app = await NestFactory.create<NestExpressApplication>(AppModule);

    // ...
    BaseAssetsModule.setupAssets(app);
    // ...
}
```
