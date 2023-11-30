## orderly.sharedrive

<!-- badges: start -->
[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)
[![codecov.io](https://codecov.io/github/vimc/orderly.sharedrive/coverage.svg?branch=master)](https://codecov.io/github/vimc/orderly.sharedrive?branch=master)
[![R-CMD-check](https://github.com/vimc/orderly.sharedrive/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/vimc/orderly.sharedrive/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

An [`orderly1`](https://github.com/vimc/orderly1) remote hosted on a shared drive. Either a network share or a synced onedrive.

### Usage

Configure your `orderly_config.yml` as, for example:

```
remote:
  real:
    driver: orderly.sharedrive::orderly_remote_sharedrive
    args:
      path: ~/path/to/drive
```

Where

* `path` is the path to your shared drive. This can be an environment variable

`orderly.sharedrive` will store files as `archive/<name>/<id>` where `<name>` is the report name and `<id>` is a zip archive of the report contents.  These must be treated as read-only and must not be modified (they do not have a file extension to help this).

With this set up, then `orderly1::pull_dependencies`, `orderly1::pull_archive` and `orderly1::push_archive` will work, and you can use your network or onedrive remote to distribute orderly results within your group.

## License

MIT © Imperial College of Science, Technology and Medicine
