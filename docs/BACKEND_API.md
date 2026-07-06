# Backend API contract

The FMX app is a thin client for a separate **Gin (Go)** backend service (repo `article-to-epub`). The canonical request contract lives in this repo under `postman/`:

- `postman/articletoepub.postman_collection.json` — request collection
- `postman/articletoepub.postman_environment.json` — local environment (`baseUrl`, `apiKey`, ...)

## Endpoints

| Method & path        | Body / form                                   | Behavior                                                                                     | Used by app? |
|----------------------|-----------------------------------------------|----------------------------------------------------------------------------------------------|--------------|
| `POST /api/fetch-url`| JSON `{"url": ..., "email": [...]}`           | Empty `email` → returns EPUB as binary download. Non-empty `email` → mails the EPUB, returns JSON. | Yes — send-email variant (`src/DMRestClient.pas`, `TBody`) |
| `POST /api/convert-html` | multipart form (`html` file, `email`, `url`) | Converts uploaded HTML. **Backend handler currently empty.**                              | No           |
| `health`             | —                                             | Health/connectivity check.                                                                   | Yes — settings-tab health button (not in Postman collection) |

## Auth

Every request carries an `Authorization: API-Key <key>` header. In the app this is added in `TRESTClient.AddCommonHeaders` (`src/DMRestClient.pas`); the key comes from `TAppSettings.ApiKey`.

## Notes

- Keep `postman/` in sync when the backend contract changes.
- The app's default/base URL is user-configurable in the Settings frame (advanced section) and stored in the INI settings file.
