# speedtest — OpenHost app

A self-hosted internet speed test that measures **download, upload, ping, and
jitter between your browser and this OpenHost server**. It's a packaging of
[LibreSpeed](https://github.com/librespeed/speedtest) using the
[`speedtest-go`](https://github.com/librespeed/speedtest-go) backend — a single
Go binary with the web frontend embedded.

Open the app's URL and click **Start**. That's it.

## How it works

`speedtest-go` serves both the web UI and the test endpoints from one port
(8989):

- `GET /garbage` — download test (streams random data to the browser)
- `POST /empty` — upload test (receives and discards data)
- `GET /empty` — ping / jitter probe
- `GET /getIP` — client IP (ISP lookup is disabled; no external API calls)
- `GET /` — the LibreSpeed web UI

The OpenHost router proxies your browser's requests to the container, so the
numbers reflect end-to-end throughput **between your browser and this server**
over whatever network path is between them.

## Files

| File | Purpose |
|------|---------|
| `openhost.toml` | OpenHost manifest (port 8989, health check `/`, 1 CPU / 256 MB). |
| `Dockerfile` | Multi-stage build of `speedtest-go` pinned to a release tag. |
| `settings.toml` | LibreSpeed config: stateless (`database_type="none"`), binds all interfaces on 8989. |

To update LibreSpeed, bump `SPEEDTEST_VERSION` in the `Dockerfile`.

## Notes / caveats

- **Auth:** the test endpoints are left behind OpenHost's default auth (no
  `public_paths`), so only the logged-in compute-space owner can run a test.
  The browser's session cookie is sent automatically with the same-origin test
  requests, so it just works once you're logged in. This deliberately keeps the
  bandwidth-heavy endpoints from being hit by anonymous traffic — if you want to
  test from a device that isn't logged in, add `public_paths = ["/"]` (and the
  test endpoints) to `[routing]`, understanding the abuse trade-off.
- **Stateless:** nothing is persisted (`app_data = false`). Results are shown
  live in the browser; the LibreSpeed "share results as an image" feature is
  disabled because it requires a results database.
- **Measurement accuracy:** results are gated by the full path —
  browser → TLS/Caddy → router proxy → container. The router proxies rather than
  letting the browser hit the container directly, so on very fast links the
  proxy (not your connection) can become the ceiling. For typical home/office
  links this measures the connection as expected.

## Deploy

From the OpenHost dashboard, "Deploy New App" with this repo's URL, or via the
CLI:

```bash
oh app deploy https://github.com/<you>/speedtest --name speedtest --wait
oh app logs speedtest --follow
```
