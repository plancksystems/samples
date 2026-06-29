# Planck sample apps

Five runnable samples that show the four ways you can build on Planck:
two front-end styles (HDA and SPA) across two deployment shapes (mono
and micro).

| App                                          | Shape | Front end      | What it shows                                                                 |
| -------------------------------------------- | ----- | -------------- | ----------------------------------------------------------------------------- |
| [`pql-demo`](./pql-demo)                     | mono  | HDA (datastar) | AdventureWorks dataset + an interactive PQL query playground                  |
| [`notes_spa_mono`](./notes_spa_mono)         | mono  | SPA (Vue 3)    | A Vue notes app and its JSON API served from one WASM monolith                |
| [`notes_spa_micro`](./notes_spa_micro)       | micro | SPA (Vue 3)    | The same notes app split into a service plus a live SSE stream                |
| [`pizzaqsr-hda-mono`](./pizzaqsr-hda-mono)   | mono  | HDA (datastar) | A pizza QSR order flow as a single hypermedia monolith (import + export demo) |
| [`pizzaqsr-hda-micro`](./pizzaqsr-hda-micro) | micro | HDA (datastar) | The same pizza QSR split into six services, each with its own DB              |

- **mono**: the app's WASM bundle, its HTTP server, and one embedded
  Planck DB all run as one service. There is exactly one store group,
  reached by the service slug `<app>_db`.
- **micro**: each feature is its own WASM service with its own Planck
  DB and its own port. Each service is reached by the slug
  `<app>_<service>`.
- **HDA**: hypermedia-driven. The server renders HTML fragments and
  drives the page with datastar over SSE.
- **SPA**: a Vue 3 single-page app talks to the service over JSON.

---

## Prerequisites

1. `systemdb` and `workbench` are running, and a `planctl` profile named
   `dev` points at your workbench. `planctl` reads its target host(s)
   from `~/.planctl/config.yaml`, which declares one or more profiles,
   each listing one or more workbench nodes:

   ```yaml
   profiles:
     - name: dev
       nodes:
         - server: http://127.0.0.1:2369
           uid: admin
           key: UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=

     - name: prod
       nodes:
         - server: https://prod-wb.example.com
           uid: admin
           key: <your-wb-admin-key>
   ```

   `UGxhbmNrX0RlZmF1bHRfQWRtaW5fS2V5XzAwMTA=` is the **default workbench
   admin key**, fine for local `dev`. Generate and set your own key for
   any real deployment. See the
   [planctl README](../plancks/planctl/README.md) for the full
   `config.yaml` reference.

2. Run every command below **from the app's project root** (the folder
   that contains `app.yaml`). From there, `planctl` reads the app name
   from `app.yaml`, so you rarely need `--app`.
3. The slug naming rule:
   - **mono** is always `<app>_db` (one service called `db`).
   - **micro** is `<app>_<service>`, so you pass `--service <name>` on
     every store, index, and import command.

### How the three steps fit together

For each app you:

1. **Deploy** the app (and its services) so the workbench registers the
   service slug(s).
2. **Create** the stores and secondary indexes the app queries.
3. **Import** the seed data from each app's `seed/` folder.

> **Imports are server-side.** `planctl import` hands the workbench a
> manifest; the workbench reads the JSON files named in it from the
> `output_dir` on the workbench host (not from your shell's working
> directory). The seed manifests below point `output_dir` at the
> in-repo `seed/` folder. If your workbench runs from a different
> checkout or a deployed copy, edit each manifest's `output_dir` to
> wherever the seed files actually live on that host.

> **Manifests only type the non-string fields.** Strings pass through
> as-is, so a manifest lists just the `int` / `double` fields that need
> coercion. That is why, for example, the pizza manifests only declare
> `ProductID`, `CategoryID`, and `BasePrice`.

---

## 1. `pql-demo` (mono, HDA)

