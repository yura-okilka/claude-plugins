# claude-plugins

A personal [Claude Code](https://code.claude.com) plugin marketplace.

## Add this marketplace

```text
/plugin marketplace add yura-okilka/claude-plugins
```

Then browse with `/plugin`, or install a plugin directly (see below).

## Plugins

| Plugin | Description | Install |
| ------ | ----------- | ------- |
| [`toast-notify`](./toast-notify) | Windows 11 toast notifications; click the toast to focus the terminal window that triggered it. **Windows only.** | `/plugin install toast-notify@yura-okilka` |

## Updates

Each plugin is versioned via the `version` field in its `plugin.json`. Bump it and push
to publish an update; users pick it up through `/plugin`.
