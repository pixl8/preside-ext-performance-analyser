# Preside Performance Analyser

A Preside extension that adds a **Monitoring tools** area to the admin for diagnosing performance problems in a running Preside application. It lets you see what the server is doing right now, capture thread and heap dumps, and record per-request Lucee debug data (queries, execution times and memory allocation) into the Preside database for later analysis.

## Features

### Active threads

A live view of the requests and CFML threads that are in progress right now, including ones that are sleeping or waiting on a lock. Idle threads and the request loading the list are hidden.

Each row shows:

* What the thread is doing: the URL of an incoming request (with the page type for site tree pages, or the ColdBox event otherwise), or the name of the scheduled or ad hoc task that is running
* The Java thread name and state
* How long the current request or task has been running
* An expandable CFML stack trace, with a button to copy it to the clipboard

The list can be refreshed manually or auto-refreshed every 1, 2, 3, 5 or 10 seconds.

### Thread dumps

**Save thread dump** captures every thread in the JVM, with both its CFML frames and full Java stack, and stores it in the database. Dumps are listed under the **Thread dumps** tab. When viewing a dump you can:

* Filter to active CFML requests only, or show all threads
* Switch between the CFML stack and the full Java stack
* Copy either rendering to the clipboard

### Heap dumps

**Download heap dump** writes an `.hprof` heap dump of the JVM and stores it using the extension's storage provider (see [Configuration](#configuration)). Saved dumps are listed under the **Heapdumps** tab. Requires Lucee admin access.

### Debug logs

When enabled, Lucee debug output for each request is captured silently and stored in the Preside database. The **Debug logs** tab lists logged requests; drilling into a log shows:

* Summary: type (HTTP, scheduled task or ad hoc task), URL or task, total and query time, memory used, and the admin or website user
* Queries: SQL, time taken and record count
* Execution times: count, min, max, average and total per template
* Memory: allocation by kind (event, viewlet, view, layout, `selectData` and `renderData`), the largest consumers, and a call hierarchy showing how allocation nests within the request

Debug logging is controlled from **Edit debug settings** (requires Lucee admin access):

* Enable or disable logging and choose which Lucee debug features to capture
* Optionally track memory allocation per frame
* Optionally display Lucee debug output in pages for selected IP addresses
* Choose how many days logs are kept; a scheduled task (**Cleanup debug logs**) removes older logs hourly
* Restrict logging to particular IPs or URL patterns, exclude URL patterns, and choose whether background tasks are logged

> **Warning:** debug logging has its own performance cost. Avoid enabling it in production, or do so only briefly and with care.

## Installation

Install with CommandBox from within your Preside application:

```
box install preside-ext-performance-analyser
```

Then reload the application. The extension creates its own database tables on the next schema sync.

## Permissions

The extension registers a single admin permission, `performanceanalyser.access`. No roles are granted it by default, so only super users can see **Monitoring tools** until you add the permission to a role in your application's `Config.cfc`.

## Configuration

### Lucee admin access

Editing debug settings and taking heap dumps use the Lucee admin API. Either configure the Lucee admin for open API access, or make the admin password available to the application in one of these ways:

* `LUCEE_ADMIN_PASSWORD` environment variable (or `lucee.admin.password`)
* `settings.performanceAnalyser.luceeAdminPassword = "..."` in your `Config.cfc`

Active threads, thread dumps and viewing existing debug logs work without admin access.

### Heap dump storage

Heap dumps are stored privately using the `performanceAnalyserStorageProvider` WireBox mapping. By default this is a file system provider under your `uploads_directory` at `/performanceAnalyser`. If your application defines `settings.s3StorageProvider` (bucket, access key, secret key and optionally region, subpath and root URL) and has the S3 storage provider extension installed, dumps are stored in S3 under a `/performanceAnalyser` subpath instead.

## Development

Admin JavaScript lives in `assets/js` and is built with Grunt. The minified, hashed bundles are gitignored, so rebuild after changing the source:

```
cd assets
npm install
node -e "require('grunt').cli()"
```

Tests use TestBox and run with `./test.sh`, which starts a CommandBox server from `server-tests.json`.

## Versioning

We use [SemVer](https://semver.org) for versioning. For the versions available, see the [tags on this repository](https://github.com/pixl8/preside-ext-performance-analyser/releases). Project releases can also be found and installed from [Forgebox](https://forgebox.io/view/preside-ext-performance-analyser).

## License

This project is licensed under the GPLv2 License - see the [LICENSE.txt](https://github.com/pixl8/preside-ext-performance-analyser/blob/stable/LICENSE.txt) file for details.

## Authors

The project is maintained by [The Pixl8 Group](https://www.pixl8.co.uk). The lead developer is [Dominic Watson](https://github.com/DominicWatson).

## Code of conduct

We are a small, friendly and professional community. For the eradication of doubt, we publish a simple [code of conduct](https://github.com/pixl8/preside-ext-performance-analyser/blob/stable/CODE_OF_CONDUCT.md) and expect all contributors, users and passers-by to observe it.