An AdventureWorks-style dataset (orders, customers, employees, products,
categories, vendors, addresses) with a hypermedia page where you run
PQL queries: joins, filters on secondary indexes, and aggregations.

- **Slug:** `pql_demo_db`
- **Stores (9):** `orders`, `customers`, `employees`, `products`,
  `productcategories`, `productsubcategories`, `vendors`,
  `vendorproduct`, `addresses`

> This app can provision itself: its in-app **Setup** button (and the
> `src/setup.zig` bootstrap binary) creates every store and index in
> one shot from `src/core/db_setup.zig`. The `planctl` commands below
> are the manual equivalent, useful when you want to drive setup from
> the CLI.

### Deploy

```bash
cd samples/pql-demo
planctl deploy --all --arch mono --profile dev
```

### Create stores

```bash
planctl create store orders             --profile dev
planctl create store customers          --profile dev
planctl create store employees          --profile dev
planctl create store products           --profile dev
planctl create store productcategories  --profile dev
planctl create store productsubcategories --profile dev
planctl create store vendors            --profile dev
planctl create store vendorproduct      --profile dev
planctl create store addresses          --profile dev
```

### Create indexes

These mirror the index set the app ships in `db_setup.zig`. For nested
fields (the customer address), pass `--field` so the index name and the
indexed path can differ.

```bash
# orders
planctl create index orders.EmployeeID    --type i64 --profile dev
planctl create index orders.CustomerID    --type i64 --profile dev
planctl create index orders.TotalDue      --type f64 --profile dev
planctl create index orders.SalesOrderID  --type i64 --profile dev

# employees
planctl create index employees.EmployeeID    --type i64    --profile dev
planctl create index employees.Gender         --type string --profile dev
planctl create index employees.MaritalStatus  --type string --profile dev

# products
planctl create index products.MakeFlag       --type i64 --profile dev
planctl create index products.ListPrice       --type f64 --profile dev
planctl create index products.SubCategoryID    --type i64 --profile dev

# vendors
planctl create index vendors.ActiveFlag    --type i64    --profile dev
planctl create index vendors.CreditRating   --type i64    --profile dev
planctl create index vendors.VendorID        --type i64    --profile dev
planctl create index vendors.VendorName      --type string --profile dev

# categories
planctl create index productcategories.CategoryName --type string --profile dev

# customers (nested address fields, named index + --field)
planctl create index customers.address_city    --field Address.City    --type string --profile dev
planctl create index customers.address_state    --field Address.State    --type string --profile dev
planctl create index customers.address_country  --field Address.Country  --type string --profile dev
planctl create index customers.address_zipcode  --field Address.ZipCode  --type string --profile dev
```

### Import seed

```bash
cd samples/pql-demo/app/seed
planctl import --manifest import.orders.yaml              --profile dev
planctl import --manifest import.customers.yaml           --profile dev
planctl import --manifest import.employees.yaml           --profile dev
planctl import --manifest import.products.yaml            --profile dev
planctl import --manifest import.productcategories.yaml   --profile dev
planctl import --manifest import.productsubcategories.yaml --profile dev
planctl import --manifest import.vendors.yaml             --profile dev
planctl import --manifest import.addresses.yaml           --profile dev
planctl import --manifest import.vendorproduct.yaml       --profile dev
```

---

## 2. `notes_spa_mono` (mono, SPA)

A Vue 3 notes app (list, create, edit, delete) whose JSON API and static
SPA bundle are both served from one Planck WASM monolith.

- **Slug:** `notes_spa_mono_db`
- **Store:** `notes` (primary key `NoteID`)

### Deploy

```bash
cd samples/notes_spa_mono
planctl deploy --all --arch mono --profile dev
```

### Create store and indexes

```bash
planctl create store notes              --profile dev
planctl create index notes.UpdatedAt --type i64 --profile dev
planctl create index notes.CreatedAt --type i64 --profile dev
```

### Import seed

```bash
cd samples/notes_spa_mono/app/seed
planctl import --manifest import.notes.yaml --profile dev
```

