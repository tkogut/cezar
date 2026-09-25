# 🧠 AGENTS-OS v6.5 SWARM MEMORY ENGINE (v0.42.1)

---
version: 0.42.1
schema: agents-os-memory-v1
sync_mode: distributed-union
last_sync: init
---

## 🧭 Swarm Node & Machine Registry
- **Active Node**: Local Workspace
- **Sync Protocol**: Native Git Union Merge (`.gitattributes`)
- **Lifecycle Triggers**: `SessionStart` (rebase pull) / `SessionEnd` (auto state-dump push)

## 📌 Epics & Persistent Context
- **Active Epic**: Project Architecture & Swarm Initialization
- **System Constraints**:
  - Triad Separation of Concerns (Coordinator: plan & route / Builder: implement & test / Auditor: lint & verify)
  - Worktree Isolation Mandate (`tmp/worktrees/`)
  - No direct pushes to main/master by execution roles

## 📝 Decisions & Key Milestones
- [INIT] Project initialized under AGENTS-OS v6.5 Swarm Edition.
- [SYNC] Conflict-free distributed auto-sync enabled for `MEMORY.md` and `task.md`.
- [VPS-SYNC] Imported Cezar stack (Docker, Traefik, entrypoint, CI/CD) from VPS to GitHub `tkogut/cezar`.
- [ARCH-DEPLOY] CI/CD Zero-Passphrase Standard: GitHub Actions secrets `VPS_SSH_KEY` must use dedicated unencrypted deploy keys without `VPS_PASSPHRASE`.
- [ARCH-NET] Cross-Container Networking: Containers on the same VPS (e.g. Cezar <-> LinkedIn Tracker) must communicate directly via Docker network `traefik-proxy` (e.g. `http://linkedin_tracker_app:8000`) or `/var/run/docker.sock`, never via loopback SSH.

## 🔄 Machine Session Log
<!-- Format: - [YYYY-MM-DD HH:MM UTC] [Node] [Role] Description -->
- [INIT] [Local] [Coordinator] Swarm memory initialized with union-merge capability.
- [2026-09-25 10:59 UTC] [Local] [Coordinator] Imported and aligned Cezar VPS environment into repo main branch.
