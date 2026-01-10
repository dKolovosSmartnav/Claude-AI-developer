# Claude Development Notes

Notes for Claude when working on the Fotios Claude System. Reference this file for development workflow.

---

## Quick Reference

### File Locations

| Purpose | Source (edit here) | Production (deployed) |
|---------|-------------------|----------------------|
| Web App | `/home/claude/fotios-claude-system/web/app.py` | `/opt/fotios-claude/web/app.py` |
| Daemon | `/home/claude/fotios-claude-system/scripts/claude-daemon.py` | `/opt/fotios-claude/scripts/claude-daemon.py` |
| Templates | `/home/claude/fotios-claude-system/web/templates/*.html` | `/opt/fotios-claude/web/templates/*.html` |
| Config | `/home/claude/fotios-claude-system/config/` | `/opt/fotios-claude/config/` |
| Scripts | `/home/claude/fotios-claude-system/scripts/` | `/opt/fotios-claude/scripts/` |

### Services

```bash
# Check status
systemctl status fotios-claude-web fotios-claude-daemon

# Restart after changes
sudo systemctl restart fotios-claude-web    # Web interface
sudo systemctl restart fotios-claude-daemon  # Background worker

# View logs
journalctl -u fotios-claude-web -f
journalctl -u fotios-claude-daemon -f
tail -f /var/log/fotios-claude/daemon.log
tail -f /var/log/fotios-claude/web.log
```

### Database

- **Type:** MySQL
- **Name:** `claude_knowledge`
- **Config:** `/etc/fotios-claude/system.conf`
- **Schema:** `/home/claude/fotios-claude-system/database/schema.sql`
- **Migrations:** `/home/claude/fotios-claude-system/database/migrations/`

```bash
# Access database
mysql -u claude_user -p claude_knowledge

# Important tables
- projects          # Project definitions
- tickets           # Tasks/tickets
- conversation_messages  # Chat history
- execution_sessions     # Claude execution sessions
- execution_logs         # Daemon logs
- daemon_logs           # System logs
- user_messages         # User input queue for daemon
```

---

## Development Workflow

### 1. Make Changes

Always edit in SOURCE directory:
```
/home/claude/fotios-claude-system/
```

### 2. Deploy to Production

```bash
# Copy app.py
sudo cp /home/claude/fotios-claude-system/web/app.py /opt/fotios-claude/web/

# Copy daemon
sudo cp /home/claude/fotios-claude-system/scripts/claude-daemon.py /opt/fotios-claude/scripts/

# Copy templates
sudo cp -r /home/claude/fotios-claude-system/web/templates/* /opt/fotios-claude/web/templates/

# Copy scripts
sudo cp /home/claude/fotios-claude-system/scripts/*.sh /opt/fotios-claude/scripts/
```

### 3. Restart Services

```bash
sudo systemctl restart fotios-claude-web fotios-claude-daemon
```

### 4. Verify

```bash
systemctl status fotios-claude-web --no-pager | head -10
```

---

## Creating New Versions

### Version Files to Update

1. **VERSION** - Single source of truth
   ```bash
   echo "X.Y.Z" > /home/claude/fotios-claude-system/VERSION
   ```

2. **web/app.py** - VERSION constant at top
   ```python
   VERSION = "X.Y.Z"
   ```

3. **README.md** - Badge and zip filenames
   - Line ~13: version badge
   - Lines with `unzip fotios-claude-system-X.Y.Z.zip`

4. **INSTALL.md** - Zip filename and footer
   - `unzip` commands
   - Footer: `**Version:** X.Y.Z`

5. **CHANGELOG.md** - New entry at TOP
   ```markdown
   ## [X.Y.Z] - YYYY-MM-DD

   ### Added
   - Feature 1
   - Feature 2

   ### Fixed
   - Bug fix 1
   ```

### Create Release Zip

```bash
cd /home/claude

# DON'T delete old zips - they are backups!
zip -r fotios-claude-system-X.Y.Z.zip fotios-claude-system \
    -x "*.pyc" -x "*__pycache__*" -x "*.git*"
```