---

## 3. `notes_spa_micro` (micro, SPA)

The same notes app, split out: a `notes` WASM service holds the JSON CRUD
API, and a separate native `sse/` service watches the `notes` store and
streams live change events to the browser.

- **Service:** `notes` → **slug:** `notes_spa_micro_notes`
- **Store:** `notes` (primary key `NoteID`)

Because this is a micro app, pass `--service notes` on every store,
index, and import command.

### Deploy

```bash
cd samples/notes_spa_micro
planctl deploy --all --arch micro --profile dev
```

`--all` includes the `sse/` subproject. To iterate on just the stream,
use `planctl deploy --sse --profile dev`.

### Create store and indexes

```bash
planctl create store notes              --service notes --profile dev
planctl create index notes.UpdatedAt --service notes --type i64 --profile dev
planctl create index notes.CreatedAt --service notes --type i64 --profile dev
```

### Import seed

```bash
cd samples/notes_spa_micro/app/services/notes/seed
planctl import --manifest import.notes.yaml --service notes --profile dev
```

---

## 4. `pizzaqsr-hda-mono` (mono, HDA)

A pizza QSR order flow (catalog, cart, checkout, payment, kitchen,
delivery) as a single hypermedia monolith. It also doubles as the
**export** demo: `app/seed/` ships `export.*.{json,csv,bson}.yaml`
manifests and pre-generated files under `app/seed/exports/`.

- **Slug:** `pizzaqsr-hda-mono_db`
- **Stores (6):** `products`, `categories`, `orders`, `carts`,
  `payments`, `users`. Only `products` and `categories` ship seed data;
  the rest are created on first write at runtime, but you can pre-create
  them so indexes exist up front.

### Deploy

```bash
cd samples/pizzaqsr-hda-mono
planctl deploy --all --arch mono --profile dev
```

### Create stores

```bash
planctl create store categories --profile dev
planctl create store products    --profile dev
planctl create store orders      --profile dev
planctl create store carts       --profile dev
planctl create store payments    --profile dev
planctl create store users       --profile dev
```

### Create indexes

```bash
# catalog
planctl create index products.ProductID    --type i64 --profile dev
planctl create index products.CategoryID    --type i64 --profile dev
planctl create index categories.CategoryID  --type i64 --profile dev

# orders / carts (looked up by public key and customer)
planctl create index orders.OrderID    --type i64    --profile dev
planctl create index orders.OrderKey    --type string --profile dev
planctl create index orders.CustomerID  --type string --profile dev
planctl create index carts.CartID       --type i64    --profile dev
planctl create index carts.CustomerID   --type string --profile dev

# payments / users
planctl create index payments.PaymentID --type i64    --profile dev
planctl create index payments.OrderID    --type i64    --profile dev
planctl create index payments.IntentID   --type string --profile dev
planctl create index users.UserID        --type i64    --profile dev
planctl create index users.GoogleSub      --type string --profile dev
planctl create index users.Email          --type string --profile dev
```

### Import seed

```bash
cd samples/pizzaqsr-hda-mono/app/seed
planctl import --manifest import.categories.yaml --profile dev
planctl import --manifest import.products.yaml   --profile dev
```

### Export (optional demo)

This app also shows the export side. After you have data, write it back
out to JSON, CSV, or BSON:

```bash
cd samples/pizzaqsr-hda-mono/app/seed
planctl export --manifest export.products.json.yaml --profile dev
planctl export --manifest export.products.csv.yaml  --profile dev
planctl export --manifest export.products.bson.yaml --profile dev
```

---

## 5. `pizzaqsr-hda-micro` (micro, HDA)

The same pizza QSR, split into six services, each with its own Planck DB
and its own port. The browser talks to each service origin directly
(CORS), and an `sse/` service watches the `orders` store for live
updates.

