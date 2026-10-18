---
name: capsjump
description: Sets up, changes, lists or explains CapsJump's Caps Lock shortcuts on a Mac, kept in ~/.capsjump.yaml. Caps Lock plus a key brings an app forward, lands on a site's tab in the right Chrome account, snaps the front window, or opens a link. Use when someone asks for a Caps Lock key or shortcut, mentions CapsJump, or wants ~/.capsjump.yaml read or edited.
allowed-tools: Bash(capsjump version) Bash(capsjump profiles *) Bash(capsjump check *)
---

# CapsJump

CapsJump turns Caps Lock into a shortcut key on a Mac. One file, `~/.capsjump.yaml`, says which key does what, and CapsJump applies it the moment the file is saved. You edit that file. CapsJump's own commands tell you which Chrome accounts exist, check your edit, and lay the file out the way CapsJump writes it. Its Edit Config… window edits the same file, so the person can always carry on there.

Work through these steps in order.

## 1. Find CapsJump

Run `capsjump version`.

- **Not found.** Ask whether to install it. On a yes, run `brew install --cask whysosuresh/tap/capsjump`, then `open -a CapsJump`. Tell the person its Welcome window will ask for Accessibility, which only they can grant. Without Homebrew, point them to https://capsjump.com and stop.
- **Older than 0.9.0.** It has no `--json` and no `tidy`. Offer `brew upgrade --cask capsjump` first. If they'd rather not, read the plain output of `capsjump check` and `capsjump profiles`, skip `tidy`, and write the file in the layout shown under Reference.
- **`dev …`.** A local build; treat it as current.

## 2. Read before writing

Run `capsjump check --json`. It prints:

- `config`: the file to edit. When `~/.capsjump.yaml` is a symlink (dotfiles), this is the file it points to. Edit that path, and never replace the link.
- `file`: findings about the file. `app`: findings about the app. Each has a `level` (`ok`, `note` or `problem`) and a `text`.

Read the file before changing it.

If `file` says there is no config, ask which they want:

- CapsJump's starter: `capsjump init` writes the window keys (Caps Lock + the arrows snaps the front window to a half, F fills the screen) and an example `github` site in their first Chrome account. Then add what they asked for.
- Only the keys they asked for, in a new file you write.

## 3. Map their words to Chrome accounts (sites only)

Run `capsjump profiles --json`. Each profile has:

- `folder`: Chrome's folder for it (`Default`, `Profile 3`).
- `account`: the signed-in email, or `null` when nobody is signed in.
- `name`, `windowLabel`: the names Chrome shows for it.
- `sharedWith`: other folders whose windows carry the same label.
- `site`: exactly what a site in this profile writes.

"My work account" or "the acme one" picks a profile only when exactly one fits its account, name or label. Otherwise list the ones that could fit and ask. Never guess an email. Copy the chosen profile's `site` fields into the site as given: `account` always, `profile` only when it is there. If `sharedWith` isn't empty, tell the person that the site will always open a new tab there, because Chrome's windows for those profiles can't be told apart.

## 4. Edit

- Keep everything else. Never remove or rebind a key the person didn't name.
- If the key they want is taken, say what it does now, suggest a free one, and ask.
- An app is its name as it appears in Applications (`iTerm`, `Slack`), or a path to the .app starting with `/` or `~/`.
- A new site needs a `name`, the account fields from step 3, and `open`. Add `match` only when `open` is a deep page that should also find a tab elsewhere on the site (see Reference).
- Then run `capsjump tidy`. It rewrites the file in the layout CapsJump writes, as its Edit Config… window saves it, so the window never has to ask before saving over it. It drops comments. If the file has the person's own comments (anything outside the header that starts `# Written by CapsJump.`), ask before tidying. If they want to keep them, skip `tidy`; `check` will then carry a note about the layout, which is fine.

## 5. Check until the file is clean

Run `capsjump check --json` again. Fix every `problem` in `file` and check again, until `file` has none. A `note` in `file` is information to pass on, not a failure.

`check` exits non-zero, and `ok` is `false`, while `app` has a problem too. Judge your edit by `file` alone. Problems in `app` are the person's to fix (step 6).

## 6. Hand back

Say what changed, one line per key added or changed, for example: "Caps Lock + G: your pull requests on GitHub, in alex@acme.dev's Chrome".

Then pass on each `problem` and `note` in `app`, in plain words, with what the person does. Its text already says what to do: open CapsJump, grant Accessibility in System Settings, resume paused keys. Only the person can grant macOS permissions; never claim to have done it. The first time a site key runs, macOS also asks to let CapsJump control Chrome.

The keys work as soon as the file is saved; nothing needs restarting.

## Reference

`capsjump check` is the authority for the installed version: it refuses anything that version doesn't know. The README (https://github.com/whysosuresh/capsjump#configure) has every detail.

The file, in CapsJump's layout:

```yaml
sites:
- name: github
  account: you@work.com
  open: https://github.com/your-org/your-repo/pulls
  match: [github.com/your-org/your-repo/pulls, github.com/]
- name: claude-client
  account: client@example.com
  open: https://claude.ai/new

keys:
  s: {app: iTerm}
  g: {site: github}
  f1: {site: claude-client}
  left: {window: left-half}
  f: {window: maximize}
  w: {url: 'slack://channel?team=T123&id=C456'}
```

**Key names** (each entry under `keys:` is Caps Lock plus that key): `a`–`z`, `0`–`9`, `f1`–`f12`, `left`, `right`, `up`, `down`. Lower case only.

**Actions** (each key does exactly one):

| Action | Value |
| --- | --- |
| `app` | An app's name (`Slack`), or a path to an .app starting with `/` or `~/`. It comes forward, starting if needed. |
| `site` | The `name` of a site under `sites:`. Lands on that site's tab in its Chrome account, or opens it there. |
| `window` | A move for the front window: `left-half`, `right-half`, `top-half`, `bottom-half`, `maximize` (fills the screen, not macOS full screen). |
| `url` | Any link with a scheme (`slack://…`, `zoommtg://…`, `https://…`), opened as a click would, afresh each time. |

**Site fields:**

| Field | |
| --- | --- |
| `name` | Lower-case letters, digits and hyphens. Also the link `capsjump://<name>`. |
| `account` | From `site.account` in `capsjump profiles --json`. |
| `profile` | From `site.profile`, only when it is given there. |
| `open` | The page opened when no tab matches. |
| `match` | Optional. URL prefixes without the scheme, most specific first; the default is `open`'s host (`github.com/`). |

A file with no `keys:` leaves Caps Lock alone.