### Version Numbering

- **Major (X):** Breaking changes, major rewrites
- **Minor (Y):** New features, significant improvements
- **Patch (Z):** Bug fixes, small improvements

---

## Key Components

### Web App (app.py)

- Flask + SocketIO
- Routes: `/dashboard`, `/projects`, `/tickets`, `/console`, `/terminal`, `/claude-assistant`
- WebSocket: Real-time updates, terminal sessions
- Auth: Session-based, bcrypt passwords

### Daemon (claude-daemon.py)

- Background worker that processes tickets
- Runs Claude CLI for each ticket
- Uses `select.select()` for non-blocking I/O (important for kill commands)
- Checks `user_messages` table for commands (/stop, /skip, /done)

### Templates

| Template | Purpose |
|----------|---------|
| dashboard.html | Main dashboard, stats |
| projects.html | Project list, create/edit |
| project_detail.html | Single project view |
| tickets_list.html | All tickets |
| ticket_detail.html | Ticket chat interface |
| console.html | Live console, all tickets |
| terminal.html | Linux terminal (xterm.js) |
| claude_assistant.html | Interactive Claude chat |
| history.html | Execution history |

### Important Patterns

**Broadcast to rooms:**
```python
socketio.emit('new_message', msg, room=f'ticket_{ticket_id}')
socketio.emit('new_message', msg, room='console')
```

**Non-blocking command check (daemon):**
```python
ready, _, _ = select.select([process.stdout], [], [], 1.0)
```

**Database query with dictionary cursor:**
```python
conn = get_db()
cursor = conn.cursor(dictionary=True)
cursor.execute("SELECT * FROM tickets WHERE id = %s", (ticket_id,))
ticket = cursor.fetchone()
cursor.close(); conn.close()
```

---

## Common Tasks

### Add New Page

1. Add route in `app.py`
2. Create template in `web/templates/`
3. Add to navigation in all templates (search for `<a href="/console">`)
4. Deploy and restart

### Add Database Column

**For new installations:** Update `database/schema.sql` directly (this is the baseline)

**For existing installations (upgrades):**
1. Create migration in `database/migrations/` (e.g., `001_add_column.sql`)
2. Migrations run ONLY via `upgrade.sh` - never manually
3. Update relevant queries in app.py/daemon

**Important:**
- `schema.sql` = complete database for fresh installs (setup.sh)
- `migrations/` = incremental changes for upgrades only (upgrade.sh)

### Add WebSocket Event

1. Add handler in app.py: `@socketio.on('event_name')`
2. Add client handler in template: `socket.on('event_name', ...)`
3. Emit from server: `socketio.emit('event_name', data, room='...')`

### Debug Issues

```bash
# Check web logs
tail -f /var/log/fotios-claude/web.log

# Check daemon logs
tail -f /var/log/fotios-claude/daemon.log

# Check systemd logs
journalctl -u fotios-claude-web -f

# Test database
mysql -u claude_user -p claude_knowledge -e "SELECT * FROM tickets ORDER BY id DESC LIMIT 5"
```

---

## Current Features (v2.33.0)

- Project & Ticket Management
- Real-time Chat with Claude
- AI Model Selection (Opus/Sonnet/Haiku)
- Kill Commands (/stop, /skip, /done)
- Web Terminal (full Linux shell)
- Claude Assistant with popup support
- Blueprint Planner for project design
- Console for monitoring all activity
- Execution History & Stats

---

## Files NOT to Delete

- `/home/claude/fotios-claude-system-*.zip` - Version backups
- `/etc/fotios-claude/system.conf` - Database credentials
- `/home/claude/.claude/` - Claude CLI config

---

## Tips

1. Always read files before editing
2. Test changes locally before deploying
3. Check service status after restart
4. Keep old zip files as backups
5. Update CHANGELOG for every release
6. Broadcast to both ticket room AND console room for real-time updates
7. Use `select.select()` for non-blocking I/O in daemon

---

*Last Updated: 2026-01-10*
*Current Version: 2.33.0*