| Service    | Slug                          | Owns stores              |
| ---------- | ----------------------------- | ------------------------ |
| `products` | `pizzaqsr-hda-micro_products` | `products`, `categories` |
| `orders`   | `pizzaqsr-hda-micro_orders`   | `orders`, `carts`        |
| `users`    | `pizzaqsr-hda-micro_users`    | `users`                  |
| `payments` | `pizzaqsr-hda-micro_payments` | `payments`               |
| `kitchen`  | `pizzaqsr-hda-micro_kitchen`  | none (reads `orders`)    |
| `delivery` | `pizzaqsr-hda-micro_delivery` | none (reads `orders`)    |

`kitchen` and `delivery` own no stores of their own (they read the
`orders` service), so they need no store, index, or seed setup.

### Deploy

```bash
cd samples/pizzaqsr-hda-micro
planctl deploy --all --arch micro --profile dev
```

### products service

```bash
planctl create store categories --service products --profile dev
planctl create store products    --service products --profile dev
planctl create index products.ProductID   --service products --type i64 --profile dev
planctl create index products.CategoryID    --service products --type i64 --profile dev
planctl create index categories.CategoryID  --service products --type i64 --profile dev

cd samples/pizzaqsr-hda-micro/app/services/products/seed
planctl import --manifest import.categories.yaml --service products --profile dev
planctl import --manifest import.products.yaml   --service products --profile dev
```

### orders service

```bash
planctl create store orders --service orders --profile dev
planctl create store carts   --service orders --profile dev
planctl create index orders.OrderID    --service orders --type i64    --profile dev
planctl create index orders.OrderKey    --service orders --type string --profile dev
planctl create index orders.CustomerID  --service orders --type string --profile dev
planctl create index carts.CartID       --service orders --type i64    --profile dev
planctl create index carts.CustomerID   --service orders --type string --profile dev

cd samples/pizzaqsr-hda-micro/app/services/orders/seed
planctl import --manifest import.orders.yaml --service orders --profile dev
planctl import --manifest import.carts.yaml  --service orders --profile dev
```

### users service

```bash
planctl create store users --service users --profile dev
planctl create index users.UserID    --service users --type i64    --profile dev
planctl create index users.GoogleSub  --service users --type string --profile dev
planctl create index users.Email      --service users --type string --profile dev

cd samples/pizzaqsr-hda-micro/app/services/users/seed
planctl import --manifest import.users.yaml --service users --profile dev
```

### payments service

```bash
planctl create store payments --service payments --profile dev
planctl create index payments.PaymentID --service payments --type i64    --profile dev
planctl create index payments.OrderID    --service payments --type i64    --profile dev
planctl create index payments.IntentID   --service payments --type string --profile dev

cd samples/pizzaqsr-hda-micro/app/services/payments/seed
planctl import --manifest import.payments.yaml --service payments --profile dev
```

---

## 6. Google OAuth and Stripe secrets (the pizzaqsr apps)

The two `pizzaqsr-hda-*` apps have Google sign-in and Stripe payments. They
work out of the box in a logged-out, payment-disabled state; to actually use
sign-in and checkout you supply your own credentials. There are no
environment variables and no secrets file: the values live on the app's
`Ctx`, which is initialised in source (they ship as empty strings). You edit
the init, then redeploy.

> **Where to get the values.**
>
> - **Google OAuth:** Google Cloud Console, APIs & Services, Credentials,
>   create an OAuth 2.0 Client ID (type "Web application"). Copy the
>   **Client ID** and **Client secret**, and add your callback as an
>   **Authorised redirect URI** (see the per-app URLs below).
> - **Stripe:** Stripe Dashboard, Developers, API keys for the
>   **secret key** (`sk_test_…`) and **publishable key** (`pk_test_…`); and
>   Developers, Webhooks, add an endpoint pointing at `/payments/webhook` to
>   get its **signing secret** (`whsec_…`).
>   Use test-mode keys for local development. Never commit real secrets.

