# Contributing to CapsJump

Thanks for wanting to help. CapsJump is small on purpose, and it stays good by doing a few things really well. So here is how a change goes in, so you don't spend a weekend on something before we've talked about it.

## Start with an issue

Before writing code, open an issue (or comment on one) and say what you want to change and why. That's where we agree what's in and what's out. A small bug fix can skip this. A change to what CapsJump does, or to what the config accepts, shouldn't.

## One thing per pull request

- One behaviour per PR. If you find an unrelated bug on the way, send it as its own PR. It'll probably merge faster.
- Rebase on `main` rather than merging `main` into your branch.
- Leave `VERSION`, the README's opening, `site/` and the packaging text (`packaging/Info.plist`, `packaging/capsjump.rb.in`) to the maintainer. They're how CapsJump describes itself, and they change at release time. If your change needs new words there, say so in the PR.
- A change to the config's rules updates `skills/capsjump/SKILL.md` in the same PR. `SkillReferenceTests` checks it.

## Say what you ran

CapsJump talks to apps, browsers and macOS permissions, and a lot of that can't be unit tested. So every PR has a "Tested on" line: the macOS version, the app or browser where it matters, what you pressed and what happened. If you couldn't try something, just say so. That's completely fine. CapsJump only claims what someone has actually run.

## Browsers

Today, sites land in Google Chrome. Other browsers come in one at a time, each in its own PR, from someone who uses that browser and has run it. Every browser has its own window titles, profile list and quirks, so "it should work the same" isn't enough.

## Build and test

The README's [Develop](README.md#develop) section has the commands and the code layout. A few things worth knowing:

- `make test` runs the same tests as CI. CI also checks the icons (`scripts/make-icon.sh --check`) and builds the bundle (`scripts/bundle.sh`).
- The rules live in `Sources/CapsJumpCore`, with their tests. A new rule comes with a test that fails without it.
- Keep only one CapsJump on your Mac while you test a local build. The release and your build share an app ID, so macOS keeps one set of permissions for both, and they keep taking it from each other. Quit the release, move it out of Applications (its login item follows it, so it has to go, not just be renamed), then `make install-local`. Found by @harsha-at-magicshake while testing #44.
- Some changes, like how a window is brought forward, can only be proven on a signed build. Say so in the PR, and the maintainer will run a signed build of it.

## Code style

Follow the code around you. Each file starts with a comment that says what it's for, comments explain why rather than what, and every message is a plain sentence a person can act on.

That's it. If something here doesn't make sense, open an issue and say so. This guide can change too.