The HTTP endpoints these reach (`oauth2.googleapis.com`,
`www.googleapis.com`, `api.stripe.com`) are already declared as outbound
`upstreams` in the relevant `service.yaml` (named `google_oauth`,
`google_userinfo`, `stripe_api`), so you only set the credential values. A
WASM module cannot call any host that is not in that allowlist; if you see an
`upstream not configured` error, that is the file to check.

### pizzaqsr-hda-mono

One app, so both Google and Stripe live on the same `Ctx`.

- **Deployed (WASM):** edit the `ctx = .{ ... }` literal in
  [`app/src/app.zig`](./pizzaqsr-hda-mono/app/src/app.zig) (in `export fn init`).
- **Native dev run (`zig build dev`):** edit the same fields in
  [`app/src/main.zig`](./pizzaqsr-hda-mono/app/src/main.zig).

```zig
ctx = .{
    .client = &client,
    .jwt_secret = "replace-with-a-long-random-string",   // also change this for real use
    .jwt_ttl_seconds = 30 * 24 * 60 * 60,
    .google_client_id = "<your-id>.apps.googleusercontent.com",
    .google_client_secret = "GOCSPX-...",
    .google_redirect_uri = "http://127.0.0.1:3010/auth/callback",
    .stripe_publishable_key = "pk_test_...",
    .stripe_secret_key = "sk_test_...",
    .stripe_webhook_secret = "whsec_...",
};
```

- **Authorised redirect URI:** `http://127.0.0.1:3010/auth/callback` for the
  deployed WASM app (HTTP port `3010` from `app/service.yaml`); for a native
  `zig build dev` run it is `http://127.0.0.1:4000/auth/callback`.
- **Stripe webhook endpoint:** `http://127.0.0.1:3010/payments/webhook`
  (forward to it locally with `stripe listen --forward-to ...`).

Then redeploy: `planctl deploy --all --arch mono --profile dev`.

### pizzaqsr-hda-micro

Here the concerns are split across two places:

- **Google OAuth lives in the native shell.** Edit the `Ctx` init in
  [`app/src/main.zig`](./pizzaqsr-hda-micro/app/src/main.zig) and add the
  three Google fields (they default to empty in
  [`app/src/ctx.zig`](./pizzaqsr-hda-micro/app/src/ctx.zig)):

  ```zig
  .jwt_secret = "replace-with-a-long-random-string",
  .google_client_id = "<your-id>.apps.googleusercontent.com",
  .google_client_secret = "GOCSPX-...",
  .google_redirect_uri = "http://127.0.0.1:4100/auth/callback",
  ```

  The shell serves on port `4100`, so the redirect URI is
  `http://127.0.0.1:4100/auth/callback`.

- **Stripe lives in the `payments` WASM service.** Edit the `ctx = .{ ... }`
  literal in
  [`app/services/payments/src/app.zig`](./pizzaqsr-hda-micro/app/services/payments/src/app.zig)
  (deployed), and in
  [`app/services/payments/src/dev.zig`](./pizzaqsr-hda-micro/app/services/payments/src/dev.zig)
  for native dev runs:

  ```zig
  .stripe_publishable_key = "pk_test_...",
  .stripe_secret_key = "sk_test_...",
  .stripe_webhook_secret = "whsec_...",
  ```

  The payments service serves on port `3103`, so the Stripe webhook endpoint
  is `http://127.0.0.1:3103/payments/webhook`. The `stripe_api` upstream is
  already declared in `app/services/payments/service.yaml`.

Then redeploy: `planctl deploy --all --arch micro --profile dev` (or just the
parts you changed: `planctl deploy --app --profile dev` for the shell's Google
settings, `planctl deploy --service payments --profile dev` for Stripe).

---

## Tearing down

Every `create` has a matching `drop`, and `deploy` has `undeploy`:

```bash
planctl drop index products.ProductID --profile dev
planctl drop store products --service products --profile dev
planctl undeploy --all --arch micro --profile dev
```

`drop` prompts before destroying data; add `--force` to skip the prompt.
